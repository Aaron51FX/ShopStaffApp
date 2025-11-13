import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

import '../payment_channel_support.dart';
import '../payment_backend_gateway.dart';

/// Cash payment flow: orchestrates cash machine interaction + backend confirmation.
class CashPaymentFlow implements PaymentFlow {
  CashPaymentFlow({
    required CashMachineClient cashMachine,
    required PaymentBackendGateway backendGateway,
    Logger? logger,
  })  : _cashMachine = cashMachine,
        _backendGateway = backendGateway,
        _logger = logger ?? Logger('CashPaymentFlow');

  final CashMachineClient _cashMachine;
  final PaymentBackendGateway _backendGateway;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await controller.close();
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(type: PaymentStatusType.pending, message: '准备现金支付'));
        await _cashMachine.startTransaction(context);
        controller.add(const PaymentStatus(type: PaymentStatusType.waitingForUser, message: '等待顾客投入现金'));
        final receipt = await _cashMachine.waitForSettlement();
        controller.add(const PaymentStatus(type: PaymentStatusType.processing, message: '现金支付完成，通知后台'));
        await _backendGateway.confirmPayment(context, {
          'method': PaymentChannels.cash,
          'receipt': receipt.toJson(),
        });
        controller.add(const PaymentStatus(type: PaymentStatusType.success, message: '现金支付完成'));
        await finish(PaymentResult.success(message: '现金支付完成', payload: {
          'receipt': receipt.toJson(),
        }));
      } catch (e, stack) {
        _logger.severe('Cash payment flow failed', e, stack);
        controller.add(PaymentStatus(type: PaymentStatusType.failure, message: '现金支付失败: $e'));
        await finish(PaymentResult.failure(message: e.toString()));
      }
    }

    unawaited(run());

    Future<void> cancel() async {
      if (isFinished) return;
      try {
        await _cashMachine.cancelTransaction();
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
    );
  }
}
