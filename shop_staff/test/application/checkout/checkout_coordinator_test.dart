import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/checkout/checkout_state.dart';
import 'package:shop_staff/application/checkout/models/checkout_draft.dart';
import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

void main() {
  group('CheckoutCoordinator', () {
    test(
      'orchestrates submit, payment completion, and print handoff',
      () async {
        final repository = _FakeBookkeepingOrderRepository();
        final local = _MemoryLocalOrders();
        final localOrders = LocalOrdersUseCases(local: local);
        final coordinator = _coordinator(repository, localOrders);

        coordinator.begin(_draft());
        final request = await coordinator.preparePayment(
          group: PaymentChannels.cash,
          code: 'cash',
          label: 'Cash',
        );

        expect(coordinator.state.stage, CheckoutStage.paymentReady);
        expect(coordinator.state.order?.orderId, 'order-1');
        expect(repository.submitCalls, 1);
        expect(local.record?.isPaid, isFalse);
        expect(local.record?.payMethod, 'cash');

        coordinator.paymentStarted(request);
        final updated = await coordinator.paymentCompleted(
          PaymentResult.success(messageKey: PaymentMessageKeys.cashSuccess),
        );

        expect(updated, isTrue);
        expect(local.record?.isPaid, isTrue);
        expect(coordinator.state.stage, CheckoutStage.printReady);
        expect(coordinator.state.printRequest?.orderId, 'order-1');
        expect(coordinator.state.printRequest?.printType, 'Label');
      },
    );

    test(
      'submits the menu order only once when payment choice changes',
      () async {
        final repository = _FakeBookkeepingOrderRepository();
        final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
        final coordinator = _coordinator(repository, localOrders);

        coordinator.begin(_draft());
        await coordinator.preparePayment(
          group: PaymentChannels.cash,
          code: 'cash',
          label: 'Cash',
        );
        await coordinator.preparePayment(
          group: PaymentChannels.qr,
          code: 'qr',
          label: 'QR',
        );

        expect(repository.submitCalls, 1);
        expect(
          coordinator.state.paymentRequest?.channelGroup,
          PaymentChannels.qr,
        );
      },
    );

    test('does not create print work for failed or unknown payments', () async {
      final repository = _FakeBookkeepingOrderRepository();
      final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
      final coordinator = _coordinator(repository, localOrders);

      coordinator.begin(_draft());
      final request = await coordinator.preparePayment(
        group: PaymentChannels.cash,
        code: 'cash',
        label: 'Cash',
      );
      coordinator.paymentStarted(request);
      await coordinator.paymentCompleted(PaymentResult.failure());
      expect(coordinator.state.stage, CheckoutStage.paymentFailed);
      expect(coordinator.state.printRequest, isNull);

      coordinator.paymentStarted(request);
      await coordinator.paymentCompleted(PaymentResult.indeterminate());
      expect(coordinator.state.stage, CheckoutStage.paymentIndeterminate);
      expect(coordinator.state.printRequest, isNull);
    });
  });
}

CheckoutCoordinator _coordinator(
  _FakeBookkeepingOrderRepository repository,
  LocalOrdersUseCases localOrders,
) {
  return CheckoutCoordinator(
    submitOrder: SubmitOrderUseCase(bookkeepingOrderRepository: repository),
    localOrders: localOrders,
    buildPaymentRequest: const BuildCheckoutPaymentRequestUseCase(),
    completePayment: CompleteCheckoutPaymentUseCase(localOrders: localOrders),
    readSettings: () => const AppSettingsSnapshot(
      basic: BasicSettings(
        paymentModes: PaymentModeSettings(
          cash: PaymentFlowMode.bookkeeping,
          qr: PaymentFlowMode.bookkeeping,
        ),
      ),
      printers: [
        PrinterSettings(
          name: 'Label',
          type: PrinterSettings.kitchenType,
          receipt: false,
          isOn: true,
        ),
      ],
    ),
  );
}

CheckoutDraft _draft() {
  return const CheckoutDraft(
    shop: ShopInfoModel(shopCode: 'shop-1', shopName: 'Shop', language: 'ja'),
    machineCode: 'machine-1',
    language: 'ja',
    takeout: false,
    items: [],
    orderNumber: 1,
    subtotal: 1000,
    discount: 0,
  );
}

class _FakeBookkeepingOrderRepository implements BookkeepingOrderRepository {
  int submitCalls = 0;

  @override
  Future<OrderSubmissionResult> submitOfflineOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
    String? shopCode,
  }) async {
    submitCalls += 1;
    return const OrderSubmissionResult(
      orderId: 'order-1',
      tax1: 0,
      baseTax1: 1000,
      tax2: 0,
      baseTax2: 0,
      total: 1000,
    );
  }

  @override
  Future<void> recordOrder(BookkeepingOrderRecordInput input) async {}
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
