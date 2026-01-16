import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/application/pos/usecases/build_payment_flow_args_usecase.dart';
import 'package:shop_staff/application/pos/usecases/fetch_categories_usecase.dart';
import 'package:shop_staff/application/pos/usecases/fetch_category_products_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/prepare_payment_selection_usecase.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/application/pos/usecases/suspended_orders_usecases.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/presentations/entry/viewmodels/peer_link_controller.dart';
import 'pos_state.dart';

import 'pos_dialog_state.dart';
import 'pos_effect.dart';

final orderModeSelectionProvider = StateProvider<String>((ref) => 'dine_in');

final posViewModelProvider = StateNotifierProvider<PosViewModel, PosState>((
  ref,
) {
  final initialMode = ref.read(orderModeSelectionProvider);
  final vm = PosViewModel(ref, initialMode: initialMode);
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
  // Also listen specifically for machineCode becoming non-empty (covers case where shopInfo was already set before this provider was built)
  ref.listen<String?>(machineCodeProvider, (prev, next) {
    if ((prev == null || prev.isEmpty) && next != null && next.isNotEmpty) {
      if (!vm.debugHasCategories) {
        vm.bootstrap();
      }
    }
  });

  ref.listen<PeerLinkState>(peerLinkControllerProvider, (prev, next) {
    vm.handlePeerMessage(next, prev);
  });
  return vm;
});

class PosViewModel extends StateNotifier<PosState> {
  final Ref _ref;
  final SubmitOrderUseCase _submitOrderUseCase;
  final LocalOrdersUseCases _localOrdersUseCases;
  final PreparePaymentSelectionUseCase _preparePaymentSelectionUseCase;
  final BuildPaymentFlowArgsUseCase _buildPaymentFlowArgsUseCase;
  final FetchCategoriesUseCase _fetchCategoriesUseCase;
  final FetchCategoryProductsUseCase _fetchCategoryProductsUseCase;
  final SuspendedOrdersUseCases _suspendedOrders;
  bool _bootstrapped = false;

  final StreamController<PosEffect> _effects = StreamController<PosEffect>.broadcast();
  Stream<PosEffect> get effects => _effects.stream;

  void _emit(PosEffect effect) {
    if (_effects.isClosed) return;
    _effects.add(effect);
  }

  PosViewModel(
    this._ref, {
    required String initialMode,
    SubmitOrderUseCase? submitOrderUseCase,
    LocalOrdersUseCases? localOrdersUseCases,
    PreparePaymentSelectionUseCase? preparePaymentSelectionUseCase,
    BuildPaymentFlowArgsUseCase? buildPaymentFlowArgsUseCase,
    FetchCategoriesUseCase? fetchCategoriesUseCase,
    FetchCategoryProductsUseCase? fetchCategoryProductsUseCase,
    SuspendedOrdersUseCases? suspendedOrders,
  })  : _submitOrderUseCase = submitOrderUseCase ?? _ref.read(submitOrderUseCaseProvider),
      _localOrdersUseCases = localOrdersUseCases ?? _ref.read(localOrdersUseCasesProvider),
        _preparePaymentSelectionUseCase =
            preparePaymentSelectionUseCase ?? _ref.read(preparePaymentSelectionUseCaseProvider),
        _buildPaymentFlowArgsUseCase =
            buildPaymentFlowArgsUseCase ?? _ref.read(buildPaymentFlowArgsUseCaseProvider),
        _fetchCategoriesUseCase = fetchCategoriesUseCase ?? _ref.read(fetchCategoriesUseCaseProvider),
        _fetchCategoryProductsUseCase =
            fetchCategoryProductsUseCase ?? _ref.read(fetchCategoryProductsUseCaseProvider),
        _suspendedOrders = suspendedOrders ?? _ref.read(suspendedOrdersUseCasesProvider),
        super(
        PosState.initial().copyWith(
          orderMode: initialMode == 'take_out' ? 'take_out' : 'dine_in',
        ),
      );
  int _lastPeerMessageSeq = 0;
  String? _lastCategoryFetchKey; // machineCode|language|takeout

  // 当前分类的商品列表 (不再一次性加载所有分类的全部商品)
  List<Product> _categoryProducts = const [];
  // 收藏商品缓存: key = product.id
  final Map<int, Product> _favoriteCache = {};
  static const String favoritesCategoryCode = '__favorites__';
  // Exposed for provider-level listener sanity checks (not part of public API for widgets)
  bool get debugHasCategories => state.categories.isNotEmpty;

  bool peerLinkEnabled() {
    final snapshot = _ref.read(appSettingsSnapshotProvider);
    return snapshot?.basic.peerLinkEnabled ?? true;
  }

  bool _ensurePeerLinkEnabled({bool toast = true}) {
    final enabled = peerLinkEnabled();
    if (!enabled && toast) {
      _emit(const PosToastEffect(message: '顾客端同步已关闭', isError: true));
    }
    return enabled;
  }

  void dismissPosDialog() {
    if (state.posDialog != null) {
      state = state.copyWith(posDialog: null);
    }
  }

  bool canPushToCustomer() {
    return peerLinkEnabled() && _ref.read(peerLinkControllerProvider).isConnected;
  }

  Future<void> bootstrap() async {
    debugPrint('Bootstrapping POS ViewModel...');
    state = state.copyWith(loading: true, error: null);
    try {
      // load suspended orders from local storage (non-blocking for network)
      final loaded = await _suspendedOrders.loadAll();
      if (loaded.isNotEmpty) {
        state = state.copyWith(
          suspended: loaded,
          suspendedCounter: loaded.length,
        );
      }
      final machineCode = _ref.read(machineCodeProvider);
      debugPrint('Current machineCode: $machineCode');
      if (machineCode == null || machineCode.isEmpty) {
        state = state.copyWith(loading: false, error: '未激活: 缺少machineCode');
        return;
      }
      final language = _ref.read(shopLanguageProvider);
      final takeout = state.orderMode == 'take_out';
      final cats = await _fetchCategoriesUseCase.execute(
        FetchCategoriesInput(machineCode: machineCode, language: language, takeout: takeout),
      );
      _lastCategoryFetchKey = '$machineCode|$language|$takeout';

      // 不再预加载所有商品, 只获取分类列表, 后续按需加载
      // CategoryModel now imported via repository return type; using dynamic field names
      final firstCat = cats.isNotEmpty
          ? (cats.first as dynamic).categoryCode as String
          : '';
      // 注入一个“收藏”虚拟分类在最前
      final augmentedCats = [
        if (cats.isNotEmpty)
          (cats.first as dynamic).runtimeType !=
                  String // keep structure
              ? CategoryModel(
                  categoryCode: favoritesCategoryCode,
                  categoryName: '❤ 收藏',
                  showType: 'normal',
                )
              : null,
        ...cats,
      ].whereType<CategoryModel>().toList();
      state = state.copyWith(
        categories: augmentedCats,
        currentCategory: firstCat,
        products: const [],
      );
      _broadcastCategories(cats);
      if (firstCat.isNotEmpty) {
        await _fetchCategoryProducts(firstCat, initial: true);
      } else {
        state = state.copyWith(loading: false);
      }
      _bootstrapped = true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ---- Customer display push helpers ----
  Future<void> broadcastCategories() async {
    if (!_ensurePeerLinkEnabled()) return;
    final categories = state.categories
        .where((c) => c.categoryCode != favoritesCategoryCode)
        .toList();

    await _broadcastCategories(categories, toastOnDisabled: true);
  }

  Future<void> _broadcastCategories(
    List<CategoryModel> categories, {
    bool toastOnDisabled = false,
  }) async {
    if (!_ensurePeerLinkEnabled(toast: toastOnDisabled)) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    final connected = _ref.read(peerLinkControllerProvider).isConnected;
    if (!connected) {
      _emit(const PosToastEffect(message: '顾客端未连接，推送失败', isError: true));
      return;
    }
    final payload = {
      'categories': categories
          .map((c) => {
                'code': c.categoryCode,
                'name': c.categoryName,
                'image': c.image,
              })
          .toList(),
    };
    await controller.sendMessage(PeerMessage(type: 'category_grid', payload: payload));
  }

  Future<void> pushProductToCustomer(Product product, {int quantity = 1}) async {
    if (!_ensurePeerLinkEnabled()) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    final connected = _ref.read(peerLinkControllerProvider).isConnected;
    if (!connected) {
      _emit(const PosToastEffect(message: '顾客端未连接，推送失败', isError: true));
      return;
    }
    final payload = {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'image': product.imageUrl,
      'categoryId': product.categoryId,
      'quantity': quantity,
    };
    await controller.sendMessage(PeerMessage(type: 'product_preview', payload: payload));
    _emit(const PosToastEffect(message: '已推送到顾客端'));
  }

  Future<void> _sendOptionsToCustomer({required Product product, required List<SelectedOption> options}) async {
    if (!_ensurePeerLinkEnabled()) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    final connected = _ref.read(peerLinkControllerProvider).isConnected;
    if (!connected) {
      _emit(const PosToastEffect(message: '顾客端未连接，推送失败', isError: true));
      return;
    }
    final basePrice = product.price;
    final optionsExtra = options.fold<double>(0, (p, e) => p + e.extraPrice * e.quantity);
    final total = basePrice + optionsExtra;
    final payload = {
      'id': product.id,
      'name': product.name,
      'image': product.imageUrl,
      'basePrice': basePrice,
      'totalPrice': total,
      'options': options
          .map((o) => {
                'groupCode': o.groupCode,
                'groupName': o.groupName,
                'optionCode': o.optionCode,
                'optionName': o.optionName,
                'extraPrice': o.extraPrice,
                'quantity': o.quantity,
              })
          .toList(),
    };
    await controller.sendMessage(PeerMessage(type: 'product_options', payload: payload));
    _emit(const PosToastEffect(message: '已推送当前配置到顾客端'));
  }

  Future<void> _sendOptionGroupToCustomer({required Product product, required OptionGroupEntity group, required Map<String, int> selected}) async {
    if (!_ensurePeerLinkEnabled()) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    final connected = _ref.read(peerLinkControllerProvider).isConnected;
    if (!connected) {
      _emit(const PosToastEffect(message: '顾客端未连接，推送失败', isError: true));
      return;
    }
    final payload = {
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
            (o) {
              final qty = selected[o.code] ?? 0;
              return {
                'optionCode': o.code,
                'optionName': o.name,
                'selected': qty > 0,
                'quantity': qty,
                'extraPrice': o.extraPrice,
              };
            },
          )
          .toList(),
    };
    await controller.sendMessage(PeerMessage(type: 'option_group', payload: payload));
    _emit(const PosToastEffect(message: '已推送分组选项给顾客'));
  }

  Future<void> sendCartToCustomer() async {
    if (!_ensurePeerLinkEnabled()) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    final connected = _ref.read(peerLinkControllerProvider).isConnected;
    if (!connected) {
      _emit(const PosToastEffect(message: '顾客端未连接，推送失败', isError: true));
      return;
    }
    if (state.cart.isEmpty) {
      _emit(const PosToastEffect(message: '购物车为空，无法推送', isError: true));
      return;
    }

    final payload = {
      'orderNumber': state.orderNumber,
      'orderMode': state.orderMode,
      'subtotal': state.subtotal,
      'discount': state.discount,
      'total': state.total,
      'items': state.cart
          .map(
            (c) => {
              'id': c.id,
              'productId': c.product.id,
              'name': c.product.name,
              'quantity': c.quantity,
              'unitPrice': c.unitPrice,
              'lineTotal': c.lineTotal,
              'options': c.options
                  .map(
                    (o) => {
                      'groupName': o.groupName,
                      'optionName': o.optionName,
                      'quantity': o.quantity,
                      'extraPrice': o.extraPrice,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };

    await controller.sendMessage(PeerMessage(type: 'cart_snapshot', payload: payload));
    _emit(const PosToastEffect(message: '已将购物车发送到顾客端'));
  }

  Future<void> _sendPaymentSelectionToCustomer(ShopInfoModel shop, double total) async {
    if (!_ensurePeerLinkEnabled()) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    if (!_ref.read(peerLinkControllerProvider).isConnected) {
      _emit(const PosToastEffect(message: '顾客端未连接，推送失败', isError: true));
      return;
    }

    final selection = _preparePaymentSelectionUseCase.execute(shop: shop);
    final payload = selection.toPayload(orderNumber: state.orderNumber, total: total);

    debugPrint('Sending payment selection to customer: $payload');

    await controller.sendMessage(PeerMessage(type: 'payment_selection', payload: payload));
  }

  Future<void> clearCustomerDisplay() async {
    if (!_ensurePeerLinkEnabled()) return;
    final controller = _ref.read(peerLinkControllerProvider.notifier);
    final connected = _ref.read(peerLinkControllerProvider).isConnected;
    if (!connected) return;
    await controller.sendMessage(const PeerMessage(type: 'reset_display', payload: {}));
    _emit(const PosToastEffect(message: '已清除顾客端展示'));
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
    state = state.copyWith(searchQuery: query, products: _applySearch(query));
  }

  // 搜索过滤当前分类(或收藏)商品
  List<Product> _applySearch(String query) {
    Iterable<Product> base;
    if (state.currentCategory == favoritesCategoryCode) {
      base = state.favoriteProductIds
          .map((id) => _favoriteCache[id])
          .whereType<Product>();
    } else {
      base = _categoryProducts;
    }
    if (query.isEmpty) return base.toList();
    return base.where((p) => p.name.contains(query)).toList();
  }

  Future<void> _fetchCategoryProducts(
    String categoryId, {
    bool initial = false,
  }) async {
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
      final products = await _fetchCategoryProductsUseCase.execute(
        FetchCategoryProductsInput(
          machineCode: machineCode,
          language: language,
          takeout: takeout,
          categoryCode: categoryId,
        ),
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
      updated = state.cart
          .map((c) => c.id == key ? c.copyWith(quantity: c.quantity + 1) : c)
          .toList();
    } else {
      updated = [
        ...state.cart,
        CartItem(id: key, product: product, options: options, quantity: 1),
      ];
    }
    state = state.copyWith(cart: updated);
  }

  void updateCartItemOptions({
    required String oldId,
    required Product product,
    required List<SelectedOption> newOptions,
  }) {
    final newKey = _generateKey(product, newOptions);
    if (newKey == oldId) {
      // simple in-place update of options (price recalculated dynamically)
      state = state.copyWith(
        cart: state.cart
            .map((c) => c.id == oldId ? c.copyWith(options: newOptions) : c)
            .toList(),
      );
      return;
    }
    final existingTarget = state.cart.firstWhere(
      (c) => c.id == newKey,
      orElse: () =>
          CartItem(id: '', product: product, options: const [], quantity: 0),
    );
    List<CartItem> updated = [];
    for (final c in state.cart) {
      if (c.id == oldId) {
        if (existingTarget.id.isNotEmpty) {
          // merge quantities into existingTarget
          updated =
              state.cart.where((x) => x.id != oldId && x.id != newKey).toList()
                ..add(
                  existingTarget.copyWith(
                    quantity: existingTarget.quantity + c.quantity,
                  ),
                );
          state = state.copyWith(cart: updated);
          return;
        } else {
          updated.add(
            CartItem(
              id: newKey,
              product: product,
              options: newOptions,
              quantity: c.quantity,
            ),
          );
        }
      } else if (c.id != newKey) {
        updated.add(c);
      }
    }
    state = state.copyWith(cart: updated);
  }

  void changeQuantity(String id, int delta) {
    final updated = state.cart
        .map(
          (c) => c.id == id
              ? c.copyWith(quantity: (c.quantity + delta).clamp(0, 999))
              : c,
        )
        .where((c) => c.quantity > 0)
        .toList();
    state = state.copyWith(cart: updated);
  }

  void clearCart() {
    _emit(const PosRequestClearCartConfirmEffect());
  }

  void confirmClearCart() {
    state = state.copyWith(cart: []);
  }

  void navToSuspendedOrder() {
    _emit(const PosNavigateEffect(location: '/pos/suspended'));
  }

  void navToSettings() {
    _emit(const PosNavigateEffect(location: '/settings'));
  }

  void checkout() {
    _submitOrder();
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

  Future<void> switchOrderMode() async {
    final newMode = state.orderMode == 'dine_in' ? 'take_out' : 'dine_in';
    await setOrderMode(newMode);
  }

  Future<void> setOrderMode(
    String mode, {
    bool clearCart = false,
    bool forceReload = false,
  }) async {
    final normalized = mode == 'take_out' ? 'take_out' : 'dine_in';
    final changed = state.orderMode != normalized;
    if (clearCart && state.cart.isNotEmpty) {
      state = state.copyWith(cart: [], discount: 0);
    }
    if (!changed && !forceReload && _bootstrapped) {
      return;
    }
    state = state.copyWith(orderMode: normalized);
    if (_bootstrapped) {
      await _maybeReloadCategories(force: true);
    } else {
      await bootstrap();
    }
  }

  void applyDiscount(double value) {
    state = state.copyWith(discount: value);
  }

  /// Load a historical local order into the current cart for reorder.
  /// Does not trigger network; simply maps takeout flag to orderMode and applies discount/cart snapshot.
  void loadFromLocalOrder(LocalOrderRecord record) {
    final mode = record.takeout ? 'take_out' : 'dine_in';
    state = state.copyWith(
      orderMode: mode,
      cart: record.items,
      discount: record.discount,
      lastOrderResult: null,
      posDialog: null,
    );
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
      final cats = await _fetchCategoriesUseCase.execute(
        FetchCategoriesInput(machineCode: machineCode, language: language, takeout: takeout),
      );
      _lastCategoryFetchKey = key;
      final firstCat = cats.isNotEmpty
          ? (cats.first as dynamic).categoryCode as String
          : '';
      final augmentedCats = [
        if (cats.isNotEmpty)
          CategoryModel(
            categoryCode: PosViewModel.favoritesCategoryCode,
            categoryName: '❤ 收藏',
            showType: 'normal',
          ),
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

    _emit(const PosRequestSuspendConfirmEffect());
  }

  void confirmSuspendCurrentOrder() {
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
    _suspendedOrders.save(suspendedOrder);
  }

  // 取单: 根据挂单 id 恢复
  void resumeSuspended(String id, {bool isDeleteAfter = true}) {
    final list = [...state.suspended];
    final idx = list.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final order = list.removeAt(idx);
    state = state.copyWith(cart: order.items, suspended: list);
    // remove from local
    if (isDeleteAfter) {
      _suspendedOrders.delete(id);
    }
  }

  String _generateKey(Product p, List<SelectedOption> options) {
    final sorted = [...options]
      ..sort((a, b) => a.optionCode.compareTo(b.optionCode));
    final optionKey = sorted
        .map((e) => '${e.groupCode}:${e.optionCode}')
        .join('|');
    return '${p.id}-$optionKey';
  }

  Future<void> _submitOrder() async {
    if (state.cart.isEmpty) return;
    final machineCode = _ref.read(machineCodeProvider);
    if (machineCode == null || machineCode.isEmpty) {
      state = state.copyWith(error: '无法下单: 缺少machineCode');
      return;
    }
    final language = _ref.read(shopLanguageProvider);
    final takeout = state.orderMode == 'take_out';
    final itemsSnapshot = List<CartItem>.from(state.cart);
    try {
      final output = await _submitOrderUseCase.execute(
        SubmitOrderInput(
          items: itemsSnapshot,
          machineCode: machineCode,
          language: language,
          takeout: takeout,
          discount: state.discount,
        ),
      );
      final result = output.order;
      final total = output.total;

      // Save local order record (best-effort; should not block payment flow).
      try {
        await _localOrdersUseCases.save(
          LocalOrderRecord(
            orderId: result.orderId,
            createdAt: DateTime.now(),
            isPaid: false,
            items: itemsSnapshot,
            machineCode: machineCode,
            language: language,
            takeout: takeout,
            discount: state.discount,
            clientTotal: total,
            orderResult: result,
          ),
        );
      } catch (e) {
        debugPrint('Failed to save local order record: $e');
        _emit(const PosToastEffect(message: '本地订单保存失败', isError: true));
      }

      state = state.copyWith(
        orderNumber: state.orderNumber + 1,
        lastOrderResult: result,
      );
      debugPrint(
        'Order submitted: ${result.orderId} total=${result.total} tax1=${result.tax1} tax2=${result.tax2}',
      );
      // After successful order, present payment selection dialog
      final shop = _ref.read(shopInfoProvider);
      if (shop != null) {
        if (peerLinkEnabled()) {
          unawaited(_sendPaymentSelectionToCustomer(shop, total));
        }
        state = state.copyWith(posDialog: PosDialogState.paymentSelection(shop: shop, total: total));
      }
    } catch (e) {
      state = state.copyWith(error: '下单失败: $e');
      _emit(const PosToastEffect(message: '下单失败', isError: true));
    }
  }

  void startPaymentFlowFromDialog({
    required ShopInfoModel shop,
    required String group,
    required String code,
    required String? label,
  }) {
    final machineCode = _ref.read(machineCodeProvider);
    final result = state.lastOrderResult;
    if (machineCode == null || machineCode.isEmpty || result == null) {
      _emit(const PosToastEffect(message: '当前没有可支付的订单', isError: true));
      return;
    }

    try {
      final posInfo = _ref.read(appSettingsSnapshotProvider)?.posTerminal;
      final args = _buildPaymentFlowArgsUseCase.execute(
        order: result,
        shop: shop,
        machineCode: machineCode,
        group: group,
        code: code,
        label: label,
        posInfo: posInfo,
      );
      state = state.copyWith(cart: []);
      dismissPosDialog();
      _emit(PosNavigateEffect(location: '/payment', extra: args));
    } catch (e) {
      debugPrint('Failed to start payment flow: $e');
      _emit(PosToastEffect(message: e.toString(), isError: true));
    }
  }

  Future<void> pushPaymentSelectionFromDialog({
    required ShopInfoModel shop,
    required double total,
  }) async {
    await _sendPaymentSelectionToCustomer(shop, total);
  }

  void _handlePaymentChoiceFromCustomer(PeerMessage message) {
    final payload = message.payload;
    final group = (payload['group'] ?? '') as String? ?? '';
    final code = (payload['code'] ?? '') as String? ?? '';
    final label = (payload['label'] ?? '') as String?;

    final shop = _ref.read(shopInfoProvider);
    final machineCode = _ref.read(machineCodeProvider);
    final result = state.lastOrderResult;
    if (shop == null || machineCode == null || machineCode.isEmpty || result == null) {
      _emit(const PosToastEffect(message: '当前没有可支付的订单', isError: true));
      return;
    }
    dismissPosDialog();
    // close any open dialogs/routes (UI layer handles actual pop)
    _emit(const PosPopToRootEffect());

    try {
      final posInfo = _ref.read(appSettingsSnapshotProvider)?.posTerminal;
      final args = _buildPaymentFlowArgsUseCase.execute(
        order: result,
        shop: shop,
        machineCode: machineCode,
        group: group,
        code: code,
        label: label,
        posInfo: posInfo,
      );
      state = state.copyWith(cart: []);
      _emit(PosNavigateEffect(location: '/payment', extra: args));
    } catch (e) {
      debugPrint('Failed to start payment from customer choice: $e');
      _emit(PosToastEffect(message: e.toString(), isError: true));
    }
  }

  void handlePeerMessage(PeerLinkState next, PeerLinkState? prev) {
    if (next.messageSeq == _lastPeerMessageSeq) return;
    _lastPeerMessageSeq = next.messageSeq;
    final msg = next.lastMessage;
    if (msg == null) return;
    if (msg.type == 'payment_choice') {
      _handlePaymentChoiceFromCustomer(msg);
    }
  }

  Map<String, Map<String, int>> buildInitialOptionSelection(
    Product product, {
    required CartItem? existing,
  }) {
    final selected = <String, Map<String, int>>{};
    if (existing != null) {
      for (final o in existing.options) {
        selected.putIfAbsent(o.groupCode, () => <String, int>{})[o.optionCode] = o.quantity;
      }
      return selected;
    }

    for (final g in product.optionGroups) {
      final defaults = g.options.where((o) => o.isDefault).toList();
      if (defaults.isEmpty) continue;
      final map = <String, int>{};
      for (final d in defaults) {
        map[d.code] = 1;
      }
      selected[g.groupCode] = map;
    }
    return selected;
  }

  List<String> validateMissingOptionGroups(
    Product product,
    Map<String, Map<String, int>> selected,
  ) {
    final missingGroups = <String>[];
    for (final g in product.optionGroups) {
      final map = selected[g.groupCode] ?? const {};
      final total = map.values.fold(0, (p, e) => p + e);
      if (g.minSelect > 0 && total < g.minSelect) {
        missingGroups.add('${g.groupName}(至少${g.minSelect})');
      }
    }
    return missingGroups;
  }

  List<SelectedOption> buildSelectedOptions(
    Product product,
    Map<String, Map<String, int>> selected,
  ) {
    final selectedOptions = <SelectedOption>[];
    for (final g in product.optionGroups) {
      final map = selected[g.groupCode] ?? const {};
      map.forEach((code, qty) {
        final opt = g.options.firstWhere((o) => o.code == code);
        selectedOptions.add(
          SelectedOption(
            groupCode: g.groupCode,
            groupName: g.groupName,
            optionCode: opt.code,
            optionName: opt.name,
            extraPrice: opt.extraPrice,
            quantity: qty,
          ),
        );
      });
    }
    return selectedOptions;
  }

  Future<void> pushSelectedOptionsToCustomer({
    required Product product,
    required List<SelectedOption> options,
  }) async {
    await _sendOptionsToCustomer(product: product, options: options);
  }

  Future<void> pushOptionGroupToCustomer({
    required Product product,
    required OptionGroupEntity group,
    required Map<String, int> selected,
  }) async {
    await _sendOptionGroupToCustomer(product: product, group: group, selected: selected);
  }

  @override
  void dispose() {
    _effects.close();
    super.dispose();
  }
}
