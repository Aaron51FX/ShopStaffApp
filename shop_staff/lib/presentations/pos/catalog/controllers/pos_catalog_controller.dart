import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/pos/usecases/fetch_categories_usecase.dart';
import 'package:shop_staff/application/pos/usecases/fetch_category_products_usecase.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/presentations/pos/catalog/state/pos_catalog_state.dart';

class PosCatalogController extends StateNotifier<PosCatalogState> {
  PosCatalogController({
    required FetchCategoriesUseCase fetchCategories,
    required FetchCategoryProductsUseCase fetchProducts,
    required String? Function() readMachineCode,
    required String Function() readLanguage,
    required bool Function() readTakeout,
  }) : _fetchCategories = fetchCategories,
       _fetchProducts = fetchProducts,
       _readMachineCode = readMachineCode,
       _readLanguage = readLanguage,
       _readTakeout = readTakeout,
       super(const PosCatalogState());

  static const favoritesCategoryCode = '__favorites__';

  final FetchCategoriesUseCase _fetchCategories;
  final FetchCategoryProductsUseCase _fetchProducts;
  final String? Function() _readMachineCode;
  final String Function() _readLanguage;
  final bool Function() _readTakeout;

  String? _lastFetchKey;
  int _productRequestId = 0;
  List<Product> _categoryProducts = const [];
  final Map<int, Product> _favoriteCache = {};

  bool get hasCategories => state.categories.isNotEmpty;

  Future<void> load({bool force = false}) async {
    final machineCode = _readMachineCode();
    if (machineCode == null || machineCode.isEmpty) {
      state = state.copyWith(loading: false, error: 'MACHINE_CODE_MISSING');
      return;
    }
    final language = _readLanguage();
    final takeout = _readTakeout();
    final key = '$machineCode|$language|$takeout';
    if (!force && key == _lastFetchKey && hasCategories) return;

    state = state.copyWith(loading: true, error: null);
    try {
      final categories = await _fetchCategories.execute(
        FetchCategoriesInput(
          machineCode: machineCode,
          language: language,
          takeout: takeout,
        ),
      );
      _lastFetchKey = key;
      final firstCategory = categories.isEmpty
          ? ''
          : categories.first.categoryCode;
      state = state.copyWith(
        categories: [
          if (categories.isNotEmpty)
            const CategoryModel(
              categoryCode: favoritesCategoryCode,
              categoryName: '',
              showType: 'normal',
            ),
          ...categories,
        ],
        currentCategory: firstCategory,
        products: const [],
        loading: firstCategory.isNotEmpty,
        error: null,
      );
      if (firstCategory.isNotEmpty) {
        await _loadProducts(firstCategory);
      }
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> selectCategory(String categoryCode) async {
    if (categoryCode == state.currentCategory) return;
    state = state.copyWith(
      currentCategory: categoryCode,
      products: const [],
      loading: true,
      error: null,
    );
    if (categoryCode == favoritesCategoryCode) {
      _showFavorites();
      return;
    }
    await _loadProducts(categoryCode);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query, products: _filtered(query));
  }

  void toggleFavorite(Product product) {
    final favorites = state.favoriteProductIds.toSet();
    if (favorites.remove(product.id)) {
      _favoriteCache.remove(product.id);
    } else {
      favorites.add(product.id);
      _favoriteCache[product.id] = product;
    }
    state = state.copyWith(favoriteProductIds: favorites);
    if (state.currentCategory == favoritesCategoryCode) _showFavorites();
  }

  Future<void> _loadProducts(String categoryCode) async {
    final requestId = ++_productRequestId;
    final machineCode = _readMachineCode();
    if (machineCode == null || machineCode.isEmpty) {
      state = state.copyWith(loading: false, error: 'MACHINE_CODE_MISSING');
      return;
    }
    try {
      _categoryProducts = await _fetchProducts.execute(
        FetchCategoryProductsInput(
          machineCode: machineCode,
          language: _readLanguage(),
          takeout: _readTakeout(),
          categoryCode: categoryCode,
        ),
      );
      if (requestId != _productRequestId) return;
      state = state.copyWith(
        products: _filtered(state.searchQuery),
        loading: false,
        error: null,
      );
    } catch (error) {
      if (requestId != _productRequestId) return;
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  List<Product> _filtered(String query) {
    final source = state.currentCategory == favoritesCategoryCode
        ? state.favoriteProductIds
              .map((id) => _favoriteCache[id])
              .whereType<Product>()
        : _categoryProducts;
    if (query.isEmpty) return source.toList();
    return source.where((product) => product.name.contains(query)).toList();
  }

  void _showFavorites() {
    _categoryProducts = state.favoriteProductIds
        .map((id) => _favoriteCache[id])
        .whereType<Product>()
        .toList();
    state = state.copyWith(
      products: _filtered(state.searchQuery),
      loading: false,
      error: null,
    );
  }
}
