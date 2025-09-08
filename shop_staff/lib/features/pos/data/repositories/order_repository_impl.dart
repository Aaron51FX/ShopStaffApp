import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/remote/pos_remote_datasource.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return OrderRepositoryImpl(ds);
});

class OrderRepositoryImpl implements OrderRepository {
  final dynamic _remote; // PosRemoteDataSource
  OrderRepositoryImpl(this._remote);

  @override
  Future<String> submitOrder(List<CartItem> items) async {
    final payload = {
      'items': items
          .map((e) => {
                'menuCode': e.product.id.toString(),
                'qty': e.quantity,
                'price': e.product.price,
              })
          .toList(),
    };
    final res = await _remote.submitOrderV4(payload);
    if (res is Map && res['orderId'] != null) return res['orderId'].toString();
    return 'UNKNOWN';
  }

  @override
  Future<double> previewTotal(List<CartItem> items) async {
    // Compute locally; could delegate to remote calculate endpoint later.
    double total = 0;
    for (final item in items) {
      total += item.lineTotal;
    }
    return total;
  }
}
