import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

/// Card flow bridges to the POS terminal service and normalizes status updates.
class CardPaymentFlow implements PaymentFlow {
  CardPaymentFlow({required PosPaymentService posPaymentService, Logger? logger})
      : _posPaymentService = posPaymentService,
        _logger = logger ?? Logger('CardPaymentFlow');

  final PosPaymentService _posPaymentService;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    String? posSessionId;
    StreamSubscription<PosPaymentStatus>? subscription;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await subscription?.cancel();
      await controller.close();
    }

    PaymentStatus _mapPosStatus(PosPaymentStatus status) {
      switch (status.type) {
        case PosPaymentStatusType.pending:
          return PaymentStatus(type: PaymentStatusType.pending, message: status.message);
        case PosPaymentStatusType.processing:
          return PaymentStatus(type: PaymentStatusType.processing, message: status.message);
        case PosPaymentStatusType.success:
          return PaymentStatus(
            type: PaymentStatusType.success,
            message: status.message ?? '信用卡支付成功',
            details: {
              if (status.approvalCode != null) 'approvalCode': status.approvalCode,
            },
          );
        case PosPaymentStatusType.failure:
          return PaymentStatus(
            type: PaymentStatusType.failure,
            message: status.message ?? '信用卡支付失败',
            details: {
              if (status.errorCode != null) 'errorCode': status.errorCode,
            },
          );
        case PosPaymentStatusType.cancelled:
          return PaymentStatus(
            type: PaymentStatusType.cancelled,
            message: status.message ?? '信用卡支付取消',
            details: {
              if (status.errorCode != null) 'errorCode': status.errorCode,
            },
          );
      }
    }

    void handlePosStatus(PosPaymentStatus status) {
      final mapped = _mapPosStatus(status);
      controller.add(mapped);
      if (mapped.isTerminal) {
        if (mapped.type == PaymentStatusType.success) {
          unawaited(finish(PaymentResult.success(
            message: mapped.message,
            payload: mapped.details,
          )));
        } else if (mapped.type == PaymentStatusType.cancelled) {
          unawaited(finish(PaymentResult.cancelled(
            message: mapped.message,
            errorCode: mapped.details?['errorCode'] as String?,
            payload: mapped.details,
          )));
        } else if (mapped.type == PaymentStatusType.failure) {
          unawaited(finish(PaymentResult.failure(
            message: mapped.message,
            errorCode: mapped.details?['errorCode'] as String?,
            payload: mapped.details,
          )));
        }
      }
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(type: PaymentStatusType.pending, message: '初始化信用卡终端'));
        final request = PosPaymentRequest(
          order: context.order,
          channelGroup: context.channel.group,
          channelCode: context.channel.code,
          customPayload: context.channelConfig,
        );
        final session = await _posPaymentService.startPayment(request);
        posSessionId = session.sessionId;
        handlePosStatus(session.initialStatus);
        subscription = _posPaymentService.watchStatus(session.sessionId).listen(
          handlePosStatus,
          onError: (error, stack) {
            if (isFinished) return;
            _logger.warning('POS status stream error', error, stack);
            unawaited(finish(PaymentResult.failure(message: error.toString())));
          },
          onDone: () {
            if (isFinished) return;
            // If the stream ends unexpectedly, mark as failure unless already completed.
            unawaited(finish(PaymentResult.failure(message: 'POS终端连接已关闭')));
          },
        );
      } catch (e, stack) {
        _logger.severe('Failed to start card payment', e, stack);
        controller.add(PaymentStatus(type: PaymentStatusType.failure, message: '信用卡支付初始化失败: $e'));
        unawaited(finish(PaymentResult.failure(message: e.toString())));
      }
    }

    Future<void> cancel() async {
      if (isFinished) return;
      final activeId = posSessionId;
      if (activeId != null) {
        await _posPaymentService.cancel(activeId);
      } else {
        controller.add(const PaymentStatus(type: PaymentStatusType.cancelled, message: '操作员取消信用卡支付'));
        unawaited(finish(PaymentResult.cancelled(message: '操作员取消信用卡支付')));
      }
    }

    unawaited(run());

    return PaymentFlowRun(
      statuses: controller.stream,
      result: completer.future,
      cancel: cancel,
    );
  }
}
