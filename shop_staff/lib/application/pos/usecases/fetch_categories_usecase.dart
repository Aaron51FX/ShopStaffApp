import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/repositories/menu_repository.dart';

final fetchCategoriesUseCaseProvider = Provider<FetchCategoriesUseCase>((ref) {
  return FetchCategoriesUseCase(
    menuRepository: ref.watch(menuRepositoryProvider),
    logger: Logger('FetchCategoriesUseCase'),
  );
});

class FetchCategoriesInput {
  const FetchCategoriesInput({
    required this.machineCode,
    required this.language,
    required this.takeout,
  });

  final String machineCode;
  final String language;
  final bool takeout;
}

class FetchCategoriesUseCase {
  FetchCategoriesUseCase({
    required MenuRepository menuRepository,
    Logger? logger,
  })  : _menuRepository = menuRepository,
        _logger = logger ?? Logger('FetchCategoriesUseCase');

  final MenuRepository _menuRepository;
  final Logger _logger;

  Future<List<CategoryModel>> execute(FetchCategoriesInput input) async {
    _logger.fine('Fetch categories takeout=${input.takeout}');
    final cats = await _menuRepository.fetchCategories(
      machineCode: input.machineCode,
      language: input.language,
      takeout: input.takeout,
    );
    return cats;
  }
}
