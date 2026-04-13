import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

void main() {
  group('PrinterSettings', () {
    test('preserves backend and connection type across json', () {
      const settings = PrinterSettings(
        name: 'Star Front',
        type: 12,
        backend: PrinterBackend.starXpandNative,
        connectionType: PrinterConnectionType.bluetoothLe,
        isOn: true,
        deviceIdentifier: 'STAR-123',
        modelName: 'mC-Print3',
      );

      final decoded = PrinterSettings.fromJson(settings.toJson());

      expect(decoded.backend, PrinterBackend.starXpandNative);
      expect(decoded.connectionType, PrinterConnectionType.bluetoothLe);
      expect(decoded.deviceIdentifier, 'STAR-123');
      expect(decoded.modelName, 'mC-Print3');
      expect(decoded.usesNativeSdk, isTrue);
      expect(decoded.requiresDeviceIdentifier, isTrue);
    });

    test('defaults legacy printers to widget raster network mode', () {
      final decoded = PrinterSettings.fromJson(<String, dynamic>{
        'name': 'Legacy Receipt',
        'type': 10,
        'printIp': '192.168.0.99',
        'printPort': '9100',
      });

      expect(decoded.backend, PrinterBackend.widgetRaster);
      expect(decoded.connectionType, PrinterConnectionType.network);
      expect(decoded.usesWidgetRaster, isTrue);
      expect(decoded.requiresNetworkEndpoint, isTrue);
    });

    test('default profiles include the local printer slot', () {
      final profiles = PrinterSettings.defaultProfiles();
      final localPrinter = profiles.firstWhere(
        (printer) => printer.type == PrinterSettings.localType,
      );

      expect(localPrinter.backend, PrinterBackend.starXpandNative);
      expect(localPrinter.connectionType, PrinterConnectionType.unknown);
      expect(localPrinter.isOn, isFalse);
    });

    test(
      'mergeWithDefaults injects the local printer into legacy settings',
      () {
        final merged =
            PrinterSettings.mergeWithDefaults(const <PrinterSettings>[
              PrinterSettings(
                name: 'Kitchen',
                type: PrinterSettings.kitchenType,
                backend: PrinterBackend.widgetRaster,
                connectionType: PrinterConnectionType.network,
                printIp: '192.168.1.20',
              ),
            ]);

        expect(
          merged.any((printer) => printer.type == PrinterSettings.localType),
          isTrue,
        );
        expect(
          merged.where(
            (printer) => printer.type == PrinterSettings.kitchenType,
          ),
          hasLength(2),
        );
      },
    );
  });
}
