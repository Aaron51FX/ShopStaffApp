import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/payment_backend_gateway.dart';
import 'package:shop_staff/data/services/payment_flows/bookkeeping_payment_flow.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

void main() {
  test(
    'bookkeeping flow reports order and succeeds without terminal flow',
    () async {
      final backend = _FakePaymentBackendGateway();
      final flow = BookkeepingPaymentFlow(backendGateway: backend);

      final run = flow.start(
        PaymentContext(
          order: const OrderSubmissionResult(
            orderId: 'ORD-BOOK-1',
            tax1: 80,
            baseTax1: 800,
            tax2: 0,
            baseTax2: 0,
            total: 880,
          ),
          channel: const PaymentChannel(
            group: PaymentChannels.qr,
            code: 'PayPay',
            displayName: 'PayPay',
          ),
          mode: PaymentFlowMode.bookkeeping,
          metadata: <String, dynamic>{
            'machineCode': 'M001',
            'takeout': false,
            'cartItems': <CartItem>[
              CartItem(
                id: 'L1',
                product: Product(
                  id: 1001,
                  name: 'Fried Rice',
                  categoryId: '10',
                  price: 880,
                  originalPrice: 880,
                  tax: 10,
                  imageUrl: '',
                  optionGroups: const <OptionGroupEntity>[],
                ),
                quantity: 1,
                options: const <SelectedOption>[],
              ),
            ],
          },
        ),
      );

      final result = await run.result;

      expect(result.status, PaymentStatusType.success);
      expect(backend.confirmedPayloads, hasLength(1));
      expect(backend.confirmedPayloads.single['channelCode'], 'PayPay');
    },
  );
}

class _FakePaymentBackendGateway implements PaymentBackendGateway {
  final List<Map<String, dynamic>> confirmedPayloads = <Map<String, dynamic>>[];

  @override
  Future<void> confirmPayment(
    PaymentContext context,
    Map<String, dynamic> payload,
  ) async {
    confirmedPayloads.add(payload);
  }
}
