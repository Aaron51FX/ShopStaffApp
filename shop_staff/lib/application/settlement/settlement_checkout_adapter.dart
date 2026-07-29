import '../../data/models/shop_info_models.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order_submission_result.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/settlement_order.dart';
import '../checkout/models/checkout_draft.dart';

class SettlementCheckoutData {
  const SettlementCheckoutData({required this.draft, required this.order});

  final CheckoutDraft draft;
  final OrderSubmissionResult order;
}

SettlementCheckoutData buildSettlementCheckoutData({
  required SettlementOrder settlement,
  required ShopInfoModel shop,
  required String machineCode,
  required String language,
}) {
  final items = <CartItem>[
    for (var index = 0; index < settlement.lines.length; index++)
      _toCartItem(settlement.lines[index], index),
  ];
  final orderNumber = int.tryParse(settlement.orderId) ?? 0;
  final discount = settlement.discount + settlement.voucherAmount;
  final order = OrderSubmissionResult(
    orderId: settlement.orderId,
    tax1: settlement.tax1,
    baseTax1: 0,
    tax2: settlement.tax2,
    baseTax2: 0,
    total: settlement.payableAmount,
  );
  return SettlementCheckoutData(
    draft: CheckoutDraft(
      shop: shop,
      machineCode: machineCode,
      language: language,
      takeout: false,
      items: items,
      orderNumber: orderNumber,
      subtotal: settlement.totalPrice.toDouble(),
      discount: discount.toDouble(),
      tableNumber: settlement.tableNum.trim().isEmpty
          ? null
          : settlement.tableNum.trim(),
      tableNumberText: settlement.tableNumText.trim().isEmpty
          ? null
          : settlement.tableNumText.trim(),
      isSettlement: true,
    ),
    order: order,
  );
}

CartItem _toCartItem(SettlementOrderLine line, int index) {
  final quantity = line.qty <= 0 ? 1 : line.qty;
  final selectedOptions = <SelectedOption>[];
  var optionIndex = 0;
  for (final group in line.options.entries) {
    for (final option in group.value) {
      selectedOptions.add(
        SelectedOption(
          groupCode: group.key,
          groupName: group.key,
          optionCode: '${group.key}_${optionIndex++}',
          optionName: option.name,
          extraPrice: option.price.toDouble(),
          quantity: option.qty <= 0 ? 1 : option.qty,
        ),
      );
    }
  }
  final unitPrice = line.price / quantity;
  final initialUnitPrice = (line.initialPrice ?? line.price) / quantity;
  return CartItem(
    id: 'settlement_${index + 1}',
    product: Product(
      id: index + 1,
      name: line.name,
      categoryId: line.categoryName ?? '',
      price: unitPrice,
      originalPrice: initialUnitPrice,
      tax: 0,
      imageUrl: '',
    ),
    options: selectedOptions,
    quantity: quantity,
  );
}
