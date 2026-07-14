import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/checkout/checkout_providers.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/presentations/pos/controllers/pos_controller.dart';
import 'package:shop_staff/presentations/pos/order/providers/pos_order_providers.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';

final posControllerProvider = Provider<PosController>((ref) {
  return PosController(
    readOrder: () => ref.read(posOrderControllerProvider),
    readOrderController: () => ref.read(posOrderControllerProvider.notifier),
    readShop: () => ref.read(shopInfoProvider),
    readMachineCode: () => ref.read(machineCodeProvider),
    readLanguage: () => ref.read(shopLanguageProvider),
    readCheckout: () => ref.read(checkoutCoordinatorProvider.notifier),
    emitEffect: ref.read(posEffectControllerProvider).emit,
  );
});
