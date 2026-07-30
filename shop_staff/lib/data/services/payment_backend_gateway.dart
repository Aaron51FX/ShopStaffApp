import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

/// Abstraction for server-side payment confirmation calls.
abstract class PaymentBackendGateway {
  Future<PrintInfoDocument?> confirmPayment(
    PaymentContext context,
    Map<String, dynamic> payload,
  );
}
