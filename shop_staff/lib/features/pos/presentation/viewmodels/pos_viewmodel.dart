import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import 'pos_state.dart';

final posViewModelProvider = StateNotifierProvider<PosViewModel, PosState>((ref) {
  return PosViewModel()..bootstrap();
});

class PosViewModel extends StateNotifier<PosState> {
  PosViewModel() : super(PosState.initial());

  // Temporary in-memory seed data (will be replaced by repository / use cases)
  final _allProducts = <Product>[
    const Product(id: 1, name: '拿铁', categoryId: 'espresso', price: 32, imageUrl: ''),
    const Product(id: 2, name: '美式咖啡', categoryId: 'espresso', price: 25, imageUrl: ''),
    const Product(id: 3, name: '提拉米苏', categoryId: 'dessert', price: 38, imageUrl: ''),
  ];

  void bootstrap() {
    final categories = <String>{for (final p in _allProducts) p.categoryId}.toList();
    state = state.copyWith(
      categories: categories,
      currentCategory: categories.isNotEmpty ? categories.first : '',
      products: _allProducts.where((p) => p.categoryId == (categories.isNotEmpty ? categories.first : '')).toList(),
      loading: false,
    );
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

  String _generateKey(Product p, List<SelectedOption> options) {
    final sorted = [...options]..sort((a, b) => a.optionName.compareTo(b.optionName));
    final optionKey = sorted.map((e) => '${e.groupName}:${e.optionName}').join('|');
  return '${p.id}-$optionKey';
  }
}
