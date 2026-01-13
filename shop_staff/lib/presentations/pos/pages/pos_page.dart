import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_dialog_state.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';
import '../widgets/cart_panel.dart';
import '../widgets/discount_input_dialog.dart';
import '../widgets/pos_app_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/side_bar.dart';
import '../widgets/payment_selection_dialog.dart';
import '../widgets/show_product_option_dialog.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  ProviderSubscription<PosDialogState?>? _dialogSub;
  ProviderSubscription<AsyncValue<PosEffect>>? _effectsSub;
  bool _isPaymentDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _dialogSub = ref.listenManual<PosDialogState?>(
      posViewModelProvider.select((s) => s.posDialog),
      (prev, next) {
        if (next == null) return;
        if (next.type != PosDialogType.paymentSelection) return;
        if (_isPaymentDialogVisible) return;

        _isPaymentDialogVisible = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final vm = ref.read(posViewModelProvider.notifier);
          await showPaymentSelectionDialog(
            context: context,
            shop: next.shop,
            onSelected: (group, code, label) {
              vm.startPaymentFlowFromDialog(
                shop: next.shop,
                group: group,
                code: code,
                label: label,
              );
            },
            onPushToCustomer: vm.peerLinkEnabled()
                ? () => vm.pushPaymentSelectionFromDialog(shop: next.shop, total: next.total)
                : null,
          );
          if (mounted) {
            vm.dismissPosDialog();
          }
          _isPaymentDialogVisible = false;
        });
      },
    );

    _effectsSub = ref.listenManual<AsyncValue<PosEffect>>(
      posEffectsProvider,
      (prev, next) {
        final effect = next.valueOrNull;
        if (effect == null) return;
        unawaited(_handleEffect(effect));
      },
    );
  }

  Future<void> _handleEffect(PosEffect effect) async {
    if (!mounted) return;
    final vm = ref.read(posViewModelProvider.notifier);

    if (effect is PosToastEffect) {
      if (effect.isError) {
        SimpleToast.errorGlobal(effect.message);
      } else {
        SimpleToast.successGlobal(effect.message);
      }
      return;
    }

    if (effect is PosNavigateEffect) {
      ref.read(appRouterProvider).push(effect.location, extra: effect.extra);
      return;
    }

    if (effect is PosPopToRootEffect) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      return;
    }

    if (effect is PosRequestClearCartConfirmEffect) {
      final ok = await ref.read(dialogControllerProvider.notifier).confirm(
            title: '清空购物车',
            message: '确认要清空购物车吗？',
            destructive: true,
          );
      if (ok) {
        vm.confirmClearCart();
      }
      return;
    }

    if (effect is PosRequestSuspendConfirmEffect) {
      final ok = await ref.read(dialogControllerProvider.notifier).confirm(
            title: '挂单',
            message: '确认要挂单吗？',
          );
      if (ok) {
        vm.confirmSuspendCurrentOrder();
      }
      return;
    }
  }

  @override
  void dispose() {
    _dialogSub?.close();
    _effectsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(posViewModelProvider.notifier);
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
                  vm.addProduct(p);
                  return;
                }
                await showProductOptionDialog(
                  context: context,
                  ref: ref,
                  product: p,
                  existing: null,
                  peerLinkEnabled: vm.peerLinkEnabled(),
                  buildSelectedOptions: (selected) => vm.buildSelectedOptions(p, selected),
                  validateMissingGroups: (selected) => vm.validateMissingOptionGroups(p, selected),
                  onConfirmed: (options) => vm.addProduct(p, options: options),
                  onSendAll: vm.peerLinkEnabled()
                      ? (options) => vm.pushSelectedOptionsToCustomer(product: p, options: options)
                      : null,
                  onSendGroup: vm.peerLinkEnabled()
                      ? (group, selections) => vm.pushOptionGroupToCustomer(
                            product: p,
                            group: group,
                            selected: selections,
                          )
                      : null,
                  initialSelected: vm.buildInitialOptionSelection(p, existing: null),
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
                  peerLinkEnabled: vm.peerLinkEnabled(),
                  buildSelectedOptions: (selected) => vm.buildSelectedOptions(p, selected),
                  validateMissingGroups: (selected) => vm.validateMissingOptionGroups(p, selected),
                  onConfirmed: (options) => vm.updateCartItemOptions(
                    oldId: item.id,
                    product: p,
                    newOptions: options,
                  ),
                  onSendAll: vm.peerLinkEnabled()
                      ? (options) => vm.pushSelectedOptionsToCustomer(product: p, options: options)
                      : null,
                  onSendGroup: vm.peerLinkEnabled()
                      ? (group, selections) => vm.pushOptionGroupToCustomer(
                            product: p,
                            group: group,
                            selected: selections,
                          )
                      : null,
                  initialSelected: vm.buildInitialOptionSelection(p, existing: item),
                );
              },
              onCheckout: vm.checkout,
              onSuspend: vm.suspendCurrentOrder,
              onClear: vm.clearCart,
              onDiscount: () async {
                final discount = ref.read(
                  posViewModelProvider.select((s) => s.discount),
                );
                final value = await showDiscountInputDialog(
                  context,
                  initialValue: discount,
                );
                if (value != null) {
                  vm.applyDiscount(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
