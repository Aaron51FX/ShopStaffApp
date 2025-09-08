import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';

class PosState {
  final List<String> categories; // category ids
  final String currentCategory;
  final List<Product> products; // filtered list per category or search
  final List<CartItem> cart;
  final int orderNumber;
  final bool loading;
  final String? error;
  final String searchQuery;

  const PosState({
    required this.categories,
    required this.currentCategory,
    required this.products,
    required this.cart,
    required this.orderNumber,
    required this.loading,
    required this.error,
    required this.searchQuery,
  });

  factory PosState.initial() => const PosState(
        categories: [],
        currentCategory: '',
        products: [],
        cart: [],
        orderNumber: 1000,
        loading: true,
        error: null,
        searchQuery: '',
      );

  double get subtotal => cart.fold(0, (p, e) => p + e.lineTotal);

  PosState copyWith({
    List<String>? categories,
    String? currentCategory,
    List<Product>? products,
    List<CartItem>? cart,
    int? orderNumber,
    bool? loading,
    String? error,
    String? searchQuery,
  }) => PosState(
        categories: categories ?? this.categories,
        currentCategory: currentCategory ?? this.currentCategory,
        products: products ?? this.products,
        cart: cart ?? this.cart,
        orderNumber: orderNumber ?? this.orderNumber,
        loading: loading ?? this.loading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}
