import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/product.dart';

class PosCatalogState {
  const PosCatalogState({
    this.categories = const [],
    this.currentCategory = '',
    this.products = const [],
    this.favoriteProductIds = const {},
    this.searchQuery = '',
    this.loading = true,
    this.error,
  });

  static const Object _unset = Object();

  final List<CategoryModel> categories;
  final String currentCategory;
  final List<Product> products;
  final Set<int> favoriteProductIds;
  final String searchQuery;
  final bool loading;
  final String? error;

  PosCatalogState copyWith({
    List<CategoryModel>? categories,
    String? currentCategory,
    List<Product>? products,
    Set<int>? favoriteProductIds,
    String? searchQuery,
    bool? loading,
    Object? error = _unset,
  }) {
    return PosCatalogState(
      categories: categories ?? this.categories,
      currentCategory: currentCategory ?? this.currentCategory,
      products: products ?? this.products,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      searchQuery: searchQuery ?? this.searchQuery,
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}
