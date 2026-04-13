import 'package:flutter/services.dart';

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
}
