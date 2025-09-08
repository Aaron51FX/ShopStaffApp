import '../entities/cart_item.dart';
import '../repositories/order_repository.dart';

class PreviewOrderTotalUseCase {
  final OrderRepository repository;
  PreviewOrderTotalUseCase(this.repository);
  Future<double> call(List<CartItem> items) => repository.previewTotal(items);
}
