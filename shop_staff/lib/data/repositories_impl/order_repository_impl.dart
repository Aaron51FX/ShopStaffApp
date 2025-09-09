import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/cart_item.dart';
import '../datasources/remote/pos_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
	final PosRemoteDataSource _remote;
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
		double total = 0;
		for (final item in items) {
			total += item.lineTotal;
		}
		return total;
	}
}
