import 'package:shop_staff/domain/services/payment_orchestrator.dart';

/// Continues result verification for an indeterminate payment session.
class ReconcilePaymentUseCase {
  ReconcilePaymentUseCase({required PaymentOrchestrator orchestrator})
    : _orchestrator = orchestrator;

  final PaymentOrchestrator _orchestrator;

  Future<void> call(String sessionId) => _orchestrator.reconcile(sessionId);
}
