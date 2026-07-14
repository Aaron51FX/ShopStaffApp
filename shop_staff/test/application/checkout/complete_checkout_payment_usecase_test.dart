import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';

void main() {
  group('CompleteCheckoutPaymentUseCase', () {
    test('marks an unpaid local order as paid', () async {
      final local = _FakeLocalOrderDataSource(_order(isPaid: false));
      final useCase = CompleteCheckoutPaymentUseCase(
        localOrders: LocalOrdersUseCases(local: local),
      );

      await useCase.execute('order-1');

      expect(local.order?.isPaid, isTrue);
      expect(local.updatePaidCalls, 1);
    });

    test('does not write an already-paid order again', () async {
      final local = _FakeLocalOrderDataSource(_order(isPaid: true));
      final useCase = CompleteCheckoutPaymentUseCase(
        localOrders: LocalOrdersUseCases(local: local),
      );

      await useCase.execute('order-1');

      expect(local.updatePaidCalls, 0);
    });

    test('fails explicitly when the local order is missing', () async {
      final local = _FakeLocalOrderDataSource(null);
      final useCase = CompleteCheckoutPaymentUseCase(
        localOrders: LocalOrdersUseCases(local: local),
      );

      expect(
        () => useCase.execute('missing-order'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'LOCAL_ORDER_NOT_FOUND',
          ),
        ),
      );
    });
  });
}

LocalOrderRecord _order({required bool isPaid}) {
  return LocalOrderRecord(
    orderId: 'order-1',
    createdAt: DateTime(2026),
    isPaid: isPaid,
    items: const [],
    machineCode: 'machine-1',
    language: 'ja',
    takeout: false,
    discount: 0,
    clientTotal: 1000,
    orderResult: const OrderSubmissionResult(
      orderId: 'order-1',
      tax1: 0,
      baseTax1: 0,
      tax2: 0,
      baseTax2: 0,
      total: 1000,
    ),
  );
}

class _FakeLocalOrderDataSource extends LocalOrderLocalDataSource {
  _FakeLocalOrderDataSource(this.order);

  LocalOrderRecord? order;
  int updatePaidCalls = 0;

  @override
  Future<LocalOrderRecord?> getById(String orderId) async => order;

  @override
  Future<void> updatePaid(String orderId, bool isPaid) async {
    updatePaidCalls += 1;
    order = order?.copyWith(isPaid: isPaid);
  }
}
