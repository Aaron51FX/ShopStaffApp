import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

/// Application-level print input, independent from any print dialog.
class PrintJobRequest {
  const PrintJobRequest({
    required this.machineCode,
    required this.printers,
    this.orderId,
    this.payAmount,
    this.printType,
    this.document,
    this.receiptOnly = false,
  });

  final String machineCode;
  final List<PrinterSettings> printers;
  final String? orderId;
  final String? payAmount;
  final String? printType;
  final PrintInfoDocument? document;
  final bool receiptOnly;

  bool get hasDocument => document != null;
}
