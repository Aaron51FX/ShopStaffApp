import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/application/pos/usecases/fetch_categories_usecase.dart';
import 'package:shop_staff/application/pos/usecases/fetch_category_products_usecase.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/repositories/menu_repository.dart';
import 'package:shop_staff/presentations/pos/catalog/controllers/pos_catalog_controller.dart';

void main() {
  test('loads one category at a time and filters its products', () async {
    final repository = _MenuRepository();
    final controller = PosCatalogController(
      fetchCategories: FetchCategoriesUseCase(menuRepository: repository),
      fetchProducts: FetchCategoryProductsUseCase(menuRepository: repository),
      readMachineCode: () => 'M01',
      readLanguage: () => 'ja',
      readTakeout: () => false,
    );

    await controller.load();
    controller.search('Tea');

    expect(controller.state.categories, hasLength(2));
    expect(controller.state.currentCategory, 'drink');
    expect(controller.state.products.map((product) => product.name), ['Tea']);
    expect(repository.requestedCategories, ['drink']);
  });
}

class _MenuRepository implements MenuRepository {
  final List<String> requestedCategories = [];

  @override
  Future<List<CategoryModel>> fetchCategories({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
  }) async {
    return const [
      CategoryModel(
        categoryCode: 'drink',
        categoryName: 'Drinks',
        showType: 'normal',
      ),
    ];
  }

  @override
  Future<List<Product>> fetchMenuByCategory({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
    required String categoryCode,
  }) async {
    requestedCategories.add(categoryCode);
    return const [
      Product(
        id: 1,
        name: 'Coffee',
        categoryId: 'drink',
        price: 300,
        originalPrice: 300,
        tax: 10,
        imageUrl: '',
      ),
      Product(
        id: 2,
        name: 'Tea',
        categoryId: 'drink',
        price: 250,
        originalPrice: 250,
        tax: 10,
        imageUrl: '',
      ),
    ];
  }

  @override
  Future<List<Product>> fetchFirstPage({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
  }) async => const [];

  @override
  void clearCache() {}
}
