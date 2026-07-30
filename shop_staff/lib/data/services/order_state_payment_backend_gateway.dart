import 'package:logging/logging.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';

import 'payment_backend_gateway.dart';

class OrderStatePaymentBackendGateway implements PaymentBackendGateway {
  OrderStatePaymentBackendGateway({
    required BookkeepingOrderRepository bookkeepingOrders,
    Logger? logger,
  }) : _bookkeepingOrders = bookkeepingOrders,
       _logger = logger ?? Logger('OrderStatePaymentBackendGateway');

  final BookkeepingOrderRepository _bookkeepingOrders;
  final Logger _logger;

  @override
  Future<PrintInfoDocument?> confirmPayment(
    PaymentContext context,
    Map<String, dynamic> payload,
  ) async {
    final metadata = context.metadata ?? const <String, dynamic>{};
    final requiresOrderStateUpdate =
        context.mode == PaymentFlowMode.bookkeeping ||
        metadata['requiresOrderStateUpdate'] == true;
    if (!requiresOrderStateUpdate) {
      _logger.info(
        '[CHECKOUT_FLOW] skip order state update for actual payment '
        'orderId=${context.order.orderId} channel=${context.channel.group}',
      );
      return null;
    }

    final machineCode = (metadata['machineCode'] as String? ?? '').trim();
    if (machineCode.isEmpty) {
      throw StateError('ORDER_STATE_UPDATE_MACHINE_CODE_MISSING');
    }

    final finalTotal = _toInt(metadata['finalTotal']) ?? context.order.total;
    final discount = _toInt(metadata['discount']) ?? 0;
    final payPrice = context.channel.group == PaymentChannels.cash
        ? _cashPayPrice(payload) ?? finalTotal
        : null;
    final payChannel = switch (context.channel.group) {
      PaymentChannels.cash => 'Cash',
      PaymentChannels.card => 'CreditCard',
      PaymentChannels.qr => 'PayPay',
      _ => throw StateError('ORDER_STATE_UPDATE_CHANNEL_UNSUPPORTED'),
    };

    _logger.info(
      '[CHECKOUT_FLOW] update order state '
      'orderId=${context.order.orderId} payChannel=$payChannel '
      'payPrice=$payPrice discount=$discount finalTotal=$finalTotal',
    );
    return _bookkeepingOrders.updateOrderState(
      OrderStateUpdateInput(
        orderId: context.order.orderId,
        machineCode: machineCode,
        payChannel: payChannel,
        payPrice: payPrice,
        discount: discount,
        finalTotal: finalTotal,
      ),
    );
  }

  int? _cashPayPrice(Map<String, dynamic> payload) {
    final receipt = payload['receipt'];
    if (receipt is! Map) return null;
    return _toInt(receipt['acceptedAmount']) ??
        _toInt(receipt['payAmount']) ??
        _toInt(receipt['amount']);
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return num.tryParse(value.trim())?.round();
    return null;
  }
}
