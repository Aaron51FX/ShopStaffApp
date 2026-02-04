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

    void failFromStatus(PaymentStatus status) {
      if (isFinished) return;
      unawaited(finish(PaymentResult.failure(
        message: status.message,
        messageKey: status.messageKey,
        messageArgs: status.messageArgs,
        errorType: status.errorType ?? PaymentErrorType.device,
        retryable: status.retryable ?? true,
        payload: status.details,
      )));
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(
          type: PaymentStatusType.pending,
          messageKey: PaymentMessageKeys.cashPrepare,
          phase: PaymentPhase.initializing,
        ));
        eventSubscription = _cashMachine.events.listen((event) {
          if (isFinished) return;
          if (event is CashMachineStageEvent) {
            if (event.stage == lastStage) return;
            lastStage = event.stage;
          }
          final status = _statusForEvent(event);
          if (status != null) {
            controller.add(status);
            if (status.type == PaymentStatusType.failure) {
              failFromStatus(status);
            }
          }
        }, onError: (error, stack) {
          _logger.warning('现金机事件流异常', error, stack);
          if (!isFinished) {
            final status = PaymentStatus(
              type: PaymentStatusType.failure,
              messageKey: PaymentMessageKeys.errorUnknown,
              messageArgs: {'detail': error.toString()},
              errorType: PaymentErrorType.device,
              retryable: true,
            );
            controller.add(status);
            failFromStatus(status);
          }
        });
        pendingReceipt = await _cashMachine.runPayment(context.order.total);
        if (isFinished) return;

        controller.add(
          PaymentStatus(
            type: PaymentStatusType.pending,
            messageKey: PaymentMessageKeys.cashAwaitConfirm,
            details: {
              'stage': 'await_confirmation',
              'receipt': pendingReceipt?.toJson(),
            },
            phase: PaymentPhase.waitingUser,
          ),
        );
      } catch (e, stack) {
        if (isFinished) {
          _logger.fine('Cash payment run aborted after finish', e, stack);
          return;
        }
        _logger.severe('Cash payment flow failed', e, stack);
        controller.add(PaymentStatus(
          type: PaymentStatusType.failure,
          messageKey: PaymentMessageKeys.cashFailure,
          messageArgs: {'detail': e.toString()},
          errorType: PaymentErrorType.device,
          retryable: true,
        ));
        await finish(PaymentResult.failure(
          message: e.toString(),
          messageKey: PaymentMessageKeys.cashFailure,
          messageArgs: {'detail': e.toString()},
          errorType: PaymentErrorType.device,
          retryable: true,
        ));
      }
    }

    unawaited(run());

    Future<void> finalize() async {
      if (isFinished) return;
      if (pendingReceipt == null) {
        throw StateError('CASH_RECEIPT_MISSING');
      }
      if (confirmRequested) return;
      confirmRequested = true;
      try {
        controller.add(const PaymentStatus(
          type: PaymentStatusType.processing,
          messageKey: PaymentMessageKeys.cashConfirming,
          phase: PaymentPhase.confirming,
        ));
        final receipt = await _cashMachine.completePayment();
        final payload = receipt.toJson();
        await _backendGateway.confirmPayment(context, {
          'method': PaymentChannels.cash,
          'receipt': payload,
        });
        controller.add(const PaymentStatus(
          type: PaymentStatusType.success,
          messageKey: PaymentMessageKeys.cashSuccess,
        ));
        await finish(PaymentResult.success(
          messageKey: PaymentMessageKeys.cashSuccess,
          payload: {
          'receipt': payload,
        }));
      } catch (e, stack) {
        confirmRequested = false;
        _logger.severe('Finalize cash payment failed', e, stack);
        controller.add(PaymentStatus(
          type: PaymentStatusType.failure,
          messageKey: PaymentMessageKeys.cashConfirmFailed,
          messageArgs: {'detail': e.toString()},
          errorType: PaymentErrorType.backend,
          retryable: true,
        ));
        await finish(PaymentResult.failure(
          message: e.toString(),
          messageKey: PaymentMessageKeys.cashConfirmFailed,
          messageArgs: {'detail': e.toString()},
          errorType: PaymentErrorType.backend,
          retryable: true,
        ));
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
      controller.add(const PaymentStatus(
        type: PaymentStatusType.cancelled,
        messageKey: PaymentMessageKeys.cashCancelled,
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
      ));
      await finish(PaymentResult.cancelled(
        messageKey: PaymentMessageKeys.cashCancelled,
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
      ));
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
      final message = event.message;
      final messageKey = message == null ? _messageKeyForStage(event.stage) : null;
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
        messageKey: messageKey,
        details: {'stage': event.stage.name},
        errorType: type == PaymentStatusType.failure ? PaymentErrorType.device : null,
        retryable: type == PaymentStatusType.failure ? true : null,
        phase: type == PaymentStatusType.waitingForUser ? PaymentPhase.waitingUser : null,
      );
    } else if (event is CashMachineAmountEvent) {
      return PaymentStatus(
        type: PaymentStatusType.processing,
        messageKey: event.isFinal
            ? PaymentMessageKeys.cashAmountFinal
            : PaymentMessageKeys.cashAmountCurrent,
        messageArgs: {'amount': event.amount},
        details: {
          'stage': 'amount',
          'amount': event.amount,
          'isFinal': event.isFinal,
        },
      );
    } else if (event is CashMachineReceiptReadyEvent) {
      return PaymentStatus(
        type: PaymentStatusType.processing,
        messageKey: PaymentMessageKeys.cashStageCompleted,
        details: event.receipt.toJson(),
      );
    } else if (event is CashMachineErrorEvent) {
      return PaymentStatus(
        type: PaymentStatusType.failure,
        message: event.message,
        messageKey: event.message == null ? PaymentMessageKeys.cashStageError : null,
        errorType: PaymentErrorType.device,
        retryable: true,
      );
    }
    return null;
  }

  String _messageKeyForStage(CashMachineStage stage) {
    switch (stage) {
      case CashMachineStage.idle:
        return PaymentMessageKeys.cashStageIdle;
      case CashMachineStage.checking:
        return PaymentMessageKeys.cashStageChecking;
      case CashMachineStage.opening:
        return PaymentMessageKeys.cashStageOpening;
      case CashMachineStage.accepting:
        return PaymentMessageKeys.cashStageAccepting;
      case CashMachineStage.counting:
        return PaymentMessageKeys.cashStageCounting;
      case CashMachineStage.closing:
        return PaymentMessageKeys.cashStageClosing;
      case CashMachineStage.completed:
        return PaymentMessageKeys.cashStageCompleted;
      case CashMachineStage.nearfull:
        return PaymentMessageKeys.cashStageNearFull;
      case CashMachineStage.full:
        return PaymentMessageKeys.cashStageFull;
      case CashMachineStage.error:
        return PaymentMessageKeys.cashStageError;
      case CashMachineStage.change:
        return PaymentMessageKeys.cashStageChange;
      case CashMachineStage.changeFailed:
        return PaymentMessageKeys.cashStageChangeFailed;
    }
  }
}
