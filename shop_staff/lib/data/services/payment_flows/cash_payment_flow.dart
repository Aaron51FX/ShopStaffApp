import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';

import '../payment_backend_gateway.dart';

/// Cash payment flow: orchestrates cash machine interaction + backend confirmation.
class CashPaymentFlow implements PaymentFlow {
  CashPaymentFlow({
    required CashMachineService cashMachine,
    required PaymentBackendGateway backendGateway,
    Logger? logger,
  })  : _cashMachine = cashMachine,
        _backendGateway = backendGateway,
        _logger = logger ?? Logger('CashPaymentFlow');

  final CashMachineService _cashMachine;
  final PaymentBackendGateway _backendGateway;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    StreamSubscription<CashMachineEvent>? eventSubscription;
    CashMachineStage? lastStage;
    CashMachineReceipt? pendingReceipt;
    var confirmRequested = false;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      await eventSubscription?.cancel();
      eventSubscription = null;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await controller.close();
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(type: PaymentStatusType.pending, message: '准备现金支付'));
        eventSubscription = _cashMachine.events.listen((event) {
          if (isFinished) return;
          if (event is CashMachineStageEvent) {
            if (event.stage == lastStage) return;
            lastStage = event.stage;
          }
          final status = _statusForEvent(event);
          if (status != null) {
            controller.add(status);
          }
        }, onError: (error, stack) {
          _logger.warning('现金机事件流异常', error, stack);
          if (!isFinished) {
            controller.add(PaymentStatus(type: PaymentStatusType.failure, message: '现金机异常: $error'));
          }
        });
        pendingReceipt = await _cashMachine.runPayment(context.order.total);
        if (isFinished) return;

        controller.add(
          PaymentStatus(
            type: PaymentStatusType.pending,
            message: '请核对投入金额，确认后点击“确认支付”',
            details: {
              'stage': 'await_confirmation',
              'receipt': pendingReceipt?.toJson(),
            },
          ),
        );
      } catch (e, stack) {
        if (isFinished) {
          _logger.fine('Cash payment run aborted after finish', e, stack);
          return;
        }
        _logger.severe('Cash payment flow failed', e, stack);
        controller.add(PaymentStatus(type: PaymentStatusType.failure, message: '现金支付失败: $e'));
        await finish(PaymentResult.failure(message: e.toString()));
      }
    }

    unawaited(run());

    Future<void> finalize() async {
      if (isFinished) return;
      if (pendingReceipt == null) {
        throw StateError('暂无可确认的现金凭证');
      }
      if (confirmRequested) return;
      confirmRequested = true;
      try {
        controller.add(const PaymentStatus(type: PaymentStatusType.processing, message: '正在通知后台…'));
        final receipt = await _cashMachine.completePayment();
        final payload = receipt.toJson();
        await _backendGateway.confirmPayment(context, {
          'method': PaymentChannels.cash,
          'receipt': payload,
        });
        controller.add(const PaymentStatus(type: PaymentStatusType.success, message: '现金支付完成'));
        await finish(PaymentResult.success(message: '现金支付完成', payload: {
          'receipt': payload,
        }));
      } catch (e, stack) {
        confirmRequested = false;
        _logger.severe('Finalize cash payment failed', e, stack);
        controller.add(PaymentStatus(type: PaymentStatusType.failure, message: '确认现金支付失败: $e'));
        await finish(PaymentResult.failure(message: e.toString()));
        rethrow;
      }
    }

    Future<void> cancel() async {
      if (isFinished) {
        return;
      }
      try {
        await _cashMachine.cancelPayment();
      } catch (e, stack) {
        _logger.warning('Failed to cancel cash transaction', e, stack);
      }
      controller.add(const PaymentStatus(type: PaymentStatusType.cancelled, message: '操作员取消现金支付'));
      await finish(PaymentResult.cancelled(message: '操作员取消现金支付'));
    }

    return PaymentFlowRun(
      statuses: controller.stream,
      result: completer.future,
      cancel: cancel,
      finalize: finalize,
    );
  }

  PaymentStatus? _statusForEvent(CashMachineEvent event) {
    if (event is CashMachineStageEvent) {
      final message = event.message ?? _messageForStage(event.stage);
      var type = PaymentStatusType.processing;
      switch (event.stage) {
        case CashMachineStage.accepting:
          type = PaymentStatusType.waitingForUser;
          break;
        case CashMachineStage.error:
          type = PaymentStatusType.failure;
          break;
        default:
          type = PaymentStatusType.processing;
      }
      return PaymentStatus(
        type: type,
        message: message,
        details: {'stage': event.stage.name},
      );
    } else if (event is CashMachineAmountEvent) {
      final label = event.isFinal ? '已确认现金金额' : '当前识别现金金额';
      return PaymentStatus(
        type: PaymentStatusType.processing,
        message: '$label: ¥${event.amount}',
        details: {
          'stage': 'amount',
          'amount': event.amount,
          'isFinal': event.isFinal,
        },
      );
    } else if (event is CashMachineReceiptReadyEvent) {
      return PaymentStatus(
        type: PaymentStatusType.processing,
        message: '现金凭证已生成',
        details: event.receipt.toJson(),
      );
    } else if (event is CashMachineErrorEvent) {
      return PaymentStatus(type: PaymentStatusType.failure, message: event.message);
    }
    return null;
  }

  String _messageForStage(CashMachineStage stage) {
    switch (stage) {
      case CashMachineStage.idle:
        return '现金机已就绪';
      case CashMachineStage.checking:
        return '正在检测现金机…';
      case CashMachineStage.opening:
        return '正在打开现金机…';
      case CashMachineStage.accepting:
        return '等待顾客投入现金';
      case CashMachineStage.counting:
        return '正在确认投入金额…';
      case CashMachineStage.closing:
        return '正在结束现金操作…';
      case CashMachineStage.completed:
        return '现金机操作完成';
      case CashMachineStage.nearfull:
        return '现金机即将满，请清空现金箱';
      case CashMachineStage.full:
        return '现金机已满，请清空现金箱';
      case CashMachineStage.error:
        return '现金机异常';
    }
  }
}
