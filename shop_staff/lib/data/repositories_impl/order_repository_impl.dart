import 'package:shop_staff/data/services/order_calling_payload.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';
import '../../domain/repositories/order_repository.dart';
import '../../core/localization/shop_language_code.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order_submission_result.dart';
import '../datasources/remote/pos_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
	final PosRemoteDataSource _remote;
	OrderRepositoryImpl(this._remote, {OrderCallingService? orderCallingService})
    : _orderCallingService = orderCallingService;
  final OrderCallingService? _orderCallingService;

	@override
	Future<OrderSubmissionResult> submitOrder({required List<CartItem> items, required String machineCode, required String language, required bool takeout, required double total}) async {
		final orderLines = <Map<String, dynamic>>[];
		for (final e in items) {
			final optionCodes = e.options.isEmpty
					? ''
					: e.options //when o.quantity > 1, just add same option multiple times like "OP1,OP1"
							.map((o) {
                String subOptions = '';
                for (int i = 0; i < o.quantity; i++) {
                  subOptions += o.optionCode + (i < o.quantity - 1 ? ',' : '');
                }
                return subOptions;
							})
							.join(',');
			final line = <String, dynamic>{
				'menuCode': e.product.id.toString(),
				'qty': e.quantity,
				if (optionCodes.isNotEmpty) 'optionList': optionCodes.split(','),
			};
			orderLines.add(line);
		}
		final payload = {
			'language': normalizeShopLanguageCode(language),
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
				final result = OrderSubmissionResult.fromJson(Map<String, dynamic>.from(data));
        if ((res['code'] == null || {0, 200, '0', '200'}.contains(res['code'])) &&
            result.orderId.isNotEmpty && !{'UNKNOWN', 'null'}.contains(result.orderId)) {
          try {
            await _orderCallingService?.enqueueOrder(localCallingPayload(
              order: result, items: items, machineCode: machineCode,
              takeout: takeout, language: language), source: 'local');
          } catch (_) { /* Calling delivery must not fail checkout. */ }
        }
        return result;
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
