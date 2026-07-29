import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/entities/settlement_order.dart';

void main() {
  test('parses settlement totals, lines, and grouped options', () {
    final order = SettlementOrder.fromJson(<String, dynamic>{
      'orderId': 465512639757484032,
      'totalPrice': 3147,
      'discount': 0,
      'voucherAmount': 20,
      'payableAmount': 3127,
      'tableNum': 'Ｄ１',
      'tableNumText': 'お席番号：',
      'orderQty': 1,
      'tax1': 237,
      'tax2': 40,
      'orderLines': <Object?>[
        <String, dynamic>{
          'name': '甘蘭牛肉麺',
          'price': 110,
          'qty': 1,
          'options': <String, dynamic>{
            'セットメニュー': <Object?>[
              <String, dynamic>{
                'name': '牛串焼',
                'price': 10,
                'qty': 2,
                'totalPrice': null,
              },
            ],
          },
        },
      ],
    });

    expect(order.orderId, '465512639757484032');
    expect(order.payableAmount, 3127);
    expect(order.lines, hasLength(1));
    expect(order.lines.single.name, '甘蘭牛肉麺');
    final option = order.lines.single.flattenedOptions.single;
    expect(option.key, 'セットメニュー');
    expect(option.value.name, '牛串焼');
    expect(option.value.displayTotal, 20);
  });

  test('treats a not-yet-ordered response as an empty order', () {
    final order = SettlementOrder.fromJson(<String, dynamic>{
      'orderId': null,
      'totalPrice': 0,
      'discount': 0,
      'voucherAmount': null,
      'payableAmount': null,
      'tableNum': '',
      'tableNumText': '',
      'orderQty': 0,
      'tax1': 0,
      'tax2': 0,
      'orderInfoMap': null,
      'orderLines': <Object?>[],
    });

    expect(order.orderId, isEmpty);
    expect(order.payableAmount, 0);
    expect(order.lines, isEmpty);
  });
}
