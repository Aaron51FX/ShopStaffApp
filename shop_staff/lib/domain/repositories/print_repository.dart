
import 'package:shop_staff/data/models/print_info.dart';

abstract class PrintRepository {
  Future<PrintInfoDocument> printInfo({
    required String orderId, 
    required String machineCode, 
    required String payAmount, 
    required String rprintType});
}