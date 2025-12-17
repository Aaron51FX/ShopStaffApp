
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/repositories/print_repository.dart';

class PrintRepositoryImpl implements PrintRepository {
  final PosRemoteDataSource _remote;
  PrintRepositoryImpl(this._remote);

  @override
  Future<PrintInfoDocument> printInfo({
    required String orderId, 
    required String machineCode, 
    required String payAmount, 
    required String rprintType}) async {
      final payload = {
        'orderId': orderId,
        'machineCode': machineCode,
        'payAmount': payAmount,
        'rprintType': rprintType,
      };
      final response = await _remote.printInfo(payload);
      return PrintInfoDocument.fromJson(response);
  }
}