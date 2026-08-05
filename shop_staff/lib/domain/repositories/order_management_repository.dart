import '../entities/managed_order.dart';

abstract class OrderManagementRepository {
  Future<ManagedOrderPage> fetchOrders(ManagedOrderQuery query);

  Future<ManagedOrderDetail> fetchOrderDetail(ManagedOrder order);

  Future<void> markPaid({required String orderId, required String payChannel});

  Future<void> cancelUnpaid(String orderId);

  Future<void> cancelPaid(ManagedOrder order);
}
