import 'package:shop_staff/domain/entities/receipt_document.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

abstract class NativeReceiptPrinter {
  Future<void> printReceipt({
    required ReceiptDocument document,
    required PrinterSettings printer,
  });
}
