import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/data/models/print_info.dart';

class BookkeepingOrderRecordInput {
  const BookkeepingOrderRecordInput({
    required this.order,
    required this.items,
    required this.machineCode,
    required this.channelGroup,
    required this.channelCode,
    required this.channelDisplayName,
    required this.takeout,
    required this.createdAt,
    this.orderSnCode,
  });

  final OrderSubmissionResult order;
  final List<CartItem> items;
  final String machineCode;
  final String channelGroup;
  final String channelCode;
  final String? channelDisplayName;
  final bool takeout;
  final DateTime createdAt;
  final String? orderSnCode;
}

class OrderStateUpdateInput {
  const OrderStateUpdateInput({
    required this.orderId,
    required this.machineCode,
    required this.payChannel,
    required this.discount,
    required this.finalTotal,
    this.payPrice,
  });

  final String orderId;
  final String machineCode;
  final String payChannel;
  final int discount;
  final int finalTotal;
  final int? payPrice;
}

abstract class BookkeepingOrderRepository {
  Future<OrderSubmissionResult> submitOfflineOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
    String? shopCode,
  });

  Future<void> recordOrder(BookkeepingOrderRecordInput input);

  Future<PrintInfoDocument> updateOrderState(OrderStateUpdateInput input);
}
