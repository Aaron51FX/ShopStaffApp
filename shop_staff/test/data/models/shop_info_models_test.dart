import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';

void main() {
  group('ShopInfoModel activation response', () {
    test('reads actuarial capability from nested activation data', () {
      final shop = ShopInfoModel.fromActivationResponse(<String, dynamic>{
        'data': <String, dynamic>{
          'shopCode': 'shop-1',
          'shopName': 'Shop',
          'language': 'JP',
          'actuarial': true,
        },
      });

      expect(shop.actuarial, isTrue);
    });

    test('reads the receipt logo URL from activation data', () {
      final shop = ShopInfoModel.fromActivationResponse(<String, dynamic>{
        'data': <String, dynamic>{
          'shopCode': 'shop-1',
          'shopName': 'Shop',
          'language': 'JP',
          'logoImage': 'https://example.com/shop-logo.png',
        },
      });

      expect(shop.logoImage, 'https://example.com/shop-logo.png');
    });

    test('defaults actuarial capability to false when absent', () {
      final shop = ShopInfoModel.fromActivationResponse(<String, dynamic>{
        'shopCode': 'shop-1',
        'shopName': 'Shop',
        'language': 'JP',
      });

      expect(shop.actuarial, isFalse);
    });
  });
}
