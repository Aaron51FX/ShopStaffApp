import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';

final completeCheckoutPaymentUseCaseProvider =
    Provider<CompleteCheckoutPaymentUseCase>((ref) {
      return CompleteCheckoutPaymentUseCase(
        localOrders: ref.watch(localOrdersUseCasesProvider),
      );
    });

class CompleteCheckoutPaymentUseCase {
  const CompleteCheckoutPaymentUseCase({
    required LocalOrdersUseCases localOrders,
  }) : _localOrders = localOrders;

  final LocalOrdersUseCases _localOrders;

  Future<void> execute(String orderId) async {
    final order = await _localOrders.getById(orderId);
    if (order == null) {
      throw StateError('LOCAL_ORDER_NOT_FOUND');
    }
    if (order.isPaid) return;
    await _localOrders.updatePaid(orderId, true);
  }
}
