import 'package:flutter/services.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:starxpand_flutter/starxpand_flutter.dart';

class StarXpandCashDrawerService {
  StarXpandCashDrawerService({StarXpandFlutter? plugin})
    : _plugin = plugin ?? StarXpandFlutter();

  final StarXpandFlutter _plugin;

  Future<StarXpandDrawerStatus> getStatus({
    required CashMachineSettings settings,
  }) async {
    final target = _toTarget(settings);

    try {
      return await _plugin.getDrawerStatus(printer: target);
    } on MissingPluginException {
      throw StateError(
        'StarXpand Flutter plugin is not registered on this platform.',
      );
    } on PlatformException catch (error) {
      final message = error.message;
      throw StateError(
        message == null || message.isEmpty
            ? 'Star drawer status check failed (${error.code}).'
            : message,
      );
    }
  }

  Future<void> openDrawer({
    required CashMachineSettings settings,
    StarXpandDrawerChannel channel = StarXpandDrawerChannel.no1,
    int onTimeMs = 200,
  }) async {
    final target = _toTarget(settings);

    try {
      await _plugin.openDrawer(
        printer: target,
        channel: channel,
        onTimeMs: onTimeMs,
      );
    } on MissingPluginException {
      throw StateError(
        'StarXpand Flutter plugin is not registered on this platform.',
      );
    } on PlatformException catch (error) {
      final message = error.message;
      throw StateError(
        message == null || message.isEmpty
            ? 'Star drawer open failed (${error.code}).'
            : message,
      );
    }
  }

  StarXpandPrinterTarget _toTarget(CashMachineSettings settings) {
    final transport = switch (settings.connectionType) {
      PrinterConnectionType.network => StarXpandTransport.network,
      PrinterConnectionType.bluetoothClassic =>
        StarXpandTransport.bluetoothClassic,
      PrinterConnectionType.bluetoothLe => StarXpandTransport.bluetoothLe,
      PrinterConnectionType.usb => StarXpandTransport.usb,
      PrinterConnectionType.usbC => StarXpandTransport.usbC,
      PrinterConnectionType.lightningUsb => StarXpandTransport.lightningUsb,
      PrinterConnectionType.unknown => throw StateError(
        'Unsupported StarXpand connection type for cash drawer.',
      ),
    };

    return StarXpandPrinterTarget(
      transport: transport,
      identifier: _trimOrNull(settings.deviceIdentifier),
      host: _trimOrNull(settings.host),
      modelName: _trimOrNull(settings.modelName),
    );
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
