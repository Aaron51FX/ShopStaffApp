import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/settlement/settlement_checkout_adapter.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/settlement_order.dart';

void main() {
  test('maps scanned order data into existing checkout arguments', () {
    const settlement = SettlementOrder(
      orderId: '465512639757484032',
      totalPrice: 3147,
      discount: 100,
      voucherAmount: 50,
      payableAmount: 2997,
      tableNum: 'D1',
      tableNumText: 'Table',
      orderQty: 2,
      tax1: 237,
      tax2: 40,
      lines: [
        SettlementOrderLine(
          categoryName: 'Noodles',
          name: 'Beef noodles',
          initialPrice: 240,
          price: 220,
          qty: 2,
          options: {
            'Size': [
              SettlementOrderOption(
                name: 'Large',
                price: 10,
                qty: 1,
                totalPrice: null,
              ),
            ],
          },
        ),
      ],
    );

    final checkout = buildSettlementCheckoutData(
      settlement: settlement,
      shop: const ShopInfoModel(
        shopCode: 'shop-1',
        shopName: 'Shop',
        language: 'JP',
      ),
      machineCode: 'machine-1',
      language: 'JP',
    );

    expect(checkout.order.orderId, settlement.orderId);
    expect(checkout.order.total, 2997);
    expect(checkout.order.tax1, 237);
    expect(checkout.order.tax2, 40);
    expect(checkout.draft.subtotal, 3147);
    expect(checkout.draft.discount, 150);
    expect(checkout.draft.tableNumber, 'D1');
    expect(checkout.draft.tableNumberText, 'Table');
    expect(checkout.draft.isSettlement, isTrue);
    expect(checkout.draft.items.single.quantity, 2);
    expect(checkout.draft.items.single.product.price, 110);
    expect(checkout.draft.items.single.options.single.optionName, 'Large');
  });
}
