import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/pos/customer_display/providers/pos_customer_display_providers.dart';
import 'package:shop_staff/presentations/pos/order/providers/pos_order_providers.dart';
import 'package:shop_staff/presentations/pos/providers/pos_providers.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';
import '../widgets/cart_panel.dart';
import '../widgets/discount_input_dialog.dart';
import '../widgets/pos_app_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/side_bar.dart';
import '../widgets/show_product_option_dialog.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  ProviderSubscription<AsyncValue<PosEffect>>? _effectsSub;

  @override
  void initState() {
    super.initState();
    _effectsSub = ref.listenManual<AsyncValue<PosEffect>>(posEffectsProvider, (
      prev,
      next,
    ) {
      final effect = next.valueOrNull;
      if (effect == null) return;
      unawaited(_handleEffect(effect));
    });
  }

  Future<void> _handleEffect(PosEffect effect) async {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final controller = ref.read(posControllerProvider);

    if (effect is PosToastEffect) {
      final message = _resolveToastMessage(t, effect);
      if (effect.isError) {
        SimpleToast.errorGlobal(message);
      } else {
        SimpleToast.successGlobal(message);
      }
      return;
    }

    if (effect is PosNavigateEffect) {
      ref.read(appRouterProvider).push(effect.location, extra: effect.extra);
      return;
    }

    if (effect is PosPopToRootEffect) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
      return;
    }

    if (effect is PosRequestClearCartConfirmEffect) {
      final ok = await ref
          .read(dialogControllerProvider.notifier)
          .confirm(
            title: t.posClearCartTitle,
            message: t.posClearCartMessage,
            destructive: true,
          );
      if (ok) {
        controller.confirmClearCart();
      }
      return;
    }

    if (effect is PosRequestSuspendConfirmEffect) {
      final ok = await ref
          .read(dialogControllerProvider.notifier)
          .confirm(title: t.posSuspendTitle, message: t.posSuspendMessage);
      if (ok) {
        await controller.confirmSuspendOrder();
      }
      return;
    }
  }

  String _resolveToastMessage(AppLocalizations t, PosToastEffect effect) {
    if (effect.messageKey != null) {
      return switch (effect.messageKey!) {
        PosToastKey.peerSyncDisabled => t.posToastPeerSyncDisabled,
        PosToastKey.peerNotConnected => t.posToastPeerNotConnected,
        PosToastKey.pushedToCustomer => t.posToastPushedToCustomer,
        PosToastKey.pushedConfigToCustomer => t.posToastPushedConfigToCustomer,
        PosToastKey.pushedOptionGroupToCustomer =>
          t.posToastPushedOptionGroupToCustomer,
        PosToastKey.cartEmptyCannotPush => t.posToastCartEmptyCannotPush,
        PosToastKey.cartSentToCustomer => t.posToastCartSentToCustomer,
        PosToastKey.clearedCustomerDisplay => t.posToastClearedCustomerDisplay,
        PosToastKey.localOrderSaveFailed => t.posToastLocalOrderSaveFailed,
        PosToastKey.orderSubmitFailed => t.posToastOrderSubmitFailed,
        PosToastKey.noPayableOrder => t.posToastNoPayableOrder,
      };
    }
    return effect.message ?? '';
  }

  @override
  void dispose() {
    _effectsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(posControllerProvider);
    final orderController = ref.read(posOrderControllerProvider.notifier);
    final customerDisplay = ref.read(posCustomerDisplayControllerProvider);
    final customerDisplayEnabled = ref.watch(posCustomerDisplayEnabledProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.stone100,
      appBar: const PosAppBar(),
      body: Container(
        margin: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CategorySidebar(),
            ProductGrid(
              onTapProduct: (p) async {
                if (!p.isCustomizable) {
                  orderController.addProduct(p);
                  return;
                }
                await showProductOptionDialog(
                  context: context,
                  ref: ref,
                  product: p,
                  existing: null,
                  peerLinkEnabled: customerDisplayEnabled,
                  buildSelectedOptions: (selected) =>
                      controller.buildSelectedOptions(p, selected),
                  validateMissingGroups: (selected) =>
                      controller.validateMissingOptionGroups(p, selected),
                  onConfirmed: (options) =>
                      orderController.addProduct(p, options: options),
                  onSendAll: customerDisplayEnabled
                      ? (options) => customerDisplay.sendOptions(
                          product: p,
                          options: options,
                        )
                      : null,
                  onSendGroup: customerDisplayEnabled
                      ? (group, selections) => customerDisplay.sendOptionGroup(
                          product: p,
                          group: group,
                          selected: selections,
                        )
                      : null,
                  initialSelected: controller.buildInitialOptionSelection(
                    p,
                    existing: null,
                  ),
                );
              },
            ),
            CartPanel(
              onEdit: (item) async {
                final p = item.product;
                if (!p.isCustomizable) return;
                await showProductOptionDialog(
                  context: context,
                  ref: ref,
                  product: p,
                  existing: item,
                  peerLinkEnabled: customerDisplayEnabled,
                  buildSelectedOptions: (selected) =>
                      controller.buildSelectedOptions(p, selected),
                  validateMissingGroups: (selected) =>
                      controller.validateMissingOptionGroups(p, selected),
                  onConfirmed: (options) => orderController.updateItemOptions(
                    oldId: item.id,
                    product: p,
                    options: options,
                  ),
                  onSendAll: customerDisplayEnabled
                      ? (options) => customerDisplay.sendOptions(
                          product: p,
                          options: options,
                        )
                      : null,
                  onSendGroup: customerDisplayEnabled
                      ? (group, selections) => customerDisplay.sendOptionGroup(
                          product: p,
                          group: group,
                          selected: selections,
                        )
                      : null,
                  initialSelected: controller.buildInitialOptionSelection(
                    p,
                    existing: item,
                  ),
                );
              },
              onCheckout: controller.checkout,
              onSuspend: controller.requestSuspendOrder,
              onClear: controller.requestClearCart,
              onDiscount: () async {
                final discount = ref.read(
                  posOrderControllerProvider.select((state) => state.discount),
                );
                final value = await showDiscountInputDialog(
                  context,
                  initialValue: discount,
                );
                if (value != null) {
                  orderController.applyDiscount(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
