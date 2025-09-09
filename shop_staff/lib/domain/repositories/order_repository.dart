import '../entities/cart_item.dart';

abstract class OrderRepository {
  Future<String> submitOrder(List<CartItem> items);
  Future<double> previewTotal(List<CartItem> items);
}
