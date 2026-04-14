import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/models/starxpand_printer_target.dart';
import 'src/models/starxpand_discovered_printer.dart';
import 'src/models/starxpand_drawer.dart';
import 'src/models/receipt_document_payload.dart';
import 'src/plan/receipt_print_plan_builder.dart';
import 'src/starxpand_flutter_method_channel.dart';

export 'src/models/starxpand_printer_target.dart';
export 'src/models/starxpand_discovered_printer.dart';
export 'src/models/starxpand_drawer.dart';

class StarXpandFlutter {
  StarXpandFlutter({StarXpandFlutterMethodChannel? channel})
    : _channel = channel ?? const StarXpandFlutterMethodChannel();

  final StarXpandFlutterMethodChannel _channel;

  Future<List<StarXpandDiscoveredPrinter>> discoverPrinters({
    List<StarXpandTransport>? transports,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      return await _channel.discoverPrinters(
        transports: transports ?? _defaultDiscoveryTransports(),
        timeoutMs: timeout.inMilliseconds,
      );
    } on MissingPluginException {
      rethrow;
    } on PlatformException {
      rethrow;
    }
  }

  List<StarXpandTransport> _defaultDiscoveryTransports() {
    if (kIsWeb) {
      return const <StarXpandTransport>[];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const <StarXpandTransport>[
          StarXpandTransport.network,
          StarXpandTransport.bluetoothClassic,
          StarXpandTransport.bluetoothLe,
          StarXpandTransport.lightningUsb,
        ];
      case TargetPlatform.android:
        return const <StarXpandTransport>[
          StarXpandTransport.network,
          StarXpandTransport.bluetoothClassic,
          StarXpandTransport.usbC,
        ];
      default:
        return StarXpandTransport.values;
    }
  }

  Future<void> printReceipt({
    required Map<String, dynamic> receiptDocument,
    required StarXpandPrinterTarget printer,
    String? logoAssetKey,
    String? footerNote,
    int paperWidthMm = 72,
    bool includeCut = true,
  }) async {
    final payload = ReceiptDocumentPayload.fromJson(receiptDocument);
    final plan = ReceiptPrintPlanBuilder.build(
      payload,
      logoAssetKey: logoAssetKey,
      footerNote: footerNote,
      paperWidthMm: paperWidthMm,
      includeCut: includeCut,
    );

    try {
      await _channel.printReceipt(
        printer: printer,
        receiptDocument: receiptDocument,
        printPlan: plan.toJson(),
      );
    } on MissingPluginException {
      rethrow;
    } on PlatformException {
      rethrow;
    }
  }

  Future<StarXpandDrawerStatus> getDrawerStatus({
    required StarXpandPrinterTarget printer,
  }) async {
    try {
      return await _channel.getDrawerStatus(printer: printer);
    } on MissingPluginException {
      rethrow;
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> openDrawer({
    required StarXpandPrinterTarget printer,
    StarXpandDrawerChannel channel = StarXpandDrawerChannel.no1,
    int onTimeMs = 200,
  }) async {
    try {
      await _channel.openDrawer(
        printer: printer,
        channel: channel,
        onTimeMs: onTimeMs,
      );
    } on MissingPluginException {
      rethrow;
    } on PlatformException {
      rethrow;
    }
  }
}
