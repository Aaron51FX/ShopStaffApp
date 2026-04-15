import 'package:logging/logging.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';

import 'payment_backend_gateway.dart';

class BookkeepingPaymentBackendGateway implements PaymentBackendGateway {
  BookkeepingPaymentBackendGateway({
    required BookkeepingOrderRepository bookkeepingOrders,
    Logger? logger,
  }) : _bookkeepingOrders = bookkeepingOrders,
       _logger = logger ?? Logger('BookkeepingPaymentBackendGateway');

  final BookkeepingOrderRepository _bookkeepingOrders;
  final Logger _logger;

  @override
  Future<void> confirmPayment(
    PaymentContext context,
    Map<String, dynamic> payload,
  ) async {
    if (context.mode != PaymentFlowMode.bookkeeping) {
      _logger.info(
        'Skip bookkeeping order record for real payment order=${context.order.orderId}',
      );
      return;
    }

    final metadata = context.metadata ?? const <String, dynamic>{};
    final rawItems = metadata['cartItems'];
    if (rawItems is! List<CartItem>) {
      throw StateError('BOOKKEEPING_CART_ITEMS_MISSING');
    }

    final machineCode = (metadata['machineCode'] as String? ?? '').trim();
    if (machineCode.isEmpty) {
      throw StateError('BOOKKEEPING_MACHINE_CODE_MISSING');
    }

    final orderSnCode = metadata['orderSnCode'] as String?;
    final takeout = metadata['takeout'] == true;
    final channelDisplayName =
        (payload['channelDisplayName'] as String?) ??
        (metadata['channelDisplayName'] as String?);

    await _bookkeepingOrders.recordOrder(
      BookkeepingOrderRecordInput(
        order: context.order,
        items: List<CartItem>.from(rawItems),
        machineCode: machineCode,
        channelGroup: context.channel.group,
        channelCode: context.channel.code,
        channelDisplayName: channelDisplayName,
        takeout: takeout,
        createdAt: DateTime.now(),
        orderSnCode: orderSnCode,
      ),
    );
  }
}
