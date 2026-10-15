import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/core/network/endpoints.dart';

void main() {
  test('SSE endpoints use the selected environment and encode identifiers', () {
    final production = Endpoints(AppConfig.forEnv(AppEnvironment.production));
    final staging = Endpoints(AppConfig.forEnv(AppEnvironment.staging));
    expect(
      production.sseSubscribeSmartWe('a/b'),
      'https://api.smartwe.jp/web/subscribe/smartWe/a%2Fb',
    );
    expect(
      staging.sseSubscribePanda('shop 1'),
      'https://sit-api.smartwe.jp/web/subscribe/panda/shop%201',
    );
    expect(
      staging.sseCallback,
      'https://sit-api.smartwe.jp/web/sse/received/callback',
    );
  });
}
