import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/checkout/models/checkout_payment_request.dart';
import 'package:shop_staff/application/checkout/checkout_providers.dart';
import 'package:shop_staff/application/checkout/checkout_state.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';
import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/payments/payment_flow_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import 'package:shop_staff/presentations/payment/providers/payment_providers.dart';

void main() {
  test(
    'payment provider starts after provider initialization completes',
    () async {
      final orchestrator = _PendingPaymentOrchestrator();
      final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
      final coordinator = CheckoutCoordinator(
        submitOrder: SubmitOrderUseCase(
          bookkeepingOrderRepository: _UnusedOrderRepository(),
        ),
        localOrders: localOrders,
        buildPaymentRequest: const BuildCheckoutPaymentRequestUseCase(),
        completePayment: CompleteCheckoutPaymentUseCase(
          localOrders: localOrders,
        ),
        readSettings: () => null,
      );
      final container = ProviderContainer(
        overrides: [
          checkoutCoordinatorProvider.overrideWith((ref) => coordinator),
          localOrdersUseCasesProvider.overrideWithValue(localOrders),
          paymentFlowUseCaseProvider.overrideWithValue(
            PaymentFlowUseCase(
              orchestrator: orchestrator,
              readSettingsSnapshot: () => null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen<PaymentSessionState>(
        paymentSessionControllerProvider(_request),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await Future<void>.delayed(Duration.zero);

      expect(orchestrator.startCalls, 1);
      expect(
        container.read(checkoutCoordinatorProvider).stage,
        CheckoutStage.paying,
      );
    },
  );

  test('disposing payment UI never cancels an active transaction', () async {
    final orchestrator = _PendingPaymentOrchestrator();
    final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
    final coordinator = CheckoutCoordinator(
      submitOrder: SubmitOrderUseCase(
        bookkeepingOrderRepository: _UnusedOrderRepository(),
      ),
      localOrders: localOrders,
      buildPaymentRequest: const BuildCheckoutPaymentRequestUseCase(),
      completePayment: CompleteCheckoutPaymentUseCase(localOrders: localOrders),
      readSettings: () => null,
    );
    final container = ProviderContainer(
      overrides: [
        checkoutCoordinatorProvider.overrideWith((ref) => coordinator),
        localOrdersUseCasesProvider.overrideWithValue(localOrders),
        paymentFlowUseCaseProvider.overrideWithValue(
          PaymentFlowUseCase(
            orchestrator: orchestrator,
            readSettingsSnapshot: () => null,
          ),
        ),
      ],
    );
    final subscription = container.listen<PaymentSessionState>(
      paymentSessionControllerProvider(_request),
      (_, _) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);
    subscription.close();
    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(orchestrator.cancelCalls, 0);
  });
}

const _request = CheckoutPaymentRequest(
  order: OrderSubmissionResult(
    orderId: 'order-1',
    tax1: 0,
    baseTax1: 0,
    tax2: 0,
    baseTax2: 0,
    total: 100,
  ),
  channelGroup: PaymentChannels.cash,
  channelCode: 'cash',
  paymentMode: PaymentFlowMode.bookkeeping,
);

class _PendingPaymentOrchestrator implements PaymentOrchestrator {
  int startCalls = 0;
  int cancelCalls = 0;
  final Completer<PaymentResult> _result = Completer<PaymentResult>();

  @override
  PaymentSessionHandle start(PaymentContext context) {
    startCalls += 1;
    return PaymentSessionHandle(
      sessionId: 'session-1',
      initialStatus: const PaymentStatus(type: PaymentStatusType.pending),
      statuses: const Stream<PaymentStatus>.empty(),
      result: _result.future,
      cancel: () async {},
    );
  }

  @override
  Future<void> cancel(String sessionId) async {
    cancelCalls += 1;
  }

  @override
  Future<void> finalize(String sessionId) async {}

  @override
  Future<void> reconcile(String sessionId) async {}

  @override
  Future<PaymentResult> result(String sessionId) => _result.future;

  @override
  Stream<PaymentStatus> watch(String sessionId) =>
      const Stream<PaymentStatus>.empty();
}

class _UnusedOrderRepository implements BookkeepingOrderRepository {
  @override
  Future<OrderSubmissionResult> submitOfflineOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
    String? shopCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordOrder(BookkeepingOrderRecordInput input) {
    throw UnimplementedError();
  }

  @override
  Future<PrintInfoDocument> updateOrderState(OrderStateUpdateInput input) {
    throw UnimplementedError();
  }
}

class _MemoryLocalOrders extends LocalOrderLocalDataSource {
  @override
  Future<List<LocalOrderRecord>> loadAll() async => const [];

  @override
  Future<void> save(LocalOrderRecord record) async {}
}
