import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/checkout/models/checkout_draft.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/presentations/pos/order/controllers/pos_order_controller.dart';
import 'package:shop_staff/presentations/pos/order/state/pos_order_state.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';

class PosController {
  const PosController({
    required PosOrderState Function() readOrder,
    required PosOrderController Function() readOrderController,
    required ShopInfoModel? Function() readShop,
    required String? Function() readMachineCode,
    required String Function() readLanguage,
    required CheckoutCoordinator Function() readCheckout,
    required void Function(PosEffect) emitEffect,
  }) : _readOrder = readOrder,
       _readOrderController = readOrderController,
       _readShop = readShop,
       _readMachineCode = readMachineCode,
       _readLanguage = readLanguage,
       _readCheckout = readCheckout,
       _emitEffect = emitEffect;

  final PosOrderState Function() _readOrder;
  final PosOrderController Function() _readOrderController;
  final ShopInfoModel? Function() _readShop;
  final String? Function() _readMachineCode;
  final String Function() _readLanguage;
  final CheckoutCoordinator Function() _readCheckout;
  final void Function(PosEffect) _emitEffect;

  void requestClearCart() {
    if (_readOrder().cart.isNotEmpty) {
      _emitEffect(const PosRequestClearCartConfirmEffect());
    }
  }

  void confirmClearCart() => _readOrderController().clear();

  void requestSuspendOrder() {
    if (_readOrder().cart.isNotEmpty) {
      _emitEffect(const PosRequestSuspendConfirmEffect());
    }
  }

  Future<void> confirmSuspendOrder() => _readOrderController().suspend();

  void checkout() {
    final order = _readOrder();
    if (order.cart.isEmpty) return;
    final shop = _readShop();
    final machineCode = _readMachineCode();
    if (shop == null || machineCode == null || machineCode.isEmpty) {
      _emitEffect(
        const PosToastEffect(
          messageKey: PosToastKey.orderSubmitFailed,
          isError: true,
        ),
      );
      return;
    }

    final draft = CheckoutDraft(
      shop: shop,
      machineCode: machineCode,
      language: _readLanguage(),
      takeout: order.isTakeout,
      items: List<CartItem>.from(order.cart),
      orderNumber: order.orderNumber + 1,
      subtotal: order.subtotal,
      discount: order.discount,
    );
    _readCheckout().begin(draft);
    _emitEffect(
      PosNavigateEffect(location: '/payment-selection', extra: draft),
    );
  }

  Map<String, Map<String, int>> buildInitialOptionSelection(
    Product product, {
    required CartItem? existing,
  }) {
    final selected = <String, Map<String, int>>{};
    if (existing != null) {
      for (final option in existing.options) {
        selected.putIfAbsent(
          option.groupCode,
          () => <String, int>{},
        )[option.optionCode] = option.quantity;
      }
      return selected;
    }
    for (final group in product.optionGroups) {
      final defaults = group.options.where((option) => option.isDefault);
      if (defaults.isNotEmpty) {
        selected[group.groupCode] = {
          for (final option in defaults) option.code: 1,
        };
      }
    }
    return selected;
  }

  List<String> validateMissingOptionGroups(
    Product product,
    Map<String, Map<String, int>> selected,
  ) {
    return product.optionGroups
        .where((group) {
          final count = (selected[group.groupCode] ?? const {}).values.fold(
            0,
            (total, value) => total + value,
          );
          return group.minSelect > 0 && count < group.minSelect;
        })
        .map((group) => group.groupName)
        .toList();
  }

  List<SelectedOption> buildSelectedOptions(
    Product product,
    Map<String, Map<String, int>> selected,
  ) {
    final result = <SelectedOption>[];
    for (final group in product.optionGroups) {
      for (final entry in (selected[group.groupCode] ?? const {}).entries) {
        final option = group.options.firstWhere(
          (candidate) => candidate.code == entry.key,
        );
        result.add(
          SelectedOption(
            groupCode: group.groupCode,
            groupName: group.groupName,
            optionCode: option.code,
            optionName: option.name,
            extraPrice: option.extraPrice,
            quantity: entry.value,
          ),
        );
      }
    }
    return result;
  }
}
