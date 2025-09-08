import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_models.dart';
import '../datasources/remote/pos_remote_datasource.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return MenuRepositoryImpl(ds);
});

class MenuRepositoryImpl implements MenuRepository {
  final dynamic _remote; // PosRemoteDataSource
  MenuRepositoryImpl(this._remote);

  // Simple cache to avoid repeated parsing in this example.
  List<Product>? _cache;

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
        imageUrl: m.homeImage ?? '',
        optionGroups: [], // mapping of option groups to domain can be added later
      );
}
