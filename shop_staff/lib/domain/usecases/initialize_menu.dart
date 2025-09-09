import '../entities/product.dart';
import '../repositories/menu_repository.dart';

class InitializeMenuUseCase {
  final MenuRepository repository;
  InitializeMenuUseCase(this.repository);
  Future<List<Product>> call() => repository.fetchCategoriesAndFirstPage();
}
