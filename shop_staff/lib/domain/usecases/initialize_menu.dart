import '../entities/product.dart';
import '../repositories/menu_repository.dart';

class InitializeMenuUseCase {
  final MenuRepository repository;
  InitializeMenuUseCase(this.repository);
  Future<List<Product>> call({required String machineCode, String language = 'JP', bool takeout = false}) {
    return repository.fetchCategoriesAndFirstPage(machineCode: machineCode, language: language, takeout: takeout);
  }
}
