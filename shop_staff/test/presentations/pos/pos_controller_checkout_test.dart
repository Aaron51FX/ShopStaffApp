import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';
import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';
import 'package:shop_staff/presentations/pos/controllers/pos_controller.dart';
import 'package:shop_staff/presentations/pos/order/state/pos_order_state.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';

void main() {
  test('checkout navigates only after offline order succeeds', () async {
    final repository = _PendingOrderRepository();
    final effects = <PosEffect>[];
    final controller = _controller(repository, effects);

    final checkout = controller.checkout();
    await Future<void>.delayed(Duration.zero);

    expect(repository.submitCalls, 1);
    expect(effects.whereType<PosNavigateEffect>(), isEmpty);

    repository.completeSuccess();
    await checkout;

    expect(effects.whereType<PosNavigateEffect>(), hasLength(1));
    expect(
      effects.whereType<PosNavigateEffect>().single.location,
      '/payment-selection',
    );
  });

  test('checkout stays on POS page when offline order fails', () async {
    final repository = _PendingOrderRepository();
    final effects = <PosEffect>[];
    final controller = _controller(repository, effects);

    final checkout = controller.checkout();
    await Future<void>.delayed(Duration.zero);
    repository.completeFailure();
    await checkout;

    expect(effects.whereType<PosNavigateEffect>(), isEmpty);
    expect(
      effects.whereType<PosToastEffect>().single.messageKey,
      PosToastKey.orderSubmitFailed,
    );
  });
}

PosController _controller(
  _PendingOrderRepository repository,
  List<PosEffect> effects,
) {
  final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
  final checkout = CheckoutCoordinator(
    submitOrder: SubmitOrderUseCase(bookkeepingOrderRepository: repository),
    localOrders: localOrders,
    buildPaymentRequest: const BuildCheckoutPaymentRequestUseCase(),
    completePayment: CompleteCheckoutPaymentUseCase(localOrders: localOrders),
    readSettings: () => null,
  );
  return PosController(
    readOrder: () => PosOrderState(cart: <CartItem>[_cartItem()]),
    readOrderController: () => throw UnimplementedError(),
    readShop: () =>
        ShopInfoModel(shopCode: 'shop-1', shopName: 'Shop', language: 'JP'),
    readMachineCode: () => 'machine-1',
    readLanguage: () => 'JP',
    readCheckout: () => checkout,
    emitEffect: effects.add,
  );
}

CartItem _cartItem() {
  return CartItem(
    id: 'line-1',
    product: const Product(
      id: 1,
      name: 'Noodles',
      categoryId: 'main',
      price: 1000,
      originalPrice: 1000,
      tax: 10,
      imageUrl: '',
    ),
    options: const <SelectedOption>[],
    quantity: 1,
  );
}

class _PendingOrderRepository implements BookkeepingOrderRepository {
  final Completer<OrderSubmissionResult> _submit =
      Completer<OrderSubmissionResult>();
  int submitCalls = 0;

  void completeSuccess() {
    _submit.complete(
      const OrderSubmissionResult(
        orderId: 'order-1',
        tax1: 0,
        baseTax1: 1000,
        tax2: 0,
        baseTax2: 0,
        total: 1000,
      ),
    );
  }

  void completeFailure() {
    _submit.completeError(StateError('OFFLINE_ORDER_FAILED'));
  }

  @override
  Future<OrderSubmissionResult> submitOfflineOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
    String? shopCode,
  }) {
    submitCalls += 1;
    return _submit.future;
  }

  @override
  Future<void> recordOrder(BookkeepingOrderRecordInput input) async {}

  @override
  Future<PrintInfoDocument> updateOrderState(
    OrderStateUpdateInput input,
  ) async => throw UnimplementedError();
}

class _MemoryLocalOrders extends LocalOrderLocalDataSource {
  LocalOrderRecord? record;

  @override
  Future<LocalOrderRecord?> getById(String orderId) async => record;

  @override
  Future<void> save(LocalOrderRecord record) async {
    this.record = record;
  }

  @override
  Future<void> updatePaid(String orderId, bool isPaid) async {
    record = record?.copyWith(isPaid: isPaid);
  }

  @override
  Future<void> updatePayMethod(
    String orderId,
    String payMethod, {
    bool isPaid = false,
  }) async {
    record = record?.copyWith(payMethod: payMethod, isPaid: isPaid);
  }

  @override
  Future<void> updatePaymentMode(
    String orderId,
    PaymentFlowMode paymentMode,
  ) async {
    record = record?.copyWith(paymentMode: paymentMode);
  }
}
