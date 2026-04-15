import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';

void main() {
  test(
    'submit order always prepares offline order totals before payment choice',
    () async {
      final repository = _FakeBookkeepingOrderRepository();
      final useCase = SubmitOrderUseCase(
        bookkeepingOrderRepository: repository,
      );

      final output = await useCase.execute(
        SubmitOrderInput(
          items: [
            CartItem(
              id: 'L1',
              product: Product(
                id: 1,
                name: 'Curry Rice',
                categoryId: 'main',
                price: 1200,
                originalPrice: 1200,
                tax: 10,
                imageUrl: '',
                optionGroups: const <OptionGroupEntity>[],
              ),
              quantity: 1,
              options: const [],
            ),
            CartItem(
              id: 'L2',
              product: Product(
                id: 2,
                name: 'Drink',
                categoryId: 'drink',
                price: 300,
                originalPrice: 300,
                tax: 8,
                imageUrl: '',
                optionGroups: const <OptionGroupEntity>[],
              ),
              quantity: 1,
              options: const [],
            ),
          ],
          machineCode: 'M001',
          language: 'ja',
          takeout: false,
          discount: 100,
          shopCode: 'SHOP-1',
        ),
      );

      expect(repository.submitCalls, hasLength(1));
      expect(repository.submitCalls.single.total, 1400);
      expect(repository.submitCalls.single.machineCode, 'M001');
      expect(output.total, 1400);
      expect(output.order.orderId, 'OFFLINE-001');
    },
  );
}

class _FakeBookkeepingOrderRepository implements BookkeepingOrderRepository {
  final List<_SubmitCall> submitCalls = <_SubmitCall>[];

  @override
  Future<OrderSubmissionResult> submitOfflineOrder({
    required List<CartItem> items,
    required String machineCode,
    required String language,
    required bool takeout,
    required double total,
    String? shopCode,
  }) async {
    submitCalls.add(
      _SubmitCall(
        machineCode: machineCode,
        language: language,
        takeout: takeout,
        total: total,
        shopCode: shopCode,
      ),
    );

    return const OrderSubmissionResult(
      orderId: 'OFFLINE-001',
      tax1: 109,
      baseTax1: 1091,
      tax2: 22,
      baseTax2: 278,
      total: 1400,
    );
  }

  @override
  Future<void> recordOrder(BookkeepingOrderRecordInput input) async {}
}

class _SubmitCall {
  const _SubmitCall({
    required this.machineCode,
    required this.language,
    required this.takeout,
    required this.total,
    required this.shopCode,
  });

  final String machineCode;
  final String language;
  final bool takeout;
  final double total;
  final String? shopCode;
}
