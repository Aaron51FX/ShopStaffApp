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
  });

  /// Enqueue receipt-only print tasks (no kitchen/label split) for a document.
  Future<List<PrintJobResult>> enqueueReceiptJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  });

  /// Enqueue kitchen tickets by routing `document.printInfo.orderLinesMap` to printers.
  /// This is the extracted logic from the orderLinesMap loop in `enqueuePrintJobs`.
  Future<List<PrintJobResult>> enqueueKitchenJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  });
}