import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/application/pos/usecases/suspended_orders_usecases.dart';
import 'package:shop_staff/data/datasources/local/suspended_order_local_data_source.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/presentations/pos/order/controllers/pos_order_controller.dart';

void main() {
  group('PosOrderController', () {
    late PosOrderController controller;

    setUp(() {
      controller = PosOrderController(
        initialMode: 'dine_in',
        suspendedOrders: SuspendedOrdersUseCases(
          local: _MemorySuspendedOrders(),
        ),
      );
    });

    test('combines identical products and calculates totals', () {
      controller.addProduct(_product);
      controller.addProduct(_product);
      controller.applyDiscount(50);

      expect(controller.state.cart, hasLength(1));
      expect(controller.state.cart.single.quantity, 2);
      expect(controller.state.subtotal, 600);
      expect(controller.state.total, 550);
    });

    test('confirmed checkout clears the editable order', () {
      controller.addProduct(_product);
      controller.applyDiscount(50);

      controller.completeCheckout(
        order: const OrderSubmissionResult(
          orderId: 'order-1',
          tax1: 0,
          baseTax1: 0,
          tax2: 0,
          baseTax2: 0,
          total: 250,
        ),
        orderNumber: 1001,
      );

      expect(controller.state.cart, isEmpty);
      expect(controller.state.discount, 0);
      expect(controller.state.orderNumber, 1001);
      expect(controller.state.lastOrderResult?.orderId, 'order-1');
    });
  });
}

const _product = Product(
  id: 1,
  name: 'Coffee',
  categoryId: 'drink',
  price: 300,
  originalPrice: 300,
  tax: 10,
  imageUrl: '',
);

class _MemorySuspendedOrders extends SuspendedOrderLocalDataSource {
  final List<SuspendedOrder> orders = [];

  @override
  Future<List<SuspendedOrder>> loadAll() async => List.of(orders);

  @override
  Future<void> save(SuspendedOrder order) async => orders.add(order);

  @override
  Future<void> delete(String id) async {
    orders.removeWhere((order) => order.id == id);
  }
}
