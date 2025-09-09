import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/domain/repositories/menu_repository.dart';
import 'pos_state.dart';

final posViewModelProvider = StateNotifierProvider<PosViewModel, PosState>((ref) {
  final menuRepo = ref.watch(menuRepositoryProvider);
  final vm = PosViewModel(menuRepo);
  // fire and forget init
  vm.bootstrap();
  return vm;
});

class PosViewModel extends StateNotifier<PosState> {
  final MenuRepository _menuRepository;
  PosViewModel(this._menuRepository) : super(PosState.initial());

  List<Product> _allProducts = const [];

  Future<void> bootstrap() async {
    state = state.copyWith(loading: true, error: null);
    try {
  final cats = await _menuRepository.fetchCategories();
      _allProducts = await _menuRepository.fetchCategoriesAndFirstPage();
  // CategoryModel now imported via repository return type; using dynamic field names
  final firstCat = cats.isNotEmpty ? (cats.first as dynamic).categoryCode as String : '';
      state = state.copyWith(
        categories: cats,
        currentCategory: firstCat,
        products: _allProducts.where((p) => p.categoryId == firstCat).toList(),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void selectCategory(String categoryId) {
    state = state.copyWith(
      currentCategory: categoryId,
      products: _filterProducts(categoryId: categoryId, query: state.searchQuery),
    );
  }

  void search(String query) {
    state = state.copyWith(
      searchQuery: query,
      products: _filterProducts(categoryId: state.currentCategory, query: query),
    );
  }

  List<Product> _filterProducts({required String categoryId, required String query}) {
    Iterable<Product> list = _allProducts.where((p) => p.categoryId == categoryId);
    if (query.isNotEmpty) {
      list = list.where((p) => p.name.contains(query));
    }
    return list.toList();
  }

  void addProduct(Product product, {List<SelectedOption> options = const []}) {
    final key = _generateKey(product, options);
    final existing = state.cart.where((c) => c.id == key).toList();
    List<CartItem> updated;
    if (existing.isNotEmpty) {
      updated = state.cart.map((c) => c.id == key ? c.copyWith(quantity: c.quantity + 1) : c).toList();
    } else {
      updated = [
        ...state.cart,
        CartItem(id: key, product: product, options: options, quantity: 1),
      ];
    }
    state = state.copyWith(cart: updated);
  }

  void updateCartItemOptions({required String oldId, required Product product, required List<SelectedOption> newOptions}) {
    final newKey = _generateKey(product, newOptions);
    if (newKey == oldId) {
      // simple in-place update of options (price recalculated dynamically)
      state = state.copyWith(
        cart: state.cart.map((c) => c.id == oldId ? c.copyWith(options: newOptions) : c).toList(),
      );
      return;
    }
    final existingTarget = state.cart.firstWhere(
      (c) => c.id == newKey,
      orElse: () => CartItem(id: '', product: product, options: const [], quantity: 0),
    );
    List<CartItem> updated = [];
    for (final c in state.cart) {
      if (c.id == oldId) {
        if (existingTarget.id.isNotEmpty) {
          // merge quantities into existingTarget
          updated = state.cart
              .where((x) => x.id != oldId && x.id != newKey)
              .toList()
            ..add(existingTarget.copyWith(quantity: existingTarget.quantity + c.quantity));
          state = state.copyWith(cart: updated);
          return;
        } else {
          updated.add(CartItem(id: newKey, product: product, options: newOptions, quantity: c.quantity));
        }
      } else if (c.id != newKey) {
        updated.add(c);
      }
    }
    state = state.copyWith(cart: updated);
  }

  void changeQuantity(String id, int delta) {
    final updated = state.cart
        .map((c) => c.id == id ? c.copyWith(quantity: (c.quantity + delta).clamp(0, 999)) : c)
        .where((c) => c.quantity > 0)
        .toList();
    state = state.copyWith(cart: updated);
  }

  void clearCart() {
    state = state.copyWith(cart: []);
  }

  void checkout() {
    // For now just increment order number and clear cart
    state = state.copyWith(orderNumber: state.orderNumber + 1, cart: []);
  }

  // 挂单: 保存当前购物车并清空
  void suspendCurrentOrder() {
    if (state.cart.isEmpty) return;
    final id = 'S${(state.suspendedCounter + 1).toString().padLeft(3, '0')}';
    final suspendedOrder = SuspendedOrder(
      id: id,
      items: state.cart,
      subtotal: state.subtotal,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      suspended: [...state.suspended, suspendedOrder],
      suspendedCounter: state.suspendedCounter + 1,
      cart: [],
    );
  }

  // 取单: 根据挂单 id 恢复
  void resumeSuspended(String id) {
    final list = [...state.suspended];
    final idx = list.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final order = list.removeAt(idx);
    state = state.copyWith(cart: order.items, suspended: list);
  }

  String _generateKey(Product p, List<SelectedOption> options) {
  final sorted = [...options]..sort((a, b) => a.optionCode.compareTo(b.optionCode));
  final optionKey = sorted.map((e) => '${e.groupCode}:${e.optionCode}').join('|');
  return '${p.id}-$optionKey';
  }
}
