import 'package:flutter/services.dart';
import 'package:shop_staff/domain/entities/receipt_document.dart';
import 'package:shop_staff/domain/services/native_receipt_printer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:starxpand_flutter/starxpand_flutter.dart';

class StarXpandNativeReceiptPrinter implements NativeReceiptPrinter {
  StarXpandNativeReceiptPrinter({StarXpandFlutter? plugin})
    : _plugin = plugin ?? StarXpandFlutter();

  final StarXpandFlutter _plugin;

  @override
  Future<void> printReceipt({
    required ReceiptDocument document,
    required PrinterSettings printer,
  }) async {
    final target = _toTarget(printer);

    try {
      await _plugin.printReceipt(
        receiptDocument: document.toJson(),
        printer: target,
        paperWidthMm: _paperWidthMm(printer),
      );
    } on MissingPluginException {
      throw StateError(
        'StarXpand Flutter plugin is not registered on this platform.',
      );
    } on PlatformException catch (error) {
      final message = error.message;
      throw StateError(
        message == null || message.isEmpty
            ? 'StarXpand native print failed (${error.code}).'
            : message,
      );
    }
  }

  StarXpandPrinterTarget _toTarget(PrinterSettings printer) {
    final transport = switch (printer.connectionType) {
      PrinterConnectionType.network => StarXpandTransport.network,
      PrinterConnectionType.bluetoothClassic =>
        StarXpandTransport.bluetoothClassic,
      PrinterConnectionType.bluetoothLe => StarXpandTransport.bluetoothLe,
      PrinterConnectionType.usb => StarXpandTransport.usb,
      PrinterConnectionType.usbC => StarXpandTransport.usbC,
      PrinterConnectionType.lightningUsb => StarXpandTransport.lightningUsb,
      PrinterConnectionType.unknown => throw StateError(
        'Unsupported StarXpand connection type.',
      ),
    };

    return StarXpandPrinterTarget(
      transport: transport,
      identifier: _trimOrNull(printer.deviceIdentifier),
      host: _trimOrNull(printer.printIp),
      port: int.tryParse(printer.printPort ?? ''),
      modelName: _trimOrNull(printer.modelName),
    );
  }

  int _paperWidthMm(PrinterSettings printer) {
    return switch (printer.receiptPaperWidthMm) {
      58 => 58,
      80 => 80,
      _ => 80,
    };
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
