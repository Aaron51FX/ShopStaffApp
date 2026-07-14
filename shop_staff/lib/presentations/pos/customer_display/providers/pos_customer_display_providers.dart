import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/presentations/peer_link/peer_link.dart';
import 'package:shop_staff/presentations/pos/customer_display/controllers/pos_customer_display_controller.dart';
import 'package:shop_staff/presentations/pos/order/providers/pos_order_providers.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';

final posCustomerDisplayEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
        appSettingsSnapshotProvider.select(
          (settings) => settings?.basic.peerLinkEnabled,
        ),
      ) ??
      true;
});

final posCustomerDisplayControllerProvider =
    Provider<PosCustomerDisplayController>((ref) {
      return PosCustomerDisplayController(
        readEnabled: () => ref.read(posCustomerDisplayEnabledProvider),
        readLinkState: () => ref.read(peerLinkControllerProvider),
        readLinkController: () => ref.read(peerLinkControllerProvider.notifier),
        readOrder: () => ref.read(posOrderControllerProvider),
        emitEffect: ref.read(posEffectControllerProvider).emit,
      );
    });
