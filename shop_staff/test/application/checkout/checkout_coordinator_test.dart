import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/checkout/checkout_state.dart';
import 'package:shop_staff/application/checkout/models/checkout_draft.dart';
import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/data/models/print_info.dart';
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

        await coordinator.beginNewOrder(_draft());
        expect(repository.submitCalls, 1);
        expect(coordinator.state.stage, CheckoutStage.selectingPayment);
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
        const printDocument = PrintInfoDocument(
          orderId: 123,
          shopName: 'Test Shop',
        );
        final updated = await coordinator.paymentCompleted(
          PaymentResult.success(
            messageKey: PaymentMessageKeys.cashSuccess,
            payload: const <String, dynamic>{'printDocument': printDocument},
          ),
        );

        expect(updated, isTrue);
        expect(local.record?.isPaid, isTrue);
        expect(coordinator.state.stage, CheckoutStage.printReady);
        expect(coordinator.state.printRequest?.orderId, 'order-1');
        expect(coordinator.state.printRequest?.printType, 'Label');
        expect(coordinator.state.printRequest?.logoImageBase64, 'AQIDBA==');
        expect(coordinator.state.printRequest?.document, printDocument);
      },
    );

    test(
      'submits the menu order only once when payment choice changes',
      () async {
        final repository = _FakeBookkeepingOrderRepository();
        final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
        final coordinator = _coordinator(repository, localOrders);

        await coordinator.beginNewOrder(_draft());
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

    test(
      'uses an existing settlement order without submitting it again',
      () async {
        final repository = _FakeBookkeepingOrderRepository();
        final local = _MemoryLocalOrders();
        final localOrders = LocalOrdersUseCases(local: local);
        final coordinator = _coordinator(repository, localOrders);
        const existingOrder = OrderSubmissionResult(
          orderId: 'settlement-order-1',
          tax1: 80,
          baseTax1: 0,
          tax2: 0,
          baseTax2: 0,
          total: 1000,
        );

        await coordinator.beginExistingOrder(
          draft: _draft(isSettlement: true),
          order: existingOrder,
        );
        final request = await coordinator.preparePayment(
          group: PaymentChannels.cash,
          code: 'cash',
          label: 'Cash',
        );

        expect(repository.submitCalls, 0);
        expect(request.order.orderId, 'settlement-order-1');
        expect(request.order.total, 1000);
        expect(local.record?.orderId, 'settlement-order-1');
        expect(local.record?.isPaid, isFalse);

        coordinator.paymentStarted(request);
        await coordinator.paymentCompleted(
          PaymentResult.success(messageKey: PaymentMessageKeys.cashSuccess),
        );

        expect(local.record?.isPaid, isTrue);
        expect(coordinator.state.stage, CheckoutStage.printReady);
        expect(coordinator.state.printRequest?.orderId, 'settlement-order-1');
        expect(coordinator.state.printRequest?.payAmount, '1000');
        expect(coordinator.state.printRequest?.printType, '');
        expect(coordinator.state.printRequest?.receiptOnly, isTrue);
      },
    );

    test('marks bookkeeping receipt payment methods as offline', () async {
      for (final scenario in <(String, String)>[
        (PaymentChannels.cash, '現金支払（オフライン）'),
        (PaymentChannels.card, 'クレジットカード（オフライン）'),
        (PaymentChannels.qr, 'QR Code（オフライン）'),
      ]) {
        final repository = _FakeBookkeepingOrderRepository();
        final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
        final coordinator = _coordinator(repository, localOrders);

        await coordinator.beginNewOrder(_draft());
        final request = await coordinator.preparePayment(
          group: scenario.$1,
          code: scenario.$1,
          label: scenario.$1,
        );
        coordinator.paymentStarted(request);
        await coordinator.paymentCompleted(
          PaymentResult.success(messageKey: PaymentMessageKeys.statusSuccess),
        );

        expect(
          coordinator.state.printRequest?.paymentMethodOverride,
          scenario.$2,
        );
      }
    });

    test(
      'bookkeeping payment defers order state update to payment flow',
      () async {
        final repository = _FakeBookkeepingOrderRepository();
        final coordinator = _coordinator(
          repository,
          LocalOrdersUseCases(local: _MemoryLocalOrders()),
        );

        await coordinator.beginNewOrder(_draft());
        final request = await coordinator.preparePayment(
          group: PaymentChannels.qr,
          code: 'qr',
          label: 'QR',
        );

        expect(repository.recordCalls, isEmpty);
        expect(request.metadata?['requiresOrderStateUpdate'], isTrue);

        final secondRequest = await coordinator.preparePayment(
          group: PaymentChannels.card,
          code: 'card',
          label: 'Card',
        );
        expect(repository.recordCalls, isEmpty);
        expect(secondRequest.metadata?['requiresOrderStateUpdate'], isTrue);
      },
    );

    test(
      'real Star cash defers order state update until cash finalization',
      () async {
        final repository = _FakeBookkeepingOrderRepository();
        final coordinator = _coordinator(
          repository,
          LocalOrdersUseCases(local: _MemoryLocalOrders()),
          settings: const AppSettingsSnapshot(
            basic: BasicSettings(
              cashMachine: CashMachineSettings(
                enabled: true,
                brand: CashMachineBrand.star,
              ),
              paymentModes: PaymentModeSettings(cash: PaymentFlowMode.real),
            ),
          ),
        );

        await coordinator.beginNewOrder(_draft());
        final request = await coordinator.preparePayment(
          group: PaymentChannels.cash,
          code: 'cash',
          label: 'Cash',
        );

        expect(repository.recordCalls, isEmpty);
        expect(request.metadata?['requiresOrderStateUpdate'], isTrue);
      },
    );

    test('real Glory cash keeps current flow without staff order', () async {
      final repository = _FakeBookkeepingOrderRepository();
      final coordinator = _coordinator(
        repository,
        LocalOrdersUseCases(local: _MemoryLocalOrders()),
        settings: const AppSettingsSnapshot(
          basic: BasicSettings(
            cashMachine: CashMachineSettings(
              enabled: true,
              brand: CashMachineBrand.glory,
            ),
            paymentModes: PaymentModeSettings(cash: PaymentFlowMode.real),
          ),
        ),
      );

      await coordinator.beginNewOrder(_draft());
      final request = await coordinator.preparePayment(
        group: PaymentChannels.cash,
        code: 'cash',
        label: 'Cash',
      );

      expect(repository.recordCalls, isEmpty);
      expect(request.metadata?['requiresOrderStateUpdate'], isNull);
    });

    test('real card and QR keep current flow without staff order', () async {
      for (final group in <String>[PaymentChannels.card, PaymentChannels.qr]) {
        final repository = _FakeBookkeepingOrderRepository();
        final coordinator = _coordinator(
          repository,
          LocalOrdersUseCases(local: _MemoryLocalOrders()),
          settings: const AppSettingsSnapshot(
            basic: BasicSettings(
              paymentModes: PaymentModeSettings(
                card: PaymentFlowMode.real,
                qr: PaymentFlowMode.real,
              ),
            ),
            posTerminal: PosTerminalSettings(
              posIp: '192.0.2.10',
              posPort: 1234,
            ),
          ),
        );

        await coordinator.beginNewOrder(_draft());
        final request = await coordinator.preparePayment(
          group: group,
          code: group,
          label: group,
        );

        expect(repository.recordCalls, isEmpty);
        expect(request.metadata?['requiresOrderStateUpdate'], isNull);
      }
    });

    test('does not create print work for failed or unknown payments', () async {
      final repository = _FakeBookkeepingOrderRepository();
      final localOrders = LocalOrdersUseCases(local: _MemoryLocalOrders());
      final coordinator = _coordinator(repository, localOrders);

      await coordinator.beginNewOrder(_draft());
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
  LocalOrdersUseCases localOrders, {
  AppSettingsSnapshot? settings,
}) {
  return CheckoutCoordinator(
    submitOrder: SubmitOrderUseCase(bookkeepingOrderRepository: repository),
    localOrders: localOrders,
    buildPaymentRequest: const BuildCheckoutPaymentRequestUseCase(),
    completePayment: CompleteCheckoutPaymentUseCase(localOrders: localOrders),
    readSettings: () =>
        settings ??
        const AppSettingsSnapshot(
          basic: BasicSettings(
            paymentModes: PaymentModeSettings(
              cash: PaymentFlowMode.bookkeeping,
              card: PaymentFlowMode.bookkeeping,
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

CheckoutDraft _draft({bool isSettlement = false}) {
  return CheckoutDraft(
    shop: ShopInfoModel(
      shopCode: 'shop-1',
      shopName: 'Shop',
      language: 'ja',
      logoImageBase64: 'AQIDBA==',
    ),
    machineCode: 'machine-1',
    language: 'ja',
    takeout: false,
    items: [],
    orderNumber: 1,
    subtotal: 1000,
    discount: 0,
    isSettlement: isSettlement,
  );
}

class _FakeBookkeepingOrderRepository implements BookkeepingOrderRepository {
  int submitCalls = 0;
  final List<BookkeepingOrderRecordInput> recordCalls =
      <BookkeepingOrderRecordInput>[];

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
  Future<void> recordOrder(BookkeepingOrderRecordInput input) async {
    recordCalls.add(input);
  }

  @override
  Future<PrintInfoDocument> updateOrderState(
    OrderStateUpdateInput input,
  ) async => const PrintInfoDocument();
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
