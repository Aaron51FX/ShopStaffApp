import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';

class PaymentFlowState {
  const PaymentFlowState({
    this.sessionId,
    this.currentStatus,
    this.timeline = const <PaymentStatus>[],
    this.result,
    this.error,
    this.isCancelling = false,
    this.hasStarted = false,
    this.cancelDialog = const CancelDialogState.hidden(),
    this.requiresManualCompletion = false,
    this.confirmationReady = false,
    this.isConfirming = false,
    this.pendingReceipt,
  });

  static const Object _unset = Object();

  final String? sessionId;
  final PaymentStatus? currentStatus;
  final List<PaymentStatus> timeline;
  final PaymentResult? result;
  final String? error;
  final bool isCancelling;
  final bool hasStarted;
  final CancelDialogState cancelDialog;
  final bool requiresManualCompletion;
  final bool confirmationReady;
  final bool isConfirming;
  final Map<String, dynamic>? pendingReceipt;

  bool get isFinished => result != null || (currentStatus?.isTerminal ?? false);
  bool get canExit => error != null || isFinished;

  PaymentFlowState copyWith({
    String? sessionId,
    PaymentStatus? currentStatus,
    List<PaymentStatus>? timeline,
    PaymentResult? result,
    String? error,
    bool? isCancelling,
    bool? hasStarted,
    CancelDialogState? cancelDialog,
    bool? requiresManualCompletion,
    bool? confirmationReady,
    bool? isConfirming,
    Object? pendingReceipt = _unset,
  }) {
    return PaymentFlowState(
      sessionId: sessionId ?? this.sessionId,
      currentStatus: currentStatus ?? this.currentStatus,
      timeline: timeline ?? this.timeline,
      result: result ?? this.result,
      error: error,
      isCancelling: isCancelling ?? this.isCancelling,
      hasStarted: hasStarted ?? this.hasStarted,
      cancelDialog: cancelDialog ?? this.cancelDialog,
      requiresManualCompletion: requiresManualCompletion ?? this.requiresManualCompletion,
      confirmationReady: confirmationReady ?? this.confirmationReady,
      isConfirming: isConfirming ?? this.isConfirming,
      pendingReceipt: identical(pendingReceipt, _unset)
          ? this.pendingReceipt
          : pendingReceipt as Map<String, dynamic>?,
    );
  }
}