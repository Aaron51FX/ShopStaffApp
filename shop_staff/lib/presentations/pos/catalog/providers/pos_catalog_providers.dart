import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/pos/usecases/fetch_categories_usecase.dart';
import 'package:shop_staff/application/pos/usecases/fetch_category_products_usecase.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/presentations/pos/catalog/controllers/pos_catalog_controller.dart';
import 'package:shop_staff/presentations/pos/catalog/state/pos_catalog_state.dart';
import 'package:shop_staff/presentations/pos/order/providers/pos_order_providers.dart';

final posCatalogControllerProvider =
    StateNotifierProvider<PosCatalogController, PosCatalogState>((ref) {
      final controller = PosCatalogController(
        fetchCategories: ref.watch(fetchCategoriesUseCaseProvider),
        fetchProducts: ref.watch(fetchCategoryProductsUseCaseProvider),
        readMachineCode: () => ref.read(machineCodeProvider),
        readLanguage: () => ref.read(shopLanguageProvider),
        readTakeout: () =>
            ref.read(posOrderControllerProvider).orderMode == 'take_out',
      );

      ref.listen<ShopInfoModel?>(shopInfoProvider, (previous, next) {
        if (next != null && previous == null && !controller.hasCategories) {
          unawaited(controller.load());
        }
      });
      ref.listen<String?>(machineCodeProvider, (previous, next) {
        if ((previous == null || previous.isEmpty) &&
            next != null &&
            next.isNotEmpty) {
          unawaited(controller.load());
        }
      });
      ref.listen<String>(
        posOrderControllerProvider.select((state) => state.orderMode),
        (previous, next) {
          if (previous != next) unawaited(controller.load(force: true));
        },
      );
      unawaited(controller.load());
      return controller;
    });
