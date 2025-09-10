import '../entities/product.dart';
import '../repositories/menu_repository.dart';

class GetMenuByCategoryUseCase {
  final MenuRepository repository;
  GetMenuByCategoryUseCase(this.repository);

  Future<List<Product>> call({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
    required String categoryCode,
  }) => repository.fetchMenuByCategory(
        machineCode: machineCode,
        language: language,
        takeout: takeout,
        categoryCode: categoryCode,
      );
}
