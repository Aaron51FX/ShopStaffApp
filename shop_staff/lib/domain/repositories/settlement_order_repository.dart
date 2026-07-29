import '../entities/settlement_order.dart';

abstract class SettlementOrderRepository {
  Future<SettlementOrder> fetchOrder({
    required String orderKey,
    required String language,
    required String machineCode,
  });

  Future<int> confirmOrderTotal(String orderId);
}
