import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';

/// Match the legacy display service's ticket JSON without fetching/printing a receipt.
Map<String, dynamic> localCallingPayload({
  required OrderSubmissionResult order,
  required List<CartItem> items,
  required String machineCode,
  required bool takeout,
  required String language,
  String? shopCode,
}) {
  final source = order.sourceData ?? const <String, dynamic>{};
  final ticket = source['printInfo'];
  final lines = items.map((item) {
    final options = <String, List<Map<String, dynamic>>>{};
    for (final option in item.options) {
      options.putIfAbsent(option.groupName, () => []).add({
        'name': option.optionName,
        'qty': option.quantity,
        'price': option.extraPrice,
        'optionCode': option.optionCode,
      });
    }
    return <String, dynamic>{
      'name': item.product.name,
      'qty': item.quantity,
      'price': item.unitPrice,
      'menuCode': item.product.id.toString(),
      'categoryName': '',
      'categoryCode': item.product.categoryId,
      'options': options,
      'remark': item.note ?? '',
    };
  }).toList();
  final payload = <String, dynamic>{
    ...source,
    'orderId': order.orderId,
    'machineCode': machineCode,
    if (shopCode != null) 'shopCode': shopCode,
    'language': language,
    'from_plate': 'Shop', 'order_type': takeout ? 'Take_Out' : 'Shop_In',
    'orderTime': DateTime.now().toIso8601String(),
    'total': order.total,
    // Bucket 0 means this local submission has not received backend printer routing.
    'orderLines': source['orderLines'] ?? lines,
    'orderLinesMap': source['orderLinesMap'] ?? {'0': lines},
    if (ticket is Map) ...Map<String, dynamic>.from(ticket),
  };
  final uuid = payload['uuid']?.toString().trim() ?? '';
  if (uuid.isEmpty) payload['uuid'] = 'shopstaff:$machineCode:${order.orderId}';
  payload['order_sn_code'] =
      payload['order_sn_code'] ??
      source['orderSnCode'] ??
      source['serialNumberText'] ??
      source['serialNumber'] ??
      source['serialNo'] ??
      order.orderId;
  return payload;
}
