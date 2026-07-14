import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';

class PosOrderState {
  const PosOrderState({
    this.cart = const [],
    this.orderNumber = 1000,
    this.suspended = const [],
    this.suspendedCounter = 0,
    this.orderMode = 'dine_in',
    this.discount = 0,
    this.lastOrderResult,
  });

  static const Object _unset = Object();

  final List<CartItem> cart;
  final int orderNumber;
  final List<SuspendedOrder> suspended;
  final int suspendedCounter;
  final String orderMode;
  final double discount;
  final OrderSubmissionResult? lastOrderResult;

  double get subtotal => cart.fold(0, (total, item) => total + item.lineTotal);
  double get total => (subtotal - discount).clamp(0, double.infinity);
  bool get isTakeout => orderMode == 'take_out';

  PosOrderState copyWith({
    List<CartItem>? cart,
    int? orderNumber,
    List<SuspendedOrder>? suspended,
    int? suspendedCounter,
    String? orderMode,
    double? discount,
    Object? lastOrderResult = _unset,
  }) {
    return PosOrderState(
      cart: cart ?? this.cart,
      orderNumber: orderNumber ?? this.orderNumber,
      suspended: suspended ?? this.suspended,
      suspendedCounter: suspendedCounter ?? this.suspendedCounter,
      orderMode: orderMode ?? this.orderMode,
      discount: discount ?? this.discount,
      lastOrderResult: identical(lastOrderResult, _unset)
          ? this.lastOrderResult
          : lastOrderResult as OrderSubmissionResult?,
    );
  }
}
