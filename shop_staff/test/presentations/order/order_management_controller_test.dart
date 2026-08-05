import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/domain/repositories/order_management_repository.dart';
import 'package:shop_staff/presentations/order/controllers/order_management_controller.dart';

void main() {
  group('OrderManagementController', () {
    test('loads paid orders for today by default', () async {
      final repository = _FakeOrderManagementRepository();
      final controller = OrderManagementController(
        repository: repository,
        readShopCode: () => 'SHOP-1',
      );

      await controller.load();

      expect(controller.state.orders, [_paidOrder]);
      expect(repository.queries, hasLength(1));
      final query = repository.queries.single;
      expect(query.shopCode, 'SHOP-1');
      expect(query.status, ManagedOrderStatus.paid);
      expect(query.startDate, query.endDate);
      expect(query.startDate.hour, 0);
    });

    test('changing status reloads with the selected backend state', () async {
      final repository = _FakeOrderManagementRepository();
      final controller = OrderManagementController(
        repository: repository,
        readShopCode: () => 'SHOP-1',
      );

      await controller.setStatus(ManagedOrderStatus.canceled);

      expect(repository.queries.single.status, ManagedOrderStatus.canceled);
      expect(repository.queries.single.status.apiValue, 2);
    });

    test(
      'selecting loads backend detail and mark paid refreshes list',
      () async {
        final repository = _FakeOrderManagementRepository();
        final controller = OrderManagementController(
          repository: repository,
          readShopCode: () => 'SHOP-1',
        );

        await controller.selectOrder(_unpaidOrder);
        expect(controller.state.detail?.order, _unpaidOrder);

        await controller.markPaid('Cash');

        expect(repository.markPaidCalls, [('UNPAID-1', 'Cash')]);
        expect(repository.queries, hasLength(1));
        expect(controller.state.selectedOrderId, isNull);
      },
    );

    test('paid online cancellation uses repository paid flow', () async {
      final repository = _FakeOrderManagementRepository();
      final controller = OrderManagementController(
        repository: repository,
        readShopCode: () => 'SHOP-1',
      );
      final onlineOrder = _paidOrder.copyWith(payChannel: 'PayPay');
      await controller.selectOrder(onlineOrder);

      await controller.cancelSelected();

      expect(repository.canceledPaid, [onlineOrder]);
      expect(repository.canceledUnpaid, isEmpty);
    });
  });

  test('managed detail can repopulate the POS cart', () {
    final detail = ManagedOrderDetail(
      order: _paidOrder,
      lines: const [
        ManagedOrderLine(
          productId: 12,
          categoryId: 'FOOD',
          name: 'Ramen',
          quantity: 2,
          price: 900,
          tax: 10,
          options: [
            ManagedOrderOption(
              groupName: 'Size',
              name: 'Large',
              price: 100,
              quantity: 1,
              code: 'L',
            ),
          ],
        ),
      ],
    );

    final local = detail.toLocalOrder(machineCode: 'M-1', language: 'JP');

    expect(local.orderId, _paidOrder.orderId);
    expect(local.items.single.product.id, 12);
    expect(local.items.single.quantity, 2);
    expect(local.items.single.options.single.optionCode, 'L');
  });
}

const _paidOrder = ManagedOrder(
  orderId: 'PAID-1',
  status: ManagedOrderStatus.paid,
  createdAt: null,
  price: 1000,
  payChannel: 'Cash',
  payBizId: 'PAY-1',
);

const _unpaidOrder = ManagedOrder(
  orderId: 'UNPAID-1',
  status: ManagedOrderStatus.unpaid,
  createdAt: null,
  price: 1000,
);

class _FakeOrderManagementRepository implements OrderManagementRepository {
  final queries = <ManagedOrderQuery>[];
  final markPaidCalls = <(String, String)>[];
  final canceledPaid = <ManagedOrder>[];
  final canceledUnpaid = <String>[];

  @override
  Future<ManagedOrderPage> fetchOrders(ManagedOrderQuery query) async {
    queries.add(query);
    return const ManagedOrderPage(orders: [_paidOrder], hasMore: false);
  }

  @override
  Future<ManagedOrderDetail> fetchOrderDetail(ManagedOrder order) async {
    return ManagedOrderDetail(order: order, lines: const []);
  }

  @override
  Future<void> markPaid({
    required String orderId,
    required String payChannel,
  }) async {
    markPaidCalls.add((orderId, payChannel));
  }

  @override
  Future<void> cancelPaid(ManagedOrder order) async {
    canceledPaid.add(order);
  }

  @override
  Future<void> cancelUnpaid(String orderId) async {
    canceledUnpaid.add(orderId);
  }
}
