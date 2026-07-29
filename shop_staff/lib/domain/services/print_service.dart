import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class PrintJobResult {
  const PrintJobResult({required this.printer, this.error});

  final PrinterSettings printer;
  final String? error;

  bool get isSuccess => error == null;
}

abstract class PrintService {
  Future<List<PrintJobResult>> enqueuePrintJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
    bool includeKitchenJobs = true,
    bool includeOrderTicket = true,
    String? logoImageBase64,
  });

  /// Enqueue a local customer receipt from `document.printInfo.orderLines`.
  Future<List<PrintJobResult>> enqueueReceiptJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
    String? logoImageBase64,
  });

  /// Enqueue external kitchen tickets by routing
  /// `document.printInfo.orderLinesMap` to printers.
  Future<List<PrintJobResult>> enqueueKitchenJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  });
}
