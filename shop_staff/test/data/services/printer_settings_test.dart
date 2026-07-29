import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
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

  group('CashMachineSettings', () {
    test('preserves nested cash machine config in basic settings json', () {
      const basic = BasicSettings(
        cashMachineEnabled: true,
        cashMachine: CashMachineSettings(
          enabled: true,
          brand: CashMachineBrand.star,
          connectionType: PrinterConnectionType.bluetoothClassic,
          deviceIdentifier: 'STAR-DRAWER-001',
          modelName: 'mC-Print3',
        ),
      );

      final decoded = BasicSettings.fromJson(basic.toJson());

      expect(decoded.cashMachineEnabled, isTrue);
      expect(decoded.cashMachine.enabled, isTrue);
      expect(decoded.cashMachine.brand, CashMachineBrand.star);
      expect(
        decoded.cashMachine.connectionType,
        PrinterConnectionType.bluetoothClassic,
      );
      expect(decoded.cashMachine.deviceIdentifier, 'STAR-DRAWER-001');
    });

    test('migrates legacy cash machine toggle into cash machine settings', () {
      final decoded = BasicSettings.fromJson(<String, dynamic>{
        'cashMachineEnabled': true,
      });

      expect(decoded.cashMachineEnabled, isTrue);
      expect(decoded.cashMachine.enabled, isTrue);
      expect(decoded.cashMachine.brand, isNull);
    });

    test('preserves display locale selection in basic settings json', () {
      const basic = BasicSettings(displayLocaleCode: 'ja');

      final decoded = BasicSettings.fromJson(basic.toJson());

      expect(decoded.displayLocaleCode, 'ja');
    });

    test('resolves payment modes and preserves explicit overrides', () {
      const basic = BasicSettings(
        cashMachine: CashMachineSettings(
          enabled: true,
          brand: CashMachineBrand.star,
        ),
        paymentModes: PaymentModeSettings(
          card: PaymentFlowMode.bookkeeping,
          qr: PaymentFlowMode.real,
        ),
      );

      final decoded = BasicSettings.fromJson(basic.toJson());

      expect(
        decoded.paymentModes.resolveCash(decoded.cashMachine),
        PaymentFlowMode.bookkeeping,
      );
      expect(decoded.paymentModes.resolveCard(), PaymentFlowMode.bookkeeping);
      expect(decoded.paymentModes.resolveQr(), PaymentFlowMode.real);
    });

    test('preserves locally enabled order modes', () {
      const basic = BasicSettings(
        orderModes: OrderModeSettings(
          dineIn: true,
          takeout: false,
          settlement: true,
        ),
      );

      final decoded = BasicSettings.fromJson(basic.toJson());

      expect(decoded.orderModes.dineIn, isTrue);
      expect(decoded.orderModes.takeout, isFalse);
      expect(decoded.orderModes.settlement, isTrue);
    });

    test('enables existing order modes when migrating legacy settings', () {
      final decoded = BasicSettings.fromJson(<String, dynamic>{
        'shopCode': 'shop-1',
      });

      expect(decoded.orderModes.dineIn, isTrue);
      expect(decoded.orderModes.takeout, isTrue);
      expect(decoded.orderModes.settlement, isTrue);
    });
  });
}
