import '../entities/cart_item.dart';
import '../entities/order_submission_result.dart';

abstract class OrderRepository {
  Future<OrderSubmissionResult> submitOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
  });
  Future<double> previewTotal(List<CartItem> items);
}
