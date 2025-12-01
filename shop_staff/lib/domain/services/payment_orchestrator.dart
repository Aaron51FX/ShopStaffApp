import '../payments/payment_models.dart';

/// Session descriptor returned when a payment flow starts.
class PaymentSession {
  const PaymentSession({
    required this.sessionId,
    required this.initialStatus,
    this.requiresManualCompletion = false,
  });

  final String sessionId;
  final PaymentStatus initialStatus;
  final bool requiresManualCompletion;
}

/// High level orchestrator that maps logical channels to payment flows and exposes
/// unified lifecycle controls for the UI/ViewModels.
abstract class PaymentOrchestrator {
  /// Start a payment flow based on the [context].
  PaymentSession start(PaymentContext context);

  /// Observe status updates for a given session.
  Stream<PaymentStatus> watch(String sessionId);

  /// Await the terminal result for the session.
  Future<PaymentResult> result(String sessionId);

  /// Cancel the session if it is still running.
  Future<void> cancel(String sessionId);

  /// Finalize a session that requires an explicit confirmation step.
  Future<void> finalize(String sessionId);
}
