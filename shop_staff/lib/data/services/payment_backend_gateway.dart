import 'package:shop_staff/domain/payments/payment_models.dart';

/// Abstraction for server-side payment confirmation calls.
abstract class PaymentBackendGateway {
  Future<void> confirmPayment(PaymentContext context, Map<String, dynamic> payload);
}
