import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';

class ObservePaymentStatusUseCase {
  ObservePaymentStatusUseCase({required PaymentOrchestrator orchestrator})
      : _orchestrator = orchestrator;

  final PaymentOrchestrator _orchestrator;

  Stream<PaymentStatus> call(String sessionId) => _orchestrator.watch(sessionId);
}
