
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
    required String printType}) async {
      final payload = {
        'orderId': orderId,
        'machineCode': machineCode,
        'payAmount': payAmount,
        'printType': printType,
      };
      final response = await _remote.printInfo(payload);
      // Backend wraps payload in { msg, code, data }, unwrap to the actual print info map.
      final data = response is Map<String, dynamic> ? response['data'] : null;
      if (data is! Map<String, dynamic>) {
        throw StateError('打印信息解析失败: data 字段缺失或格式错误');
      }
      return PrintInfoDocument.fromJson(data);
  }
}