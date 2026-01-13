import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/repositories/menu_repository.dart';

final fetchCategoryProductsUseCaseProvider = Provider<FetchCategoryProductsUseCase>((ref) {
  return FetchCategoryProductsUseCase(
    menuRepository: ref.watch(menuRepositoryProvider),
    logger: Logger('FetchCategoryProductsUseCase'),
  );
});

class FetchCategoryProductsInput {
  const FetchCategoryProductsInput({
    required this.machineCode,
    required this.language,
    required this.takeout,
    required this.categoryCode,
  });

  final String machineCode;
  final String language;
  final bool takeout;
  final String categoryCode;
}

class FetchCategoryProductsUseCase {
  FetchCategoryProductsUseCase({
    required MenuRepository menuRepository,
    Logger? logger,
  })  : _menuRepository = menuRepository,
        _logger = logger ?? Logger('FetchCategoryProductsUseCase');

  final MenuRepository _menuRepository;
  final Logger _logger;

  Future<List<Product>> execute(FetchCategoryProductsInput input) async {
    _logger.fine('Fetch products category=${input.categoryCode}');
    return _menuRepository.fetchMenuByCategory(
      machineCode: input.machineCode,
      language: input.language,
      takeout: input.takeout,
      categoryCode: input.categoryCode,
    );
  }
}
