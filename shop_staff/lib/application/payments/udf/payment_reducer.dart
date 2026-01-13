import 'package:shop_staff/domain/payments/payment_models.dart';

import 'payment_udf_models.dart';

/// Minimal pure reducer for payment flow.
///
/// Notes:
/// - This is intentionally NOT wired into current ViewModels yet.
/// - Side-effects are represented as [PaymentEffect] values.
class PaymentReducer {
  const PaymentReducer();

  PaymentReduceResult reduce(
    PaymentUdfState state, {
    PaymentAction? action,
    PaymentEvent? event,
  }) {
    assert(
      (action == null) != (event == null),
      'Pass exactly one of action/event',
    );

    if (action != null) {
      return _reduceAction(state, action);
    }
    return _reduceEvent(state, event!);
  }

  PaymentReduceResult _reduceAction(PaymentUdfState state, PaymentAction action) {
    if (action is PaymentActionCancelTapped) {
      return PaymentReduceResult(
        state: state,
        effects: const [PaymentEffectRequestCancelConfirm()],
      );
    }

    if (action is PaymentActionRetryTapped) {
      // Minimal skeleton: real retry is orchestrated by a usecase.
      return PaymentReduceResult(
        state: state,
        effects: const [PaymentEffectToast(message: '正在重试…')],
      );
    }

    if (action is PaymentActionConfirmManualTapped) {
      return PaymentReduceResult(
        state: state,
        effects: const [PaymentEffectToast(message: '正在确认…')],
      );
    }

    return PaymentReduceResult(state: state);
  }

  PaymentReduceResult _reduceEvent(PaymentUdfState state, PaymentEvent event) {
    if (event is PaymentEventStarted) {
      final next = state.copyWith(
        sessionId: event.sessionId,
        currentStatus: event.initialStatus,
        timeline: <PaymentStatus>[event.initialStatus],
        error: null,
        result: null,
      );
      return PaymentReduceResult(state: next);
    }

    if (event is PaymentEventStatusUpdated) {
      final nextTimeline = List<PaymentStatus>.from(state.timeline)
        ..add(_snapshot(event.status));
      final next = state.copyWith(
        currentStatus: event.status,
        timeline: nextTimeline,
      );
      return PaymentReduceResult(state: next);
    }

    if (event is PaymentEventCompleted) {
      final next = state.copyWith(result: event.result);
      final effects = <PaymentEffect>[];
      switch (event.result.status) {
        case PaymentStatusType.success:
          effects.add(PaymentEffectToast(message: event.result.message ?? '支付成功'));
          effects.add(const PaymentEffectStartPrint());
          break;
        case PaymentStatusType.failure:
          effects.add(PaymentEffectToast(message: event.result.message ?? '支付失败', isError: true));
          break;
        case PaymentStatusType.cancelled:
        default:
          break;
      }
      return PaymentReduceResult(state: next, effects: effects);
    }

    if (event is PaymentEventFailed) {
      final next = state.copyWith(error: event.message);
      return PaymentReduceResult(
        state: next,
        effects: [PaymentEffectToast(message: event.message, isError: true)],
      );
    }

    return PaymentReduceResult(state: state);
  }

  PaymentStatus _snapshot(PaymentStatus status) {
    final details = status.details;
    Map<String, dynamic>? clonedDetails;
    if (details != null) {
      clonedDetails = Map<String, dynamic>.from(details);
    }
    return PaymentStatus(
      type: status.type,
      message: status.message,
      details: clonedDetails,
    );
  }
}
