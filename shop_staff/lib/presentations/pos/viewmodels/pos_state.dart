
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';

import 'pos_dialog_state.dart';

class PosState {
  static const Object _unset = Object();

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
  final Set<int> favoriteProductIds; // 收藏商品 id 集合
  final String orderMode; // dine_in / take_out
  final double discount; // 未来可扩展多种优惠, 先简单一个数值
  final OrderSubmissionResult? lastOrderResult; // 最近一次下单结果
  final PosDialogState? posDialog;

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
    required this.favoriteProductIds,
    required this.orderMode,
    required this.discount,
    required this.lastOrderResult,
    required this.posDialog,
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
      favoriteProductIds: {},
      orderMode: 'dine_in',
      discount: 0,
      lastOrderResult: null,
      posDialog: null,
    );

  double get subtotal => cart.fold(0, (p, e) => p + e.lineTotal);
  double get total => (subtotal - discount).clamp(0, double.infinity);

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
    Set<int>? favoriteProductIds,
    String? orderMode,
    double? discount,
    OrderSubmissionResult? lastOrderResult,
    Object? posDialog = _unset,
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
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      orderMode: orderMode ?? this.orderMode,
      discount: discount ?? this.discount,
      lastOrderResult: lastOrderResult ?? this.lastOrderResult,
      posDialog: identical(posDialog, _unset) ? this.posDialog : posDialog as PosDialogState?,
    );
  }
}
