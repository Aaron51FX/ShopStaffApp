import 'package:shop_staff/domain/payments/payment_models.dart';

sealed class PaymentAction {
  const PaymentAction();
}

class PaymentActionCancelTapped extends PaymentAction {
  const PaymentActionCancelTapped();
}

class PaymentActionRetryTapped extends PaymentAction {
  const PaymentActionRetryTapped();
}

class PaymentActionConfirmManualTapped extends PaymentAction {
  const PaymentActionConfirmManualTapped();
}

sealed class PaymentEvent {
  const PaymentEvent();
}

class PaymentEventStarted extends PaymentEvent {
  const PaymentEventStarted({required this.sessionId, required this.initialStatus});

  final String sessionId;
  final PaymentStatus initialStatus;
}

class PaymentEventStatusUpdated extends PaymentEvent {
  const PaymentEventStatusUpdated(this.status);

  final PaymentStatus status;
}

class PaymentEventCompleted extends PaymentEvent {
  const PaymentEventCompleted(this.result);

  final PaymentResult result;
}

class PaymentEventFailed extends PaymentEvent {
  const PaymentEventFailed(this.message);

  final String message;
}

sealed class PaymentEffect {
  const PaymentEffect();
}

class PaymentEffectToast extends PaymentEffect {
  const PaymentEffectToast({required this.message, this.isError = false});

  final String message;
  final bool isError;
}

class PaymentEffectRequestCancelConfirm extends PaymentEffect {
  const PaymentEffectRequestCancelConfirm({
    this.title = '注意',
    this.message = '确认要取消支付吗？',
    this.destructive = true,
  });

  final String title;
  final String message;
  final bool destructive;
}

class PaymentEffectStartPrint extends PaymentEffect {
  const PaymentEffectStartPrint();
}

class PaymentReduceResult {
  const PaymentReduceResult({required this.state, this.effects = const []});

  final PaymentUdfState state;
  final List<PaymentEffect> effects;
}

class PaymentUdfState {
  const PaymentUdfState({
    this.sessionId,
    this.currentStatus,
    this.timeline = const [],
    this.result,
    this.error,
  });

  final String? sessionId;
  final PaymentStatus? currentStatus;
  final List<PaymentStatus> timeline;
  final PaymentResult? result;
  final String? error;

  bool get hasStarted => sessionId != null;

  PaymentUdfState copyWith({
    String? sessionId,
    PaymentStatus? currentStatus,
    List<PaymentStatus>? timeline,
    PaymentResult? result,
    String? error,
  }) {
    return PaymentUdfState(
      sessionId: sessionId ?? this.sessionId,
      currentStatus: currentStatus ?? this.currentStatus,
      timeline: timeline ?? this.timeline,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}
