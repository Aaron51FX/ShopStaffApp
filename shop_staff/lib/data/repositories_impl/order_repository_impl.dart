import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order_submission_result.dart';
import '../datasources/remote/pos_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
	final PosRemoteDataSource _remote;
	OrderRepositoryImpl(this._remote);

	@override
	Future<OrderSubmissionResult> submitOrder({required List<CartItem> items, required String machineCode, required String language, required bool takeout, required double total}) async {
		final orderLines = <Map<String, dynamic>>[];
		for (final e in items) {
			final optionCodes = e.options.isEmpty
					? ''
					: e.options
							.map((o) => '${o.groupCode}:${o.optionCode}${o.quantity > 1 ? 'x${o.quantity}' : ''}')
							.join(',');
			final line = <String, dynamic>{
				'menuCode': e.product.id.toString(),
				'qty': e.quantity,
				if (optionCodes.isNotEmpty) 'optionList': optionCodes.split(','),
			};
			orderLines.add(line);
		}
		final payload = {
			'language': language,
			'machineCode': machineCode,
			'orderLineList': orderLines,
			'total': total,
			'takeout': takeout,
		};
		final res = await _remote.submitOrderV4(payload);
		if (res is Map) {
			final root = Map<String, dynamic>.from(res);
			final data = root['data'];
			if (data is Map) {
				return OrderSubmissionResult.fromJson(Map<String, dynamic>.from(data));
			}
		}
		return const OrderSubmissionResult(orderId: 'UNKNOWN', tax1: 0, baseTax1: 0, tax2: 0, baseTax2: 0, total: 0);
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
