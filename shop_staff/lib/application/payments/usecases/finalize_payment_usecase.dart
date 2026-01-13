import 'package:shop_staff/domain/services/payment_orchestrator.dart';

class FinalizePaymentUseCase {
  FinalizePaymentUseCase({required PaymentOrchestrator orchestrator})
      : _orchestrator = orchestrator;

  final PaymentOrchestrator _orchestrator;

  Future<void> call(String sessionId) => _orchestrator.finalize(sessionId);
}
