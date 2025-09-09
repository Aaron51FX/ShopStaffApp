import '../entities/product.dart';
import '../repositories/menu_repository.dart';

class GetMenuByCategoryUseCase {
  final MenuRepository repository;
  GetMenuByCategoryUseCase(this.repository);
  Future<List<Product>> call(String categoryCode) => repository.fetchMenuByCategory(categoryCode);
}
