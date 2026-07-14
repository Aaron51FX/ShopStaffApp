import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';

/// Immutable menu snapshot handed to checkout.
class CheckoutDraft {
  const CheckoutDraft({
    required this.shop,
    required this.machineCode,
    required this.language,
    required this.takeout,
    required this.items,
    required this.orderNumber,
    required this.subtotal,
    required this.discount,
  });

  final ShopInfoModel shop;
  final String machineCode;
  final String language;
  final bool takeout;
  final List<CartItem> items;
  final int orderNumber;
  final double subtotal;
  final double discount;

  double get total =>
      (subtotal - discount).clamp(0, double.infinity).toDouble();
}
