import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/pos/usecases/suspended_orders_usecases.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/presentations/pos/order/state/pos_order_state.dart';

class PosOrderController extends StateNotifier<PosOrderState> {
  PosOrderController({
    required String initialMode,
    required SuspendedOrdersUseCases suspendedOrders,
  }) : _suspendedOrders = suspendedOrders,
       super(
         PosOrderState(
           orderMode: initialMode == 'take_out' ? 'take_out' : 'dine_in',
         ),
       );

  final SuspendedOrdersUseCases _suspendedOrders;

  Future<void> loadSuspendedOrders() async {
    final orders = await _suspendedOrders.loadAll();
    state = state.copyWith(suspended: orders, suspendedCounter: orders.length);
  }

  void addProduct(Product product, {List<SelectedOption> options = const []}) {
    final key = _itemKey(product, options);
    final exists = state.cart.any((item) => item.id == key);
    final updated = exists
        ? state.cart
              .map(
                (item) => item.id == key
                    ? item.copyWith(quantity: item.quantity + 1)
                    : item,
              )
              .toList()
        : [
            ...state.cart,
            CartItem(id: key, product: product, options: options, quantity: 1),
          ];
    state = state.copyWith(cart: updated);
  }

  void updateItemOptions({
    required String oldId,
    required Product product,
    required List<SelectedOption> options,
  }) {
    final oldItem = state.cart.where((item) => item.id == oldId).firstOrNull;
    if (oldItem == null) return;
    final newId = _itemKey(product, options);
    final target = state.cart.where((item) => item.id == newId).firstOrNull;

    if (newId == oldId) {
      state = state.copyWith(
        cart: state.cart
            .map(
              (item) =>
                  item.id == oldId ? item.copyWith(options: options) : item,
            )
            .toList(),
      );
      return;
    }

    final updated = state.cart
        .where((item) => item.id != oldId && item.id != newId)
        .toList();
    updated.add(
      target != null
          ? target.copyWith(quantity: target.quantity + oldItem.quantity)
          : CartItem(
              id: newId,
              product: product,
              options: options,
              quantity: oldItem.quantity,
            ),
    );
    state = state.copyWith(cart: updated);
  }

  void changeQuantity(String id, int delta) {
    state = state.copyWith(
      cart: state.cart
          .map(
            (item) => item.id == id
                ? item.copyWith(quantity: (item.quantity + delta).clamp(0, 999))
                : item,
          )
          .where((item) => item.quantity > 0)
          .toList(),
    );
  }

  void clear() {
    state = state.copyWith(cart: const [], discount: 0);
  }

  void applyDiscount(double value) {
    state = state.copyWith(discount: value);
  }

  void setOrderMode(String mode, {bool clearCart = false}) {
    state = state.copyWith(
      orderMode: mode == 'take_out' ? 'take_out' : 'dine_in',
      cart: clearCart ? const [] : state.cart,
      discount: clearCart ? 0 : state.discount,
    );
  }

  Future<void> suspend() async {
    if (state.cart.isEmpty) return;
    final order = SuspendedOrder(
      id: 'S${(state.suspendedCounter + 1).toString().padLeft(3, '0')}',
      items: state.cart,
      subtotal: state.subtotal,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      suspended: [...state.suspended, order],
      suspendedCounter: state.suspendedCounter + 1,
      cart: const [],
      discount: 0,
    );
    await _suspendedOrders.save(order);
  }

  Future<void> resumeSuspended(String id, {bool deleteAfter = true}) async {
    final index = state.suspended.indexWhere((order) => order.id == id);
    if (index < 0) return;
    final orders = [...state.suspended];
    final order = orders.removeAt(index);
    state = state.copyWith(cart: order.items, suspended: orders, discount: 0);
    if (deleteAfter) await _suspendedOrders.delete(id);
  }

  void loadFromLocalOrder(LocalOrderRecord record) {
    state = state.copyWith(
      orderMode: record.takeout ? 'take_out' : 'dine_in',
      cart: record.items,
      discount: record.discount,
      lastOrderResult: null,
    );
  }

  void completeCheckout({
    required OrderSubmissionResult order,
    required int orderNumber,
  }) {
    state = state.copyWith(
      cart: const [],
      discount: 0,
      orderNumber: orderNumber,
      lastOrderResult: order,
    );
  }

  String _itemKey(Product product, List<SelectedOption> options) {
    final sorted = [...options]
      ..sort((left, right) => left.optionCode.compareTo(right.optionCode));
    final optionKey = sorted
        .map((option) => '${option.groupCode}:${option.optionCode}')
        .join('|');
    return '${product.id}-$optionKey';
  }
}
