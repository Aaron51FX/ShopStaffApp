import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';

/// UI-ready state for one payment session.
///
/// Button capabilities live here so widgets never need to infer payment safety
/// rules from raw status values.
class PaymentSessionState {
  const PaymentSessionState({
    this.channelGroup,
    this.sessionId,
    this.currentStatus,
    this.result,
    this.isCancelling = false,
    this.hasStarted = false,
    this.cancelDialog = const CancelDialogState.hidden(),
    this.requiresManualCompletion = false,
    this.confirmationReady = false,
    this.isConfirming = false,
    this.pendingReceipt,
  });

  static const Object _unset = Object();

  final String? channelGroup;
  final String? sessionId;
  final PaymentStatus? currentStatus;
  final PaymentResult? result;
  final bool isCancelling;
  final bool hasStarted;
  final CancelDialogState cancelDialog;
  final bool requiresManualCompletion;
  final bool confirmationReady;
  final bool isConfirming;
  final Map<String, dynamic>? pendingReceipt;

  bool get isIndeterminate {
    if (currentStatus?.type == PaymentStatusType.indeterminate) return true;
    if (currentStatus?.certainty == PaymentOutcomeCertainty.indeterminate) {
      return true;
    }
    return result?.failure?.certainty == PaymentOutcomeCertainty.indeterminate;
  }

  bool get isReconciling =>
      currentStatus?.type == PaymentStatusType.reconciling;

  bool get isFinished => result != null || (currentStatus?.isTerminal ?? false);

  bool get canExit => isFinished;

  PaymentErrorType? get effectiveErrorType =>
      result?.failure?.type ?? result?.errorType ?? currentStatus?.errorType;

  PaymentRecovery? get recommendedRecovery =>
      result?.failure?.recovery ?? currentStatus?.recovery;

  bool get canCancel {
    if (isCancelling || isReconciling || isIndeterminate || isFinished) {
      return false;
    }
    if (!hasStarted) return false;

    final current = currentStatus?.type;
    final phase = currentStatus?.phase;
    if (phase != null) return phase.policy.canCancel;

    final isManagedPayment =
        channelGroup == PaymentChannels.card ||
        channelGroup == PaymentChannels.qr ||
        channelGroup == PaymentChannels.cash;
    if (!isManagedPayment) return true;
    return current == PaymentStatusType.waitingForUser;
  }

  bool get canRetry {
    if (isCancelling || isReconciling || isIndeterminate) return false;
    final retryable = result?.retryable ?? currentStatus?.retryable ?? true;
    if (!retryable) return false;
    final effective = result?.status ?? currentStatus?.type;
    return effective == PaymentStatusType.failure ||
        effective == PaymentStatusType.cancelled;
  }

  bool get canReconcile =>
      isIndeterminate &&
      !isReconciling &&
      sessionId != null &&
      recommendedRecovery == PaymentRecovery.reconcileResult;

  bool get canOpenSettings =>
      effectiveErrorType == PaymentErrorType.config ||
      recommendedRecovery == PaymentRecovery.openSettings;

  bool get canCheckNetwork =>
      effectiveErrorType == PaymentErrorType.network ||
      recommendedRecovery == PaymentRecovery.checkNetwork;

  bool get canConfirmManual =>
      requiresManualCompletion &&
      confirmationReady &&
      !isConfirming &&
      !isCancelling &&
      !isReconciling &&
      !isIndeterminate &&
      !isFinished;

  PaymentSessionState copyWith({
    String? channelGroup,
    String? sessionId,
    PaymentStatus? currentStatus,
    Object? result = _unset,
    bool? isCancelling,
    bool? hasStarted,
    CancelDialogState? cancelDialog,
    bool? requiresManualCompletion,
    bool? confirmationReady,
    bool? isConfirming,
    Object? pendingReceipt = _unset,
  }) {
    return PaymentSessionState(
      channelGroup: channelGroup ?? this.channelGroup,
      sessionId: sessionId ?? this.sessionId,
      currentStatus: currentStatus ?? this.currentStatus,
      result: identical(result, _unset)
          ? this.result
          : result as PaymentResult?,
      isCancelling: isCancelling ?? this.isCancelling,
      hasStarted: hasStarted ?? this.hasStarted,
      cancelDialog: cancelDialog ?? this.cancelDialog,
      requiresManualCompletion:
          requiresManualCompletion ?? this.requiresManualCompletion,
      confirmationReady: confirmationReady ?? this.confirmationReady,
      isConfirming: isConfirming ?? this.isConfirming,
      pendingReceipt: identical(pendingReceipt, _unset)
          ? this.pendingReceipt
          : pendingReceipt as Map<String, dynamic>?,
    );
  }
}

/// Temporary compatibility alias while callers migrate to the session name.
typedef PaymentFlowState = PaymentSessionState;
