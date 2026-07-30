import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/core/async/buffered_broadcast_controller.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

import '../payment_backend_gateway.dart';

class BookkeepingPaymentFlow implements PaymentFlow {
  BookkeepingPaymentFlow({
    required PaymentBackendGateway backendGateway,
    Logger? logger,
  }) : _backendGateway = backendGateway,
       _logger = logger ?? Logger('BookkeepingPaymentFlow');

  final PaymentBackendGateway _backendGateway;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = BufferedBroadcastController<PaymentStatus>();
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
        controller.add(
          const PaymentStatus(
            type: PaymentStatusType.pending,
            messageKey: PaymentMessageKeys.statusPending,
            phase: PaymentPhase.requesting,
          ),
        );
        controller.add(
          const PaymentStatus(
            type: PaymentStatusType.processing,
            messageKey: PaymentMessageKeys.posReportResult,
            phase: PaymentPhase.confirming,
          ),
        );

        final printDocument = await _backendGateway.confirmPayment(context, {
          'method': context.channel.group,
          'channelCode': context.channel.code,
          'channelDisplayName': context.channel.displayName,
        });

        if (isFinished) return;
        controller.add(
          const PaymentStatus(
            type: PaymentStatusType.success,
            messageKey: PaymentMessageKeys.statusSuccess,
          ),
        );
        await finish(
          PaymentResult.success(
            messageKey: PaymentMessageKeys.statusSuccess,
            payload: <String, dynamic>{
              'mode': context.mode.wireValue,
              'method': context.channel.group,
              'channelCode': context.channel.code,
              if (printDocument != null) 'printDocument': printDocument,
            },
          ),
        );
      } catch (error, stack) {
        _logger.warning('Bookkeeping payment flow failed', error, stack);
        if (isFinished) return;
        controller.add(
          PaymentStatus(
            type: PaymentStatusType.failure,
            messageKey: PaymentMessageKeys.statusFailure,
            messageArgs: {'detail': error.toString()},
            errorType: PaymentErrorType.backend,
            retryable: true,
          ),
        );
        await finish(
          PaymentResult.failure(
            message: error.toString(),
            messageKey: PaymentMessageKeys.statusFailure,
            messageArgs: {'detail': error.toString()},
            errorType: PaymentErrorType.backend,
            retryable: true,
          ),
        );
      }
    }

    Future<void> cancel() async {
      if (isFinished) return;
      controller.add(
        const PaymentStatus(
          type: PaymentStatusType.cancelled,
          messageKey: PaymentMessageKeys.statusCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        ),
      );
      await finish(
        PaymentResult.cancelled(
          messageKey: PaymentMessageKeys.statusCancelled,
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
    );
  }
}
