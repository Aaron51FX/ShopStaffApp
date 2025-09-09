import 'package:shop_staff/data/models/shop_info_models.dart';

import '../repositories/menu_repository.dart';

class FetchCategoriesUseCase {
  final MenuRepository _repo;
  FetchCategoriesUseCase(this._repo);
  Future<List<CategoryModel>> call() => _repo.fetchCategories();
}
