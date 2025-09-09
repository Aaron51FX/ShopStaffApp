import '../repositories/order_repository.dart';
import '../entities/cart_item.dart';

class SubmitOrderUseCase {
  final OrderRepository _repo;
  SubmitOrderUseCase(this._repo);
  Future<String> call(List<CartItem> items) => _repo.submitOrder(items);
}
