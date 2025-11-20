import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/repositories/menu_repository.dart';
import 'package:shop_staff/domain/repositories/order_repository.dart'; // ensure type reference
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_viewmodel.dart';
import 'package:shop_staff/presentations/pos/widgets/option_dialog_widgets.dart';
import 'package:shop_staff/presentations/pos/widgets/primary_button.dart';
import 'pos_state.dart';
import 'package:shop_staff/presentations/pos/widgets/payment_selection_dialog.dart';

final orderModeSelectionProvider = StateProvider<String>((ref) => 'dine_in');

final posViewModelProvider = StateNotifierProvider<PosViewModel, PosState>((
  ref,
) {
  final menuRepo = ref.watch(menuRepositoryProvider);
  final initialMode = ref.read(orderModeSelectionProvider);
  final vm = PosViewModel(menuRepo, ref, initialMode: initialMode);
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
  return vm;
});

class PosViewModel extends StateNotifier<PosState> {
  final MenuRepository _menuRepository;
  final Ref _ref;
  bool _bootstrapped = false;
  PosViewModel(this._menuRepository, this._ref, {required String initialMode})
    : super(
        PosState.initial().copyWith(
          orderMode: initialMode == 'take_out' ? 'take_out' : 'dine_in',
        ),
      );
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
      // load suspended orders from local storage (non-blocking for network)
      final local = _ref.read(suspendedOrderLocalDataSourceProvider);
      final loaded = await local.loadAll();
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
      final cats = await _menuRepository.fetchCategories(
        machineCode: machineCode,
        language: language,
        takeout: takeout,
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

  void clearCart() async {
    final ok = await _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: '清空购物车', message: '确认要清空购物车吗？', destructive: true);
    if (ok) {
      state = state.copyWith(cart: []);
    }
  }

  void logout() async {
    final ok = await _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: '注销', message: '确认要注销吗？', destructive: true);
    if (ok) {
      try {
        // 清空购物车与本地状态
        state = PosState.initial();
        // 清理仓库缓存
        _menuRepository.clearCache();
        // 删除激活码与本地设置
        await _ref.read(startupServiceProvider).clear();
        // 清空全局店铺信息与设置快照
        _ref.read(shopInfoProvider.notifier).state = null;
        _ref.read(appSettingsSnapshotProvider.notifier).state = null;
        _ref.read(orderModeSelectionProvider.notifier).state = 'dine_in';
        // 跳转登录
        final router = _ref.read(appRouterProvider);
        router.go('/login');
      } catch (e) {
        debugPrint('Logout failed: $e');
      }
    }
  }

  void navToSuspendedOrder() {
    _ref.read(appRouterProvider).push('/pos/suspended');
  }

  void navToSettings() {
    _ref.read(appRouterProvider).push('/settings');
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
      final cats = await _menuRepository.fetchCategories(
        machineCode: machineCode,
        language: language,
        takeout: takeout,
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

    _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: '挂单', message: '确认要挂单吗？')
        .then((ok) {
          if (ok) {
            final id =
                'S${(state.suspendedCounter + 1).toString().padLeft(3, '0')}';
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
            // persist
            _ref
                .read(suspendedOrderLocalDataSourceProvider)
                .save(suspendedOrder);
          }
        });
  }

  // 取单: 根据挂单 id 恢复
  void resumeSuspended(String id) {
    final list = [...state.suspended];
    final idx = list.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final order = list.removeAt(idx);
    state = state.copyWith(cart: order.items, suspended: list);
    // remove from local
    _ref.read(suspendedOrderLocalDataSourceProvider).delete(id);
  }

  String _generateKey(Product p, List<SelectedOption> options) {
    final sorted = [...options]
      ..sort((a, b) => a.optionCode.compareTo(b.optionCode));
    final optionKey = sorted
        .map((e) => '${e.groupCode}:${e.optionCode}')
        .join('|');
    return '${p.id}-$optionKey';
  }

  // ================= Option Dialog Public APIs =================
  void addProductWithOptions(BuildContext context, Product product) {
    if (!product.isCustomizable) {
      addProduct(product);
      return;
    }
    _openOptionDialog(context, product);
  }

  void editCartItemOptions(BuildContext context, CartItem item) {
    final product = item.product;
    if (!product.isCustomizable) return;
    _openOptionDialog(context, product, existing: item);
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
    final total =
        state.cart.fold<double>(0, (p, e) => p + e.lineTotal) - state.discount;
    try {
      final OrderRepository orderRepo = _ref.read(orderRepositoryProvider);
      final OrderSubmissionResult result = await orderRepo.submitOrder(
        items: state.cart,
        machineCode: machineCode,
        language: language,
        takeout: takeout,
        total: total,
      );
      state = state.copyWith(
        orderNumber: state.orderNumber + 1,
        cart: [],
        lastOrderResult: result,
      );
      debugPrint(
        'Order submitted: ${result.orderId} total=${result.total} tax1=${result.tax1} tax2=${result.tax2}',
      );
      // SimpleToast.successGlobal('下单成功');
      // After successful order, present payment selection dialog
      final shop = _ref.read(shopInfoProvider);
      if (shop != null) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          await showPaymentSelectionDialog(
            context: ctx,
            shop: shop,
            onSelected: (group, code, label) {
              try {
                final args = _buildPaymentArgs(
                  order: result,
                  shop: shop,
                  machineCode: machineCode,
                  group: group,
                  code: code,
                  label: label,
                );
                _ref.read(appRouterProvider).push('/payment', extra: args);
              } catch (e) {
                debugPrint('Failed to start payment flow: $e');
                SimpleToast.errorGlobal(e.toString());
              }
            },
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: '下单失败: $e');
      SimpleToast.errorGlobal('下单失败');
    }
  }

  PaymentFlowPageArgs _buildPaymentArgs({
    required OrderSubmissionResult order,
    required ShopInfoModel shop,
    required String machineCode,
    required String group,
    required String code,
    String? label,
  }) {
    final config = Map<String, dynamic>.from(
      shop.linePayChannelMap ?? const {},
    );
    config['selectedChannel'] = code;

    final posInfo = _ref.read(appSettingsSnapshotProvider)?.posTerminal;

    if (group == PaymentChannels.card) {
      // final dynamic ipValue = config['posIp'] ?? config['ip'];
      // final String ip = ipValue == null ? '' : ipValue.toString().trim();
      // final dynamic portValue = config['posPort'] ?? config['port'];
      // final String portString = portValue == null ? '' : portValue.toString().trim();

      //pos setting from settings
      final String ip = posInfo?.posIp ?? '';
      final int portString = posInfo?.posPort ?? 0;
      config['posIp'] = ip;
      config['posPort'] = portString;

      if (ip.isEmpty) {
        throw StateError('未配置POS终端IP');
      }
      if (portString == 0) {
        throw StateError('未配置POS终端端口');
      }
    }

    final metadata = <String, dynamic>{
      'machineCode': machineCode,
      'shopCode': shop.shopCode,
    };

    return PaymentFlowPageArgs(
      order: order,
      channelGroup: group,
      channelCode: code,
      channelDisplayName: label,
      channelConfig: config.isEmpty ? null : config,
      metadata: metadata,
    );
  }

  // ================= Option Dialog Core =================
  void _openOptionDialog(
    BuildContext context,
    Product product, {
    CartItem? existing,
  }) {
    final Map<String, Map<String, int>> selected = {};
    if (existing != null) {
      for (final o in existing.options) {
        selected.putIfAbsent(o.groupCode, () => <String, int>{})[o.optionCode] =
            o.quantity;
      }
    } else {
      for (final g in product.optionGroups) {
        final defaults = g.options.where((o) => o.isDefault).toList();
        if (defaults.isNotEmpty) {
          final map = <String, int>{};
          for (final d in defaults) {
            map[d.code] = 1;
          }
          selected[g.groupCode] = map;
        }
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'options',
      barrierColor: Colors.black.withAlpha(115),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: Center(
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 520,
                      maxHeight: 640,
                    ),
                    child: Material(
                      color: Colors.white,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.amberPrimary,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                          ),
                          // Body
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              children: [
                                for (final group in product.optionGroups) ...[
                                  OptionGroupWidget(
                                    group: group,
                                    selected:
                                        selected[group.groupCode] ?? const {},
                                    onChanged: (map) {
                                      setState(() {
                                        if (map.isEmpty) {
                                          selected.remove(group.groupCode);
                                        } else {
                                          selected[group.groupCode] = map;
                                        }
                                      });
                                    },
                                    onMaxReached: () {
                                      _ref
                                          .read(
                                            dialogControllerProvider.notifier,
                                          )
                                          .confirm(
                                            title: '已达到最大可选',
                                            message:
                                                '${group.groupName} 已达到最多可选数量',
                                            okText: '知道了',
                                            cancelText: '关闭',
                                          );
                                    },
                                  ),
                                  const Divider(height: 28),
                                ],
                              ],
                            ),
                          ),
                          // Footer
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            decoration: const BoxDecoration(
                              color: AppColors.stone100,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: existing == null ? '确认添加' : '更新',
                                    onTap: () {
                                      final missingGroups = <String>[];
                                      for (final g in product.optionGroups) {
                                        final map =
                                            selected[g.groupCode] ?? const {};
                                        final total = map.values.fold(
                                          0,
                                          (p, e) => p + e,
                                        );
                                        if (g.minSelect > 0 &&
                                            total < g.minSelect) {
                                          missingGroups.add(
                                            '${g.groupName}(至少${g.minSelect})',
                                          );
                                        }
                                      }
                                      if (missingGroups.isNotEmpty) {
                                        _ref
                                            .read(
                                              dialogControllerProvider.notifier,
                                            )
                                            .confirm(
                                              title: '缺少必选项',
                                              message: missingGroups.join('\n'),
                                              okText: '好的',
                                              cancelText: '关闭',
                                            );
                                        return;
                                      }
                                      final selectedOptions =
                                          <SelectedOption>[];
                                      for (final g in product.optionGroups) {
                                        final map =
                                            selected[g.groupCode] ?? const {};
                                        map.forEach((code, qty) {
                                          final opt = g.options.firstWhere(
                                            (o) => o.code == code,
                                          );
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
                                      if (existing != null) {
                                        updateCartItemOptions(
                                          oldId: existing.id,
                                          product: product,
                                          newOptions: selectedOptions,
                                        );
                                      } else {
                                        addProduct(
                                          product,
                                          options: selectedOptions,
                                        );
                                      }
                                      Navigator.of(ctx).pop();
                                    },
                                    color: AppColors.amberPrimary,
                                    textColor: Colors.white,
                                    height: 48,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
