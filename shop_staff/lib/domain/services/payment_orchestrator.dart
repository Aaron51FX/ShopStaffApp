import '../payments/payment_models.dart';

/// Active payment session with buffered status and terminal result channels.
class PaymentSessionHandle {
  const PaymentSessionHandle({
    required this.sessionId,
    required this.initialStatus,
    required this.statuses,
    required this.result,
    required Future<void> Function() cancel,
    Future<void> Function()? finalize,
    this.requiresManualCompletion = false,
  }) : _cancel = cancel,
       _finalize = finalize;

  final String sessionId;
  final PaymentStatus initialStatus;
  final Stream<PaymentStatus> statuses;
  final Future<PaymentResult> result;
  final bool requiresManualCompletion;
  final Future<void> Function() _cancel;
  final Future<void> Function()? _finalize;

  Future<void> cancel() => _cancel();

  Future<void> finalize() {
    final action = _finalize;
    if (action == null) {
      throw StateError('PAYMENT_FINALIZE_NOT_REQUIRED');
    }
    return action();
  }
}

/// High level orchestrator that maps logical channels to payment flows and exposes
/// unified lifecycle controls for the UI/ViewModels.
abstract class PaymentOrchestrator {
  /// Start a payment flow based on the [context].
  PaymentSessionHandle start(PaymentContext context);

  /// Observe status updates for a given session.
  Stream<PaymentStatus> watch(String sessionId);

  /// Await the terminal result for the session.
  Future<PaymentResult> result(String sessionId);

  /// Cancel the session if it is still running.
  Future<void> cancel(String sessionId);

  /// Finalize a session that requires an explicit confirmation step.
  Future<void> finalize(String sessionId);
}
