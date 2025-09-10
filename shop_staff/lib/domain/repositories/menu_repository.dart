import '../../data/models/shop_info_models.dart';

import '../entities/product.dart';

abstract class MenuRepository {
  Future<List<CategoryModel>> fetchCategories({required String machineCode, String language = 'JP', bool takeout = false});
  // 获取分类并解析返回里的首批商品(与分类请求参数一致)
  Future<List<Product>> fetchCategoriesAndFirstPage({required String machineCode, String language = 'JP', bool takeout = false});
  Future<List<Product>> fetchMenuByCategory(String categoryCode);
}
