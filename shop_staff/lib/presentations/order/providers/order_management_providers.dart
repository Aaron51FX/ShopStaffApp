import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/presentations/order/controllers/order_management_controller.dart';
import 'package:shop_staff/presentations/order/state/order_management_state.dart';

final orderManagementControllerProvider =
    StateNotifierProvider.autoDispose<
      OrderManagementController,
      OrderManagementState
    >((ref) {
      final controller = OrderManagementController(
        repository: ref.watch(orderManagementRepositoryProvider),
        readShopCode: () => ref.read(shopInfoProvider)?.shopCode ?? '',
      );
      Future.microtask(controller.load);
      return controller;
    });
