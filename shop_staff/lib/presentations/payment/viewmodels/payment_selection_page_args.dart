import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';

class PaymentSelectionPageArgs {
  const PaymentSelectionPageArgs({
    required this.order,
    required this.shop,
    required this.machineCode,
    required this.language,
    required this.takeout,
    required this.items,
    required this.orderNumber,
    required this.subtotal,
    required this.discount,
  });

  final OrderSubmissionResult order;
  final ShopInfoModel shop;
  final String machineCode;
  final String language;
  final bool takeout;
  final List<CartItem> items;
  final int orderNumber;
  final double subtotal;
  final double discount;
}
