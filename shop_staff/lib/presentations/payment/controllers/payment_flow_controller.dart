import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';
import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/payments/payment_flow_usecase.dart';
import 'package:shop_staff/application/payments/usecases/start_payment_usecase.dart';
import 'package:shop_staff/application/payments/usecases/record_abnormal_payment_exit_usecase.dart';
import 'package:shop_staff/data/services/payment_channel_support.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'payment_flow_effect.dart';

class PaymentFlowController extends StateNotifier<PaymentSessionState> {
  PaymentFlowController(
    PaymentFlowPageArgs args, {
    required PaymentFlowUseCase useCase,
    required RecordAbnormalPaymentExitUseCase recordAbnormalExit,
    required CheckoutCoordinator checkoutCoordinator,
    required QrScannerService qrScanner,
    VoidCallback? onSessionActive,
    VoidCallback? onTerminal,
  }) : _args = args,
       _useCase = useCase,
       _recordAbnormalExit = recordAbnormalExit,
       _checkoutCoordinator = checkoutCoordinator,
       _qrScanner = qrScanner,
       _onSessionActive = onSessionActive,
       _onTerminal = onTerminal,
       _logger = Logger('PaymentFlowController'),
       super(PaymentSessionState(channelGroup: args.channelGroup));

  final PaymentFlowPageArgs _args;
  final PaymentFlowUseCase _useCase;
  final RecordAbnormalPaymentExitUseCase _recordAbnormalExit;
  final CheckoutCoordinator _checkoutCoordinator;
  final QrScannerService _qrScanner;
  final VoidCallback? _onSessionActive;
  final VoidCallback? _onTerminal;
  final Logger _logger;

  StreamSubscription<PaymentStatus>? _statusSubscription;
  Future<PaymentResult>? _resultFuture;
  bool _isRestarting = false;
  bool _isForceExiting = false;
  bool _startRequested = false;
  bool _disposed = false;
  bool _terminalNotified = false;
  int _runGeneration = 0;
  final StreamController<PaymentFlowEffect> _effects =
      StreamController<PaymentFlowEffect>.broadcast();

  Stream<PaymentFlowEffect> get effects => _effects.stream;

  void _emit(PaymentFlowEffect effect) {
    if (_effects.isClosed) return;
    _effects.add(effect);
  }

  Future<void> start() async {
    if (_startRequested || _disposed) return;
    _startRequested = true;
    _activateSessionLifetime();
    try {
      _checkoutCoordinator.paymentStarted(_args);
      final run = _useCase.start(_args);
      _bindRun(run);
    } catch (e, stack) {
      await _handleStartError(e, stack);
    }
  }

  void _bindRun(PaymentFlowStartResult run) {
    final generation = ++_runGeneration;
    final session = run.session;
    final initial = session.initialStatus;
    state = state.copyWith(
      sessionId: session.sessionId,
      currentStatus: initial,
      hasStarted: true,
      requiresManualCompletion: session.requiresManualCompletion,
      confirmationReady: false,
      pendingReceipt: null,
    );

    _statusSubscription = run.statuses.listen((status) {
      if (_disposed || generation != _runGeneration) return;
      final previous = state;
      debugPrint('Payment status update: ${status.type} - ${status.message}');
      final dialogUpdate = _cancelDialogStateForStatus(
        status,
        previous.cancelDialog,
      );
      final previousStage = previous.currentStatus?.details?['stage'];
      var confirmationReady = previous.confirmationReady;
      var pendingReceipt = previous.pendingReceipt;
      final stage = status.details?['stage'];
      if (stage == 'await_confirmation') {
        final receipt = status.details?['receipt'] as Map<String, dynamic>?;
        if (receipt != null) {
          pendingReceipt = Map<String, dynamic>.from(receipt);
        }
      } else if (stage == 'amount') {
        final amount = status.details?['amount'];
        final isFinal = status.details?['isFinal'] == true;
        if (amount is num) {
          final meetsRequirement = amount >= _expectedAmount;
          confirmationReady = isFinal && meetsRequirement;
          pendingReceipt = confirmationReady
              ? _mergeReceiptAmount(pendingReceipt, amount)
              : null;
        } else {
          confirmationReady = false;
          pendingReceipt = null;
        }
      }
      if (status.isTerminal ||
          status.type == PaymentStatusType.failure ||
          status.type == PaymentStatusType.indeterminate ||
          status.type == PaymentStatusType.reconciling) {
        confirmationReady = false;
        pendingReceipt = null;
      }
      if (stage == CashMachineStage.waitingDrawerClose.name &&
          previousStage != CashMachineStage.waitingDrawerClose.name) {
        _emit(const PaymentFlowDrawerCloseReminderEffect());
      }
      state = previous.copyWith(
        currentStatus: status,
        cancelDialog: dialogUpdate ?? previous.cancelDialog,
        confirmationReady: confirmationReady,
        pendingReceipt: pendingReceipt,
      );
    }, onError: (error, stack) => _handleError(error, stack));

    _resultFuture = run.result;
    _resultFuture
        ?.then((result) async {
          if (_disposed || generation != _runGeneration) return;
          state = state.copyWith(result: result);
          switch (result.status) {
            case PaymentStatusType.success:
              final localOrderUpdated = await _checkoutCoordinator
                  .paymentCompleted(result);
              if (!localOrderUpdated) {
                _emit(
                  const PaymentFlowToastEffect(
                    messageKey: PaymentMessageKeys.orderCompletionFailed,
                    isError: true,
                  ),
                );
              }
              _emit(
                PaymentFlowToastEffect(
                  message: result.message,
                  messageKey:
                      result.messageKey ?? PaymentMessageKeys.statusSuccess,
                  messageArgs: result.messageArgs,
                ),
              );
              break;
            case PaymentStatusType.failure:
              await _checkoutCoordinator.paymentCompleted(result);
              _emit(
                PaymentFlowToastEffect(
                  message: result.message,
                  messageKey:
                      result.messageKey ?? PaymentMessageKeys.statusFailure,
                  messageArgs: result.messageArgs,
                  isError: true,
                ),
              );
              break;
            case PaymentStatusType.cancelled:
              await _checkoutCoordinator.paymentCompleted(result);
              break;
            case PaymentStatusType.indeterminate:
              await _checkoutCoordinator.paymentCompleted(result);
              _emit(
                PaymentFlowToastEffect(
                  message: result.message,
                  messageKey:
                      result.messageKey ??
                      PaymentMessageKeys.resultIndeterminate,
                  messageArgs: result.messageArgs,
                  isError: true,
                ),
              );
              break;
            case PaymentStatusType.reconciling:
            case PaymentStatusType.initialized:
            case PaymentStatusType.pending:
            case PaymentStatusType.waitingForUser:
            case PaymentStatusType.processing:
              break;
          }
          _notifyTerminal();
        })
        .catchError((error, stack) {
          if (_disposed || generation != _runGeneration) return;
          _handleError(error, stack is StackTrace ? stack : StackTrace.current);
        });
  }

  Future<void> retryPayment() async {
    if (_isRestarting || !state.canRetry) return;
    _isRestarting = true;
    _activateSessionLifetime();
    final previousSessionId = state.sessionId;
    try {
      await _teardownActiveSession(
        releaseQrScanner: true,
        cancelSession: false,
      );
      state = PaymentSessionState(channelGroup: _args.channelGroup);
      _checkoutCoordinator.paymentStarted(_args);
      final run = await _useCase.retry(
        args: _args,
        previousSessionId: previousSessionId,
      );
      _bindRun(run);
    } catch (error, stack) {
      await _handleStartError(error, stack);
    } finally {
      _isRestarting = false;
    }
  }

  void cancelPayment() {
    if (!state.canCancel) return;
    _emit(const PaymentFlowRequestCancelConfirmEffect(destructive: true));
  }

  Future<void> reconcilePayment() async {
    if (!state.canReconcile) return;
    final id = state.sessionId;
    if (id == null) return;
    try {
      await _useCase.reconcile(id);
    } catch (error, stack) {
      _logger.warning('Reconcile payment failed', error, stack);
      _emit(
        PaymentFlowToastEffect(
          messageKey: PaymentMessageKeys.resultIndeterminate,
          messageArgs: {'detail': error.toString()},
          isError: true,
        ),
      );
    }
  }

  Future<void> confirmCancelPayment() async {
    await _cancelPayment();
  }

  Future<void> retryCancelAfterFailure() async {
    if (state.cancelDialog.status != CancelDialogStatus.failure) return;
    if (state.isCancelling) return;
    await _cancelPayment();
  }

  Future<void> forceExitAfterCancelFailure() async {
    if (_isForceExiting) return;
    if (state.cancelDialog.status != CancelDialogStatus.failure) return;
    _isForceExiting = true;
    final snapshot = state;
    final sessionId = snapshot.sessionId;
    final orderId = _args.order.orderId;
    try {
      await _teardownActiveSession(
        releaseQrScanner: true,
        cancelSession: false,
        snapshot: snapshot,
      );
      final recorded = await _recordAbnormalExit.execute(
        orderId: orderId,
        sessionId: sessionId,
      );
      if (!recorded) {
        _logger.warning(
          'Unable to mark abnormal force-exit order because local record is '
          'missing: orderId=$orderId sessionId=$sessionId',
        );
      }
      final forceExitStatus = PaymentStatus(
        type: PaymentStatusType.cancelled,
        messageKey: PaymentMessageKeys.posOperatorCancelled,
        details: {
          'stage': 'force_exit',
          'orderId': orderId,
          if (sessionId != null) 'sessionId': sessionId,
          'recordedAs': RecordAbnormalPaymentExitUseCase.payMethod,
        },
        errorType: PaymentErrorType.unknown,
        retryable: true,
      );
      final forceExitResult = PaymentResult.cancelled(
        messageKey: PaymentMessageKeys.posOperatorCancelled,
        errorCode: 'CANCEL_FORCE_EXIT',
        payload: forceExitStatus.details,
        errorType: PaymentErrorType.unknown,
        retryable: true,
      );
      state = state.copyWith(
        currentStatus: forceExitStatus,
        result: forceExitResult,
        isCancelling: false,
        cancelDialog: CancelDialogState.success(null),
      );
      await _checkoutCoordinator.paymentCompleted(forceExitResult);
      _notifyTerminal();
      _emit(
        const PaymentFlowToastEffect(
          messageKey: PaymentMessageKeys.paymentForceExitRecorded,
          isError: true,
        ),
      );
    } catch (e, stack) {
      _logger.warning('Force exit after cancel failure failed', e, stack);
      state = state.copyWith(
        cancelDialog: CancelDialogState.failure(null, requiresRecovery: true),
      );
      _emit(
        PaymentFlowToastEffect(
          messageKey: PaymentMessageKeys.posCancelFailed,
          messageArgs: {'detail': e.toString()},
          isError: true,
        ),
      );
    } finally {
      _isForceExiting = false;
    }
  }

  Future<void> confirmManualPayment() async {
    if (!state.canConfirmManual) return;
    final id = state.sessionId;
    if (id == null) return;
    state = state.copyWith(isConfirming: true);
    try {
      await _useCase.finalize(id);
    } catch (e, stack) {
      _logger.warning('Confirm payment failed', e, stack);
      final detail = e.toString();
      _emit(
        PaymentFlowToastEffect(
          message: detail,
          messageKey: PaymentMessageKeys.cashConfirmFailed,
          messageArgs: {'detail': detail},
          isError: true,
        ),
      );
    } finally {
      state = state.copyWith(isConfirming: false);
    }
  }

  Future<void> _cancelPayment() async {
    final id = state.sessionId;
    if (id == null || !state.canCancel) return;
    state = state.copyWith(
      isCancelling: true,
      cancelDialog: CancelDialogState.loading(null),
    );
    try {
      await _useCase.cancel(id);
    } catch (e, stack) {
      _logger.warning('Cancel payment failed', e, stack);
      state = state.copyWith(
        cancelDialog: CancelDialogState.failure(null, requiresRecovery: true),
      );
      _emit(
        PaymentFlowToastEffect(
          messageKey: PaymentMessageKeys.posCancelFailed,
          messageArgs: {'detail': e.toString()},
          isError: true,
        ),
      );
    } finally {
      state = state.copyWith(isCancelling: false);
    }
  }

  void dismissCancelDialog() {
    if (state.cancelDialog.status != CancelDialogStatus.hidden) {
      state = state.copyWith(cancelDialog: const CancelDialogState.hidden());
    }
  }

  CancelDialogState? _cancelDialogStateForStatus(
    PaymentStatus status,
    CancelDialogState currentDialog,
  ) {
    if (currentDialog.status != CancelDialogStatus.loading) {
      return null;
    }
    if (status.type == PaymentStatusType.cancelled) {
      return CancelDialogState.success(null);
    }
    if (status.type == PaymentStatusType.failure) {
      return CancelDialogState.failure(null, requiresRecovery: true);
    }
    return null;
  }

  void _handleError(Object error, StackTrace stack) {
    _logger.severe('Payment flow error', error, stack);
    unawaited(_handleRuntimeError());
  }

  Future<void> _handleRuntimeError() async {
    if (_disposed || state.isFinished) return;
    final phase = state.currentStatus?.phase;
    final isUnknown =
        phase != null &&
        phase.policy.timeoutOutcome == PaymentTimeoutOutcome.indeterminate;
    final status = PaymentStatus(
      type: isUnknown
          ? PaymentStatusType.indeterminate
          : PaymentStatusType.failure,
      messageKey: PaymentMessageKeys.errorRuntime,
      errorType: PaymentErrorType.unknown,
      retryable: !isUnknown,
      phase: phase,
      certainty: isUnknown
          ? PaymentOutcomeCertainty.indeterminate
          : PaymentOutcomeCertainty.known,
      recovery: isUnknown
          ? PaymentRecovery.contactSupervisor
          : PaymentRecovery.restartPayment,
    );
    final dialogNeedsUpdate =
        state.cancelDialog.status == CancelDialogStatus.loading;
    final result = isUnknown
        ? PaymentResult.indeterminate(
            messageKey: PaymentMessageKeys.errorRuntime,
            errorType: PaymentErrorType.unknown,
            recovery: PaymentRecovery.contactSupervisor,
          )
        : PaymentResult.failure(
            messageKey: PaymentMessageKeys.errorRuntime,
            errorType: PaymentErrorType.unknown,
            retryable: true,
            recovery: PaymentRecovery.restartPayment,
          );
    state = state.copyWith(
      currentStatus: status,
      result: result,
      cancelDialog: dialogNeedsUpdate
          ? CancelDialogState.failure(null, requiresRecovery: true)
          : state.cancelDialog,
    );
    await _checkoutCoordinator.paymentCompleted(result);
    _notifyTerminal();
    _emit(
      const PaymentFlowToastEffect(
        messageKey: PaymentMessageKeys.errorRuntime,
        isError: true,
      ),
    );
  }

  Future<void> _handleStartError(Object error, StackTrace stack) async {
    _logger.severe('Payment flow failed to start', error, stack);
    final result = PaymentResult.failure(
      messageKey: PaymentMessageKeys.errorRuntime,
      errorType: PaymentErrorType.unknown,
      recovery: PaymentRecovery.retryCurrentStep,
      certainty: PaymentOutcomeCertainty.known,
    );
    state = state.copyWith(
      currentStatus: PaymentStatus(
        type: PaymentStatusType.failure,
        messageKey: PaymentMessageKeys.errorRuntime,
        errorType: PaymentErrorType.unknown,
        retryable: true,
        certainty: PaymentOutcomeCertainty.known,
        recovery: PaymentRecovery.retryCurrentStep,
      ),
      result: result,
    );
    await _checkoutCoordinator.paymentCompleted(result);
    _emit(
      PaymentFlowToastEffect(
        messageKey: PaymentMessageKeys.errorRuntime,
        isError: true,
      ),
    );
    _notifyTerminal();
  }

  void _notifyTerminal() {
    if (_terminalNotified) return;
    _terminalNotified = true;
    _onTerminal?.call();
  }

  void _activateSessionLifetime() {
    _terminalNotified = false;
    _onSessionActive?.call();
  }

  int get _expectedAmount => _args.order.total;

  Map<String, dynamic> _mergeReceiptAmount(
    Map<String, dynamic>? current,
    num amount,
  ) {
    final receipt = <String, dynamic>{'expectedAmount': _expectedAmount};
    if (current != null) {
      receipt.addAll(current);
    }
    receipt['acceptedAmount'] = amount.toInt();
    return receipt;
  }

  Future<void> _teardownActiveSession({
    bool releaseQrScanner = false,
    bool cancelSession = false,
    PaymentSessionState? snapshot,
  }) async {
    _runGeneration += 1;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    final current = snapshot ?? state;
    final sessionId = current.sessionId;
    final shouldReleaseScanner =
        releaseQrScanner && _args.channelGroup == PaymentChannels.qr;

    if (cancelSession && sessionId != null && !current.isFinished) {
      try {
        await _useCase.cancel(sessionId);
      } catch (error, stack) {
        _logger.fine('Teardown cancel failed: $error', error, stack);
      }
    }

    if (shouldReleaseScanner) {
      try {
        await _qrScanner.cancelScan();
      } catch (error, stack) {
        _logger.fine('Scanner reset failed: $error', error, stack);
      }
    }

    _resultFuture = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _runGeneration += 1;
    final snapshot = state;
    unawaited(
      _teardownActiveSession(
        releaseQrScanner: true,
        cancelSession: false,
        snapshot: snapshot,
      ),
    );
    unawaited(_effects.close());
    super.dispose();
  }
}
