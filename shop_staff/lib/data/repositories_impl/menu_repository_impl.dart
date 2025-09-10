import '../models/shop_info_models.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_models.dart';
import '../datasources/remote/pos_remote_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final PosRemoteDataSource _remote;
  MenuRepositoryImpl(this._remote);

  // Simple cache to avoid repeated parsing in this example.
  List<Product>? _cache;
  List<CategoryModel>? _cachedCategories;

  @override
  Future<List<CategoryModel>> fetchCategories({required String machineCode, String language = 'JP', bool takeout = false}) async {
    if (_cachedCategories != null) return _cachedCategories!;
  final raw = await _remote.fetchCategoriesV2(machineCode: machineCode, language: language, takeout: takeout);
    final list = _parseCategoriesFlexible(raw);
    // 仅在非空时缓存，避免把一次异常/空结果锁死
    if (list.isNotEmpty) {
      _cachedCategories = list;
    }
    return list;
  }

  @override
  Future<List<Product>> fetchCategoriesAndFirstPage({required String machineCode, String language = 'JP', bool takeout = false}) async {
    // 调用与分类相同的接口, 服务端返回 categoryVoList, 每个分类里可能有 menuVoList 代表首批商品
    final raw = await _remote.fetchHomeMenu(machineCode: machineCode, language: language, takeout: takeout);
    final products = <Product>[];
    // 解析分类 (并缓存)
    final catList = _parseCategoriesFlexible(raw);
    if (catList.isNotEmpty) {
      if (_cachedCategories == null && catList.isNotEmpty) {
        _cachedCategories = catList;
      }
      for (final c in catList) {
        for (final item in c.menuVoList) {
          if (item is Map) {
            try {
              final model = MenuItemModel.fromJson(Map<String, dynamic>.from(item.cast<String, dynamic>()));
              products.add(_toEntity(model));
            } catch (_) {
              // swallow a single malformed item
            }
          }
        }
      }
    } else if (raw is List) {
      // 兼容: 接口直接返回商品数组
      final models = parseMenuItems(raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      products.addAll(models.map(_toEntity));
    }
    _cache = products;
    return products;
  }

  @override
  Future<List<Product>> fetchMenuByCategory(String categoryCode) async {
    if (_cache != null) {
      return _cache!.where((p) => p.categoryId == categoryCode).toList();
    }
    // Fallback to remote category fetch; expecting a list
    final raw = await _remote.fetchMenuByCategoryV2(categoryCode);
    if (raw is List) {
      final models = parseMenuItems(raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      return models.map(_toEntity).toList();
    }
    return [];
  }

  Product _toEntity(MenuItemModel m) => Product(
        id: int.tryParse(m.menuCode) ?? m.menuCode.hashCode,
        name: m.mainTitle,
        categoryId: m.categoryCode,
  price: m.currentPrice.toDouble(),
  originalPrice: m.price.toDouble(),
  tax: m.tax,
        imageUrl: m.homeImage ?? '',
        optionGroups: m.optionGroupVoList.map(_mapGroup).toList(),
      );

  OptionGroupEntity _mapGroup(OptionGroupModel g) => OptionGroupEntity(
        groupCode: g.groupCode,
        groupName: g.groupName,
        multiple: g.multipleState != 1, // assumption: 1 single, else multi
        minSelect: g.smallest,
        maxSelect: null,
        options: g.optionVoList.map(_mapOption).toList(),
      );

  OptionChoiceEntity _mapOption(OptionVoModel o) => OptionChoiceEntity(
        code: o.optionCode,
        name: o.mainTitle,
        extraPrice: (o.currentPrice ?? o.price ?? 0).toDouble(),
        isDefault: o.standard == 1,
      );

  // --- Flexible parsing helpers ---
  List<CategoryModel> _parseCategoriesFlexible(dynamic raw) {
    try {
      final extracted = _extractCategoryArray(raw);
      if (extracted == null) {
        // ignore: avoid_print
        print('[MenuRepo] No category array found in raw response type=${raw.runtimeType}');
        return const <CategoryModel>[];
      }
      final list = extracted
          .whereType<Map>()
          .map((e) => CategoryModel.fromJsonSafe(Map<String, dynamic>.from(e.cast<String, dynamic>())))
          .toList();
      // ignore: avoid_print
      print('[MenuRepo] Parsed categories count=${list.length}');
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('[MenuRepo] Category parse error: $e');
      return const <CategoryModel>[];
    }
  }

  List<dynamic>? _extractCategoryArray(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      // Direct keys
      for (final key in ['categoryVoList', 'categoryList', 'categories']) {
        final v = raw[key];
        if (v is List) return v;
      }
      // Deep envelope traversal (handle data -> data -> result ...)
      final envelopeKeys = ['data', 'result', 'payload'];
      final seen = <int>{};
      dynamic cursor = raw;
      bool progressed = true;
      while (progressed && cursor is Map<String, dynamic>) {
        progressed = false;
        for (final env in envelopeKeys) {
          final inner = cursor[env];
            if (inner is List) return inner;
            if (inner is Map<String, dynamic>) {
              // Check keys inside
              for (final key in ['categoryVoList', 'categoryList', 'categories']) {
                final v = inner[key];
                if (v is List) return v;
              }
              // move deeper only if map hash not seen to avoid loops
              final h = identityHashCode(inner);
              if (!seen.contains(h)) {
                seen.add(h);
                cursor = inner;
                progressed = true;
                break;
              }
            }
        }
      }
    }
    return null;
  }
}

