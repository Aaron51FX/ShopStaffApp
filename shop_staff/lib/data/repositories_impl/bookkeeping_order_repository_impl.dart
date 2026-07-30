import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/core/localization/shop_language_code.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';

class BookkeepingOrderRepositoryImpl implements BookkeepingOrderRepository {
  BookkeepingOrderRepositoryImpl(this._remote);

  final PosRemoteDataSource _remote;

  @override
  Future<OrderSubmissionResult> submitOfflineOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
    String? shopCode,
  }) async {
    final payload = <String, dynamic>{
      'language': normalizeShopLanguageCode(language),
      'machineCode': machineCode,
      'orderLineList': _buildOrderLineList(items),
      'total': total.round(),
      'takeout': takeout,
      if (shopCode != null && shopCode.trim().isNotEmpty) 'shopCode': shopCode,
    };

    final res = await _remote.submitOfflineOrderV1(payload);
    return _parseOrderSubmissionResult(res);
  }

  @override
  Future<void> recordOrder(BookkeepingOrderRecordInput input) async {
    final channelLabel = _resolveChannelLabel(
      group: input.channelGroup,
      code: input.channelCode,
      displayName: input.channelDisplayName,
    );
    final payload = <String, dynamic>{
      'create_time': input.createdAt.toIso8601String(),
      'from_plate': 'Shop',
      'machineCode': input.machineCode,
      'order_sn_code': input.orderSnCode ?? input.order.orderId,
      'order_type': input.takeout ? 'Take_Out' : 'Shop_In',
      'pay_type': channelLabel,
      'remark':
          'BOOKKEEPING:${input.channelGroup}:${input.channelCode}:TOTAL=${input.order.total}',
      'orderLineVos': input.items.map(_mapOtherOrderLine).toList(),
    };

    await _remote.recordStaffOrderV1(payload);
  }

  @override
  Future<PrintInfoDocument> updateOrderState(
    OrderStateUpdateInput input,
  ) async {
    final payload = <String, dynamic>{
      'payPrice': input.payPrice,
      'payChannel': input.payChannel,
      'orderId': int.tryParse(input.orderId) ?? input.orderId,
      'discount': input.discount,
      'finalTotal': input.finalTotal,
      'machineCode': input.machineCode,
    };
    final response = await _remote.updateStaffOrderStateV1(payload);
    if (response is! Map) {
      throw StateError('ORDER_STATE_UPDATE_RESPONSE_INVALID');
    }
    final data = response['data'];
    if (data is! Map) {
      throw StateError('ORDER_STATE_UPDATE_DATA_MISSING');
    }
    return PrintInfoDocument.fromJson(Map<String, dynamic>.from(data));
  }

  List<Map<String, dynamic>> _buildOrderLineList(List<CartItem> items) {
    final orderLines = <Map<String, dynamic>>[];
    for (final item in items) {
      final optionCodes = item.options
          .expand(
            (option) => List<String>.filled(
              option.quantity,
              option.optionCode,
              growable: false,
            ),
          )
          .where((code) => code.trim().isNotEmpty)
          .toList(growable: false);

      orderLines.add(<String, dynamic>{
        'menuCode': item.product.id.toString(),
        'qty': item.quantity,
        if (optionCodes.isNotEmpty) 'optionList': optionCodes,
      });
    }
    return orderLines;
  }

  Map<String, dynamic> _mapOtherOrderLine(CartItem item) {
    return <String, dynamic>{
      'item_count': item.quantity,
      'item_name': item.product.name,
      'item_groups': item.options
          .map(
            (option) => <String, dynamic>{
              'itemGroupName': option.groupName,
              'itemOptionName': option.optionName,
              'itemOptionCount': option.quantity,
            },
          )
          .toList(growable: false),
    };
  }

  String _resolveChannelLabel({
    required String group,
    required String code,
    String? displayName,
  }) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    if (code.trim().isNotEmpty && code.trim().toLowerCase() != group) {
      return code.trim();
    }
    switch (group) {
      case PaymentChannels.cash:
        return '现金';
      case PaymentChannels.card:
        return '信用卡';
      case PaymentChannels.qr:
        return '二维码';
      default:
        return group;
    }
  }

  OrderSubmissionResult _parseOrderSubmissionResult(dynamic res) {
    if (res is Map) {
      final root = Map<String, dynamic>.from(res);
      final data = root['data'];
      if (data is Map) {
        return OrderSubmissionResult.fromJson(Map<String, dynamic>.from(data));
      }
    }
    return const OrderSubmissionResult(
      orderId: 'UNKNOWN',
      tax1: 0,
      baseTax1: 0,
      tax2: 0,
      baseTax2: 0,
      total: 0,
    );
  }
}
