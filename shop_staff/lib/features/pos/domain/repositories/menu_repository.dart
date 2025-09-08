import '../entities/product.dart';

abstract class MenuRepository {
  Future<List<Product>> fetchCategoriesAndFirstPage();
  Future<List<Product>> fetchMenuByCategory(String categoryCode);
}
