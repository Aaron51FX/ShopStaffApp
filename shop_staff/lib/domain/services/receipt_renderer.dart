import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

/// Renders receipt/label layouts into printable widgets (ATempWidget).
abstract class ReceiptRenderer {

  ATempWidget buildHReceipt({
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
  });

  ATempWidget buildReceipt({
    required String shopName,
    required String shopIcon,
    required String address,
    required String orderSnCode,
    required String telephone,
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
    required bool isTakeOut,
    required String payPrice,
    required String change,
    required String paymentMethod,
    required String tax1,
    required String baseTax1,
    required String tax2,
    required String baseTax2,
    required String total,
    
    String discount = '0',
    String voucherAmount = '0',
    String cardNumber = '',
  });

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
