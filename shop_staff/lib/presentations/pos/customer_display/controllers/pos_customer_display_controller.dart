import 'package:multipeer_session/multipeer_session.dart';

import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/presentations/peer_link/peer_link.dart';
import 'package:shop_staff/presentations/pos/order/state/pos_order_state.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_effect.dart';

class PosCustomerDisplayController {
  const PosCustomerDisplayController({
    required bool Function() readEnabled,
    required PeerLinkState Function() readLinkState,
    required PeerLinkController Function() readLinkController,
    required PosOrderState Function() readOrder,
    required void Function(PosEffect) emitEffect,
  }) : _readEnabled = readEnabled,
       _readLinkState = readLinkState,
       _readLinkController = readLinkController,
       _readOrder = readOrder,
       _emitEffect = emitEffect;

  final bool Function() _readEnabled;
  final PeerLinkState Function() _readLinkState;
  final PeerLinkController Function() _readLinkController;
  final PosOrderState Function() _readOrder;
  final void Function(PosEffect) _emitEffect;

  bool get isEnabled => _readEnabled();
  bool get canSend => isEnabled && _readLinkState().isConnected;

  Future<void> sendCategories(List<CategoryModel> categories) async {
    if (!_ensureAvailable()) return;
    final payload = {
      'categories': categories
          .where((category) => category.categoryCode != '__favorites__')
          .map(
            (category) => {
              'code': category.categoryCode,
              'name': category.categoryName,
              'image': category.image,
            },
          )
          .toList(),
    };
    await _readLinkController().sendMessage(
      PeerMessage(type: 'category_grid', payload: payload),
    );
  }

  Future<void> sendProduct(Product product, {int quantity = 1}) async {
    if (!_ensureAvailable()) return;
    await _readLinkController().sendMessage(
      PeerMessage(
        type: 'product_preview',
        payload: {
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'image': product.imageUrl,
          'categoryId': product.categoryId,
          'quantity': quantity,
        },
      ),
    );
    _emitEffect(const PosToastEffect(messageKey: PosToastKey.pushedToCustomer));
  }

  Future<void> sendOptions({
    required Product product,
    required List<SelectedOption> options,
  }) async {
    if (!_ensureAvailable()) return;
    final extra = options.fold<double>(
      0,
      (total, option) => total + option.extraPrice * option.quantity,
    );
    await _readLinkController().sendMessage(
      PeerMessage(
        type: 'product_options',
        payload: {
          'id': product.id,
          'name': product.name,
          'image': product.imageUrl,
          'basePrice': product.price,
          'totalPrice': product.price + extra,
          'options': options
              .map(
                (option) => {
                  'groupCode': option.groupCode,
                  'groupName': option.groupName,
                  'optionCode': option.optionCode,
                  'optionName': option.optionName,
                  'extraPrice': option.extraPrice,
                  'quantity': option.quantity,
                },
              )
              .toList(),
        },
      ),
    );
    _emitEffect(
      const PosToastEffect(messageKey: PosToastKey.pushedConfigToCustomer),
    );
  }

  Future<void> sendOptionGroup({
    required Product product,
    required OptionGroupEntity group,
    required Map<String, int> selected,
  }) async {
    if (!_ensureAvailable()) return;
    await _readLinkController().sendMessage(
      PeerMessage(
        type: 'option_group',
        payload: {
          'productId': product.id,
          'productName': product.name,
          'productImage': product.imageUrl,
          'groupCode': group.groupCode,
          'groupName': group.groupName,
          'multiple': group.multiple,
          'minSelect': group.minSelect,
          'maxSelect': group.maxSelect,
          'options': group.options
              .map(
                (option) => {
                  'optionCode': option.code,
                  'optionName': option.name,
                  'selected': (selected[option.code] ?? 0) > 0,
                  'quantity': selected[option.code] ?? 0,
                  'extraPrice': option.extraPrice,
                },
              )
              .toList(),
        },
      ),
    );
    _emitEffect(
      const PosToastEffect(messageKey: PosToastKey.pushedOptionGroupToCustomer),
    );
  }

  Future<void> sendCart() async {
    if (!_ensureAvailable()) return;
    final order = _readOrder();
    if (order.cart.isEmpty) {
      _emitEffect(
        const PosToastEffect(
          messageKey: PosToastKey.cartEmptyCannotPush,
          isError: true,
        ),
      );
      return;
    }
    await _readLinkController().sendMessage(
      PeerMessage(
        type: 'cart_snapshot',
        payload: {
          'orderNumber': order.orderNumber,
          'orderMode': order.orderMode,
          'subtotal': order.subtotal,
          'discount': order.discount,
          'total': order.total,
          'items': order.cart
              .map(
                (item) => {
                  'id': item.id,
                  'productId': item.product.id,
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'lineTotal': item.lineTotal,
                  'options': item.options
                      .map(
                        (option) => {
                          'groupName': option.groupName,
                          'optionName': option.optionName,
                          'quantity': option.quantity,
                          'extraPrice': option.extraPrice,
                        },
                      )
                      .toList(),
                },
              )
              .toList(),
        },
      ),
    );
    _emitEffect(
      const PosToastEffect(messageKey: PosToastKey.cartSentToCustomer),
    );
  }

  Future<void> clear() async {
    if (!canSend) return;
    await _readLinkController().sendMessage(
      const PeerMessage(type: 'reset_display', payload: {}),
    );
    _emitEffect(
      const PosToastEffect(messageKey: PosToastKey.clearedCustomerDisplay),
    );
  }

  bool _ensureAvailable() {
    if (!isEnabled) {
      _emitEffect(
        const PosToastEffect(
          messageKey: PosToastKey.peerSyncDisabled,
          isError: true,
        ),
      );
      return false;
    }
    if (!_readLinkState().isConnected) {
      _emitEffect(
        const PosToastEffect(
          messageKey: PosToastKey.peerNotConnected,
          isError: true,
        ),
      );
      return false;
    }
    return true;
  }
}
