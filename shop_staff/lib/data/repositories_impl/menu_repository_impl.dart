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
  Future<List<CategoryModel>> fetchCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;
    final raw = await _remote.fetchCategoriesV2();
    if (raw is Map<String, dynamic>) {
      final list = (raw['categoryVoList'] as List? ?? [])
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _cachedCategories = list;
      return list;
    }
    if (raw is List) {
      // fallback: endpoint directly returns array
      final list = raw.map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      _cachedCategories = list;
      return list;
    }
    return [];
  }

  @override
  Future<List<Product>> fetchCategoriesAndFirstPage() async {
    // Example: call boot index which returns full menu list (placeholder)
    final raw = await _remote.fetchHomeMenu();
    if (raw is List) {
      final models = parseMenuItems(raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      _cache = models.map(_toEntity).toList();
      return _cache!;
    }
    return [];
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
}

