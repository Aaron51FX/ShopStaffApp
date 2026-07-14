import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/core/async/buffered_broadcast_controller.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

import 'pos_payment_status_adapter.dart';
import 'pos_terminal_payment_step.dart';

/// Card flow delegates the shared terminal lifecycle to
/// [PosTerminalPaymentStep].
class CardPaymentFlow implements PaymentFlow {
  CardPaymentFlow({
    required PosPaymentService posPaymentService,
    Logger? logger,
  }) : _posPaymentService = posPaymentService,
       _logger = logger ?? Logger('CardPaymentFlow');

  static const PosPaymentStatusAdapter _statusAdapter = PosPaymentStatusAdapter(
    PosPaymentStatusAdapterConfig(
      successMessageKey: PaymentMessageKeys.cardSuccess,
      failureMessageKey: PaymentMessageKeys.cardFailure,
      cancelledMessageKey: PaymentMessageKeys.cardCancelled,
    ),
  );

  final PosPaymentService _posPaymentService;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = BufferedBroadcastController<PaymentStatus>();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    late final PosTerminalPaymentStep terminalStep;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      if (!completer.isCompleted) completer.complete(result);
      await terminalStep.dispose();
      await controller.close();
    }

    terminalStep = PosTerminalPaymentStep(
      service: _posPaymentService,
      adapter: _statusAdapter,
      config: const PosTerminalPaymentStepConfig(
        startStatus: PaymentStatus(
          type: PaymentStatusType.pending,
          messageKey: PaymentMessageKeys.cardInitTerminal,
          phase: PaymentPhase.connecting,
        ),
        startFailureMessageKey: PaymentMessageKeys.cardInitFailed,
        startStage: 'card_pos_start',
        waitingStage: 'card_pos_waiting',
      ),
      emitStatus: controller.add,
      complete: finish,
      logger: _logger,
    );

    Future<void> run() async {
      final request = PosPaymentRequest(
        order: context.order,
        channelGroup: context.channel.group,
        channelCode: context.channel.code,
        customPayload: context.channelConfig,
      );
      await terminalStep.start(request);
    }

    Future<void> cancel() async {
      if (isFinished) return;
      if (terminalStep.hasSession) {
        try {
          await terminalStep.cancel();
        } catch (error, stack) {
          _logger.severe('Failed to cancel card payment', error, stack);
          controller.add(
            PaymentStatus(
              type: PaymentStatusType.failure,
              messageKey: PaymentMessageKeys.cardCancelFailed,
              messageArgs: {'detail': error.toString()},
              errorType: PaymentErrorType.device,
              retryable: true,
              certainty: PaymentOutcomeCertainty.known,
              recovery: PaymentRecovery.retryCurrentStep,
            ),
          );
          await finish(
            PaymentResult.failure(
              message: error.toString(),
              messageKey: PaymentMessageKeys.cardCancelFailed,
              messageArgs: {'detail': error.toString()},
              errorType: PaymentErrorType.device,
              retryable: true,
            ),
          );
          rethrow;
        }
        return;
      }
      controller.add(
        const PaymentStatus(
          type: PaymentStatusType.cancelled,
          messageKey: PaymentMessageKeys.cardCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        ),
      );
      await finish(
        PaymentResult.cancelled(
          messageKey: PaymentMessageKeys.cardCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        ),
      );
    }

    unawaited(run());

    return PaymentFlowRun(
      statuses: controller.stream,
      result: completer.future,
      cancel: cancel,
      reconcile: terminalStep.reconcile,
    );
  }
}
