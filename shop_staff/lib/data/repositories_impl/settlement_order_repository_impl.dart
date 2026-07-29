import '../../core/network/api_exception.dart';
import '../../domain/entities/settlement_order.dart';
import '../../domain/repositories/settlement_order_repository.dart';
import '../datasources/remote/pos_remote_datasource.dart';

class SettlementOrderRepositoryImpl implements SettlementOrderRepository {
  const SettlementOrderRepositoryImpl(this._remote);

  final PosRemoteDataSource _remote;

  @override
  Future<SettlementOrder> fetchOrder({
    required String orderKey,
    required String language,
    required String machineCode,
  }) async {
    final raw = await _remote.fetchSettlementOrder(
      orderKey: orderKey,
      language: language,
      machineCode: machineCode,
    );
    if (raw is! Map) {
      throw const FormatException('Invalid settlement order response');
    }
    final response = Map<String, dynamic>.from(raw);
    final code = _readCode(response['code']);
    final data = response['data'];
    if (code != 200 || data is! Map) {
      throw ApiException(
        (response['msg'] ?? 'Failed to fetch settlement order').toString(),
        statusCode: code,
        data: response,
      );
    }
    return SettlementOrder.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<int> confirmOrderTotal(String orderId) async {
    final raw = await _remote.confirmSettlementOrder(orderId);
    if (raw is! Map) {
      throw const FormatException('Invalid settlement confirmation response');
    }
    final response = Map<String, dynamic>.from(raw);
    final code = _readCode(response['code']);
    final total = _readCode(response['data']);
    if (code != 200 || total == null) {
      throw ApiException(
        (response['msg'] ?? 'Failed to confirm settlement order').toString(),
        statusCode: code,
        data: response,
      );
    }
    return total;
  }
}

int? _readCode(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
