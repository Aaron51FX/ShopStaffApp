import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/network/app_environment.dart';

void main() {
  group('appEnvironmentFromDartDefine', () {
    test('defaults to production', () {
      expect(appEnvironmentFromDartDefine(null), AppEnvironment.production);
    });

    test('maps prod-like values to production', () {
      expect(
        appEnvironmentFromDartDefine('production'),
        AppEnvironment.production,
      );
      expect(appEnvironmentFromDartDefine('prod'), AppEnvironment.production);
    });

    test('maps dev-like values to staging', () {
      expect(appEnvironmentFromDartDefine('staging'), AppEnvironment.staging);
      expect(appEnvironmentFromDartDefine('dev'), AppEnvironment.staging);
      expect(
        appEnvironmentFromDartDefine('development'),
        AppEnvironment.staging,
      );
    });
  });
}
