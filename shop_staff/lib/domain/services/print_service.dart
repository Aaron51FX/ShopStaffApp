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
}