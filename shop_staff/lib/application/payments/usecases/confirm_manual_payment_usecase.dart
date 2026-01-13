import 'package:shop_staff/domain/services/payment_orchestrator.dart';

/// Confirms/finalizes a payment that requires explicit manual completion.
class ConfirmManualPaymentUseCase {
  ConfirmManualPaymentUseCase({required PaymentOrchestrator orchestrator})
      : _orchestrator = orchestrator;

  final PaymentOrchestrator _orchestrator;

  Future<void> call(String sessionId) => _orchestrator.finalize(sessionId);
}
