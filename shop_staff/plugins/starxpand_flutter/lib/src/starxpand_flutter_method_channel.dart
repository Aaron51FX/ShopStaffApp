import 'package:flutter/services.dart';

import 'models/starxpand_discovered_printer.dart';
import 'models/starxpand_drawer.dart';
import 'models/starxpand_printer_target.dart';

class StarXpandFlutterMethodChannel {
  const StarXpandFlutterMethodChannel();

  static const MethodChannel _methodChannel = MethodChannel(
    'starxpand_flutter/methods',
  );

  Future<void> printReceipt({
    required StarXpandPrinterTarget printer,
    required Map<String, dynamic> receiptDocument,
    required Map<String, dynamic> printPlan,
  }) {
    return _methodChannel.invokeMethod<void>('printReceipt', <String, dynamic>{
      'printer': printer.toJson(),
      'receiptDocument': receiptDocument,
      'printPlan': printPlan,
    });
  }

  Future<List<StarXpandDiscoveredPrinter>> discoverPrinters({
    required List<StarXpandTransport> transports,
    required int timeoutMs,
  }) async {
    final response = await _methodChannel
        .invokeMethod<List<dynamic>>('discoverPrinters', <String, dynamic>{
          'transports': transports
              .map((transport) => transport.wireValue)
              .toList(),
          'timeoutMs': timeoutMs,
        });

    final entries = response ?? const <dynamic>[];
    return entries
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (entry) => StarXpandDiscoveredPrinter.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  Future<StarXpandDrawerStatus> getDrawerStatus({
    required StarXpandPrinterTarget printer,
  }) async {
    final response = await _methodChannel.invokeMapMethod<String, dynamic>(
      'getDrawerStatus',
      <String, dynamic>{'printer': printer.toJson()},
    );

    return StarXpandDrawerStatus.fromJson(response ?? const <String, dynamic>{});
  }

  Future<void> openDrawer({
    required StarXpandPrinterTarget printer,
    required StarXpandDrawerChannel channel,
    required int onTimeMs,
  }) {
    return _methodChannel.invokeMethod<void>('openDrawer', <String, dynamic>{
      'printer': printer.toJson(),
      'channel': channel.wireValue,
      'onTimeMs': onTimeMs,
    });
  }
}
