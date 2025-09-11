import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/domain/repositories/menu_repository.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'pos_state.dart';

final posViewModelProvider = StateNotifierProvider<PosViewModel, PosState>((ref) {
  final menuRepo = ref.watch(menuRepositoryProvider);
  final vm = PosViewModel(menuRepo, ref);
  // fire-and-forget initial bootstrap (may early-exit if machineCode not yet ready)
  vm.bootstrap();
  // Listen for shopInfo becoming available after splash and trigger bootstrap once.
  ref.listen<ShopInfoModel?>(shopInfoProvider, (prev, next) {
    if (next != null && (prev == null)) {
      // Only re-bootstrap if we currently have no categories loaded.
      final hasCategories = vm.debugHasCategories;
      if (!hasCategories) {
        vm.bootstrap();
      }
    }
  });
  return vm;
});

class PosViewModel extends StateNotifier<PosState> {
  final MenuRepository _menuRepository;
  final Ref _ref;
  PosViewModel(this._menuRepository, this._ref) : super(PosState.initial());
  String? _lastCategoryFetchKey; // machineCode|language|takeout

  // 当前分类的商品列表 (不再一次性加载所有分类的全部商品)
  List<Product> _categoryProducts = const [];
  // 收藏商品缓存: key = product.id
  final Map<int, Product> _favoriteCache = {};
  static const String favoritesCategoryCode = '__favorites__';
  // Exposed for provider-level listener sanity checks (not part of public API for widgets)
  bool get debugHasCategories => state.categories.isNotEmpty;

  Future<void> bootstrap() async {
    debugPrint('Bootstrapping POS ViewModel...');
    state = state.copyWith(loading: true, error: null);
    try {
      final machineCode = _ref.read(machineCodeProvider);
      debugPrint('Current machineCode: $machineCode');
      if (machineCode == null || machineCode.isEmpty) {
        state = state.copyWith(loading: false, error: '未激活: 缺少machineCode');
        return;
      }
      final language = _ref.read(shopLanguageProvider);
      final takeout = state.orderMode == 'take_out';
      final cats = await _menuRepository.fetchCategories(machineCode: machineCode, language: language, takeout: takeout);
      _lastCategoryFetchKey = '$machineCode|$language|$takeout';
      
  // 不再预加载所有商品, 只获取分类列表, 后续按需加载
      // CategoryModel now imported via repository return type; using dynamic field names
      final firstCat = cats.isNotEmpty ? (cats.first as dynamic).categoryCode as String : '';
      // 注入一个“收藏”虚拟分类在最前
      final augmentedCats = [
        if (cats.isNotEmpty)
          (cats.first as dynamic).runtimeType != String // keep structure
              ? CategoryModel(categoryCode: favoritesCategoryCode, categoryName: '❤ 收藏', showType: 'normal')
              : null,
        ...cats,
      ].whereType<CategoryModel>().toList();
      state = state.copyWith(
        categories: augmentedCats,
        currentCategory: firstCat,
        products: const [],
      );
      if (firstCat.isNotEmpty) {
        await _fetchCategoryProducts(firstCat, initial: true);
      } else {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // 选择分类: 异步请求该分类商品
  void selectCategory(String categoryId) {
    if (categoryId == state.currentCategory) return;
    state = state.copyWith(
      currentCategory: categoryId,
      products: const [],
      loading: true,
    );
    if (categoryId == favoritesCategoryCode) {
      // 收藏分类本地聚合
      _loadFavoritesCategory();
    } else {
      _fetchCategoryProducts(categoryId); // fire & forget
    }
  }

  void search(String query) {
    state = state.copyWith(
      searchQuery: query,
      products: _applySearch(query),
    );
  }

  // 搜索过滤当前分类(或收藏)商品
  List<Product> _applySearch(String query) {
    Iterable<Product> base;
    if (state.currentCategory == favoritesCategoryCode) {
      base = state.favoriteProductIds.map((id) => _favoriteCache[id]).whereType<Product>();
    } else {
      base = _categoryProducts;
    }
    if (query.isEmpty) return base.toList();
    return base.where((p) => p.name.contains(query)).toList();
  }

  Future<void> _fetchCategoryProducts(String categoryId, {bool initial = false}) async {
    try {
      if (!initial) {
        state = state.copyWith(loading: true, error: null);
      }
      final machineCode = _ref.read(machineCodeProvider);
      if (machineCode == null || machineCode.isEmpty) {
        state = state.copyWith(loading: false, error: '未激活: 缺少machineCode');
        return;
      }
      final language = _ref.read(shopLanguageProvider);
      final takeout = state.orderMode == 'take_out';
      final products = await _menuRepository.fetchMenuByCategory(
        machineCode: machineCode,
        language: language,
        takeout: takeout,
        categoryCode: categoryId,
      );
      _categoryProducts = products;
      state = state.copyWith(
        products: _applySearch(state.searchQuery),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '获取分类商品失败: $e');
    }
  }

  void _loadFavoritesCategory() {
    final favProducts = state.favoriteProductIds
        .map((id) => _favoriteCache[id])
        .whereType<Product>()
        .toList();
    _categoryProducts = favProducts; // 复用结构
    state = state.copyWith(
      products: _applySearch(state.searchQuery),
      loading: false,
    );
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

  void clearCart() async{
    final ok = await _ref.read(dialogControllerProvider.notifier).confirm(
      title: '清空购物车',
      message: '确认要清空购物车吗？',
      destructive: true,
    );
    if (ok) {
      state = state.copyWith(cart: []);
    }
  }

  void checkout() {
    // For now just increment order number and clear cart
    state = state.copyWith(orderNumber: state.orderNumber + 1, cart: []);
  }

  void toggleFavorite(Product p) {
    final favs = state.favoriteProductIds.contains(p.id)
        ? (state.favoriteProductIds.toSet()..remove(p.id))
        : (state.favoriteProductIds.toSet()..add(p.id));
    state = state.copyWith(favoriteProductIds: favs);
    // 如果当前在收藏分类，刷新产品
    if (favs.contains(p.id)) {
      _favoriteCache[p.id] = p; // 缓存收藏商品
    } else {
      _favoriteCache.remove(p.id);
    }
    if (state.currentCategory == favoritesCategoryCode) {
      _loadFavoritesCategory();
    }
  }

  void switchOrderMode() {
  final newMode = state.orderMode == 'dine_in' ? 'take_out' : 'dine_in';
  state = state.copyWith(orderMode: newMode);
  _maybeReloadCategories(force: true);
  }

  void applyDiscount(double value) {
    state = state.copyWith(discount: value);
  }

  // Public API: call when languageOverrideProvider changes
  Future<void> onLanguageChanged() async {
    await _maybeReloadCategories(force: true);
  }

  Future<void> _maybeReloadCategories({bool force = false}) async {
    final machineCode = _ref.read(machineCodeProvider);
    if (machineCode == null || machineCode.isEmpty) return;
    final language = _ref.read(shopLanguageProvider);
    final takeout = state.orderMode == 'take_out';
    final key = '$machineCode|$language|$takeout';
    if (!force && key == _lastCategoryFetchKey) return;
    try {
      final cats = await _menuRepository.fetchCategories(machineCode: machineCode, language: language, takeout: takeout);
      _lastCategoryFetchKey = key;
      final firstCat = cats.isNotEmpty ? (cats.first as dynamic).categoryCode as String : '';
      final augmentedCats = [
        if (cats.isNotEmpty)
          CategoryModel(categoryCode: PosViewModel.favoritesCategoryCode, categoryName: '❤ 收藏', showType: 'normal'),
        ...cats,
      ];
      state = state.copyWith(
        categories: augmentedCats,
        currentCategory: firstCat,
        products: const [],
      );
      if (firstCat.isNotEmpty) {
        _fetchCategoryProducts(firstCat); // fire & forget
      }
    } catch (e) {
      state = state.copyWith(error: '分类刷新失败: $e');
    }
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
