import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

/// Card flow bridges to the POS terminal service and normalizes status updates.
class CardPaymentFlow implements PaymentFlow {
  CardPaymentFlow({required PosPaymentService posPaymentService, Logger? logger})
      : _posPaymentService = posPaymentService,
        _logger = logger ?? Logger('CardPaymentFlow');

  static const Duration _startTimeout = Duration(seconds: 20);
  static const Duration _statusInactivityTimeout = Duration(seconds: 90);

  final PosPaymentService _posPaymentService;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    String? posSessionId;
    StreamSubscription<PosPaymentStatus>? subscription;
    Timer? stageTimer;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      stageTimer?.cancel();
      stageTimer = null;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await subscription?.cancel();
      await controller.close();
    }

    void clearStageTimer() {
      stageTimer?.cancel();
      stageTimer = null;
    }

    void armStageTimeout({required Duration timeout, required String stage}) {
      clearStageTimer();
      stageTimer = Timer(timeout, () {
        if (isFinished) return;
        _logger.warning('Card payment stage timed out: $stage');
        controller.add(PaymentStatus(
          type: PaymentStatusType.failure,
          messageKey: PaymentMessageKeys.posTimeout,
          messageArgs: const {'detail': 'PAYMENT_STAGE_TIMEOUT'},
          details: {'stage': stage},
          errorType: PaymentErrorType.device,
          retryable: true,
        ));
        unawaited(() async {
          final activeId = posSessionId;
          if (activeId != null) {
            try {
              await _posPaymentService.cancel(activeId);
            } catch (error, stack) {
              _logger.warning('Card payment timeout cancel failed', error, stack);
            }
          }
          await finish(PaymentResult.failure(
            messageKey: PaymentMessageKeys.posTimeout,
            messageArgs: const {'detail': 'PAYMENT_STAGE_TIMEOUT'},
            payload: {'stage': stage},
            errorType: PaymentErrorType.device,
            retryable: true,
          ));
        }());
      });
    }

    PaymentStatus _mapPosStatus(PosPaymentStatus status) {
      final messageArgs = {
        if (status.messageArgs != null) ...status.messageArgs!,
        if (status.errorCode != null) 'errorCode': status.errorCode,
      };
      switch (status.type) {
        case PosPaymentStatusType.pending:
          return PaymentStatus(
            type: PaymentStatusType.pending,
            message: status.message,
            messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.posWaitingResponse : null),
            messageArgs: messageArgs.isEmpty ? null : messageArgs,
            phase: PaymentPhase.sending,
          );
        case PosPaymentStatusType.processing:
          return PaymentStatus(
            type: PaymentStatusType.processing,
            message: status.message,
            messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.posProcessing : null),
            messageArgs: messageArgs.isEmpty ? null : messageArgs,
            phase: PaymentPhase.waitingUser,
          );
        case PosPaymentStatusType.success:
          return PaymentStatus(
            type: PaymentStatusType.success,
            message: status.message,
            messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.cardSuccess : null),
            messageArgs: messageArgs.isEmpty ? null : messageArgs,
            details: {
              if (status.approvalCode != null) 'approvalCode': status.approvalCode,
            },
          );
        case PosPaymentStatusType.failure:
          return PaymentStatus(
            type: PaymentStatusType.failure,
            message: status.message,
            messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.cardFailure : null),
            messageArgs: messageArgs.isEmpty ? null : messageArgs,
            details: {
              if (status.errorCode != null) 'errorCode': status.errorCode,
            },
            errorType: PaymentErrorType.device,
            retryable: true,
          );
        case PosPaymentStatusType.cancelled:
          return PaymentStatus(
            type: PaymentStatusType.cancelled,
            message: status.message,
            messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.cardCancelled : null),
            messageArgs: messageArgs.isEmpty ? null : messageArgs,
            details: {
              if (status.errorCode != null) 'errorCode': status.errorCode,
            },
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
          );
      }
    }

    void handlePosStatus(PosPaymentStatus status) {
      final mapped = _mapPosStatus(status);
      controller.add(mapped);
      if (mapped.isTerminal) {
        clearStageTimer();
        if (mapped.type == PaymentStatusType.success) {
          unawaited(finish(PaymentResult.success(
            message: mapped.message,
            messageKey: mapped.messageKey,
            messageArgs: mapped.messageArgs,
            payload: mapped.details,
          )));
        } else if (mapped.type == PaymentStatusType.cancelled) {
          unawaited(finish(PaymentResult.cancelled(
            message: mapped.message,
            messageKey: mapped.messageKey,
            messageArgs: mapped.messageArgs,
            errorCode: mapped.details?['errorCode'] as String?,
            payload: mapped.details,
            errorType: mapped.errorType ?? PaymentErrorType.userCancelled,
            retryable: mapped.retryable ?? true,
          )));
        } else if (mapped.type == PaymentStatusType.failure) {
          unawaited(finish(PaymentResult.failure(
            message: mapped.message,
            messageKey: mapped.messageKey,
            messageArgs: mapped.messageArgs,
            errorCode: mapped.details?['errorCode'] as String?,
            payload: mapped.details,
            errorType: mapped.errorType ?? PaymentErrorType.device,
            retryable: mapped.retryable ?? true,
          )));
        }
      } else {
        armStageTimeout(timeout: _statusInactivityTimeout, stage: 'pos_status_waiting');
      }
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(
          type: PaymentStatusType.pending,
          messageKey: PaymentMessageKeys.cardInitTerminal,
          phase: PaymentPhase.connecting,
        ));
        armStageTimeout(timeout: _startTimeout, stage: 'start_payment');
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
            unawaited(finish(PaymentResult.failure(
              message: error.toString(),
              messageKey: PaymentMessageKeys.errorUnknown,
              messageArgs: {'detail': error.toString()},
              errorType: PaymentErrorType.device,
              retryable: true,
            )));
          },
          onDone: () {
            if (isFinished) return;
            // If the stream ends unexpectedly, mark as failure unless already completed.
            unawaited(finish(PaymentResult.failure(
              messageKey: PaymentMessageKeys.posStreamClosed,
              errorType: PaymentErrorType.device,
              retryable: true,
            )));
          },
        );
      } catch (e, stack) {
        _logger.severe('Failed to start card payment', e, stack);
        controller.add(PaymentStatus(
          type: PaymentStatusType.failure,
          messageKey: PaymentMessageKeys.cardInitFailed,
          messageArgs: {'detail': e.toString()},
          errorType: PaymentErrorType.device,
          retryable: true,
        ));
        unawaited(finish(PaymentResult.failure(
          message: e.toString(),
          messageKey: PaymentMessageKeys.cardInitFailed,
          messageArgs: {'detail': e.toString()},
          errorType: PaymentErrorType.device,
          retryable: true,
        )));
      }
    }

    Future<void> cancel() async {
      if (isFinished) {
        return;
      }
      clearStageTimer();
      final activeId = posSessionId;
      if (activeId != null) {
        try {
          await _posPaymentService.cancel(activeId);
        } catch (e, stack) {
          _logger.severe('Failed to cancel card payment', e, stack);
          controller.add(PaymentStatus(
            type: PaymentStatusType.failure,
            messageKey: PaymentMessageKeys.cardCancelFailed,
            messageArgs: {'detail': e.toString()},
            errorType: PaymentErrorType.device,
            retryable: true,
          ));
          unawaited(finish(PaymentResult.failure(
            message: e.toString(),
            messageKey: PaymentMessageKeys.cardCancelFailed,
            messageArgs: {'detail': e.toString()},
            errorType: PaymentErrorType.device,
            retryable: true,
          )));
          rethrow;
        }
      } else {
        controller.add(const PaymentStatus(
          type: PaymentStatusType.cancelled,
          messageKey: PaymentMessageKeys.cardCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        ));
        unawaited(finish(PaymentResult.cancelled(
          messageKey: PaymentMessageKeys.cardCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        )));
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
