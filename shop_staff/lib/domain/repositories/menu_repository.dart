import '../../data/models/shop_info_models.dart';

import '../entities/product.dart';

abstract class MenuRepository {
  Future<List<CategoryModel>> fetchCategories();
  Future<List<Product>> fetchCategoriesAndFirstPage();
  Future<List<Product>> fetchMenuByCategory(String categoryCode);
}
