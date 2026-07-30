import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/services/order_state_payment_backend_gateway.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';

void main() {
  test('bookkeeping QR updates order state with PWA pay channel', () async {
    final repository = _FakeBookkeepingOrderRepository();
    final gateway = OrderStatePaymentBackendGateway(
      bookkeepingOrders: repository,
    );

    final document = await gateway.confirmPayment(
      _context(group: PaymentChannels.qr),
      const <String, dynamic>{},
    );

    expect(document, repository.document);
    expect(repository.updateCalls, hasLength(1));
    final input = repository.updateCalls.single;
    expect(input.payChannel, 'PayPay');
    expect(input.payPrice, isNull);
    expect(input.discount, 100);
    expect(input.finalTotal, 900);
  });

  test('real Star cash updates after payment with accepted amount', () async {
    final repository = _FakeBookkeepingOrderRepository();
    final gateway = OrderStatePaymentBackendGateway(
      bookkeepingOrders: repository,
    );

    await gateway.confirmPayment(
      _context(
        group: PaymentChannels.cash,
        mode: PaymentFlowMode.real,
        requiresOrderStateUpdate: true,
      ),
      const <String, dynamic>{
        'receipt': <String, dynamic>{'acceptedAmount': 1000},
      },
    );

    expect(repository.updateCalls.single.payChannel, 'Cash');
    expect(repository.updateCalls.single.payPrice, 1000);
  });

  test('actual payment without update flag keeps current flow', () async {
    final repository = _FakeBookkeepingOrderRepository();
    final gateway = OrderStatePaymentBackendGateway(
      bookkeepingOrders: repository,
    );

    final document = await gateway.confirmPayment(
      _context(group: PaymentChannels.card, mode: PaymentFlowMode.real),
      const <String, dynamic>{},
    );

    expect(document, isNull);
    expect(repository.updateCalls, isEmpty);
  });
}

PaymentContext _context({
  required String group,
  PaymentFlowMode mode = PaymentFlowMode.bookkeeping,
  bool requiresOrderStateUpdate = false,
}) {
  return PaymentContext(
    order: const OrderSubmissionResult(
      orderId: 'order-1',
      tax1: 0,
      baseTax1: 1000,
      tax2: 0,
      baseTax2: 0,
      total: 1000,
    ),
    channel: PaymentChannel(group: group, code: group),
    mode: mode,
    metadata: <String, dynamic>{
      'machineCode': 'machine-1',
      'discount': 100,
      'finalTotal': 900,
      if (requiresOrderStateUpdate) 'requiresOrderStateUpdate': true,
    },
  );
}

class _FakeBookkeepingOrderRepository implements BookkeepingOrderRepository {
  final document = const PrintInfoDocument(orderId: 123, price: 900);
  final List<OrderStateUpdateInput> updateCalls = <OrderStateUpdateInput>[];

  @override
  Future<void> recordOrder(BookkeepingOrderRecordInput input) async {}

  @override
  Future<PrintInfoDocument> updateOrderState(
    OrderStateUpdateInput input,
  ) async {
    updateCalls.add(input);
    return document;
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
    throw UnimplementedError();
  }
}
