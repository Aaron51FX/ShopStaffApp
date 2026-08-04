import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/external_apps/smartwe_admin_launcher.dart';

void main() {
  test('opens the smartwe-admin custom URL scheme', () async {
    Uri? openedUri;
    final launcher = SmartWeAdminLauncher(
      openUri: (uri) async {
        openedUri = uri;
        return true;
      },
    );

    expect(await launcher.open(), isTrue);
    expect(openedUri.toString(), 'smartwe-admin://open');
  });
}
