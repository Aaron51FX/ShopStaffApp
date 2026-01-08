import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

/// Renders receipt/label layouts into printable widgets (ATempWidget).
abstract class ReceiptRenderer {

  ATempWidget buildContinuousReceipt({
    required PrintTicketInfo info,
    required List<Map<String, dynamic>> items,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
    bool isCenterPrint = false,
  });

  ATempWidget buildSingleReceipt({
    required PrintTicketInfo info,
    required Map<String, dynamic> item,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
  });

  /// For label printers: head ticket (takeout tag) when needed.
  ATempWidget? buildLabelHead({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  });

  /// For label printers: one widget per line (qty already expanded externally).
  List<ATempWidget> buildLabels({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  });
}
