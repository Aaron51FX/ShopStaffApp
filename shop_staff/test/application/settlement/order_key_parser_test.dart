import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/settlement/order_key_parser.dart';

void main() {
  group('parseSettlementOrderKey', () {
    test('accepts a plain order key', () {
      expect(
        parseSettlementOrderKey('2Ou79s0VumJdMMjLOPoFA'),
        '2Ou79s0VumJdMMjLOPoFA',
      );
    });

    test('extracts p from an order link', () {
      expect(
        parseSettlementOrderKey(
          'https://sit-mobile.smartwe.jp/index?p=2Ou79s0VumJdMMjLOPoFA',
        ),
        '2Ou79s0VumJdMMjLOPoFA',
      );
    });

    test('rejects a link without p', () {
      expect(
        () => parseSettlementOrderKey(
          'https://sit-mobile.smartwe.jp/index?order=123',
        ),
        throwsFormatException,
      );
    });
  });
}
