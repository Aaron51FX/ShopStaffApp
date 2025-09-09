
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';

class PosState {
  final List<CategoryModel> categories; // category list with name/code
  final String currentCategory; // categoryCode
  final List<Product> products; // filtered list per category or search
  final List<CartItem> cart;
  final int orderNumber;
  final bool loading;
  final String? error;
  final String searchQuery;
  final List<SuspendedOrder> suspended; //挂单列表
  final int suspendedCounter; //用于生成挂单号

  const PosState({
    required this.categories,
    required this.currentCategory,
    required this.products,
    required this.cart,
    required this.orderNumber,
    required this.loading,
    required this.error,
    required this.searchQuery,
    required this.suspended,
    required this.suspendedCounter,
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
      suspended: [],
      suspendedCounter: 0,
    );

  double get subtotal => cart.fold(0, (p, e) => p + e.lineTotal);

  PosState copyWith({
    List<CategoryModel>? categories,
    String? currentCategory,
    List<Product>? products,
    List<CartItem>? cart,
    int? orderNumber,
    bool? loading,
    String? error,
    String? searchQuery,
    List<SuspendedOrder>? suspended,
    int? suspendedCounter,
  }) {
    return PosState(
      categories: categories ?? this.categories,
      currentCategory: currentCategory ?? this.currentCategory,
      products: products ?? this.products,
      cart: cart ?? this.cart,
      orderNumber: orderNumber ?? this.orderNumber,
      loading: loading ?? this.loading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      suspended: suspended ?? this.suspended,
      suspendedCounter: suspendedCounter ?? this.suspendedCounter,
    );
  }
}
