import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/checkout/checkout_providers.dart';
import 'package:shop_staff/application/pos/usecases/suspended_orders_usecases.dart';
import 'package:shop_staff/presentations/pos/order/controllers/pos_order_controller.dart';
import 'package:shop_staff/presentations/pos/order/state/pos_order_state.dart';

final orderModeSelectionProvider = StateProvider<String>((ref) => 'dine_in');

final posOrderControllerProvider =
    StateNotifierProvider<PosOrderController, PosOrderState>((ref) {
      final controller = PosOrderController(
        initialMode: ref.read(orderModeSelectionProvider),
        suspendedOrders: ref.watch(suspendedOrdersUseCasesProvider),
      );
      ref.listen(checkoutCoordinatorProvider, (previous, next) {
        final order = next.order;
        final draft = next.draft;
        if (order == null || draft == null) return;
        if (previous?.order?.orderId == order.orderId) return;
        controller.completeCheckout(
          order: order,
          orderNumber: draft.orderNumber,
        );
      });
      unawaited(controller.loadSuspendedOrders());
      return controller;
    });
