import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/localization/locale_providers.dart';
import 'package:shop_staff/core/localization/shop_language_code.dart';

void main() {
  test('Chinese locale uses CH for backend language parameters', () {
    expect(localeToShopLanguageOverride(const Locale('zh')), 'CH');
  });

  test('legacy Chinese language codes normalize to CH', () {
    expect(normalizeShopLanguageCode('CN'), 'CH');
    expect(normalizeShopLanguageCode('zh'), 'CH');
    expect(normalizeShopLanguageCode('CH'), 'CH');
  });
}
