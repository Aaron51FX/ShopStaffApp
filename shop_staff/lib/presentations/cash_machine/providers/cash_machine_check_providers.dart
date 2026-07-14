import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

import '../controllers/cash_machine_check_controller.dart';
import '../state/cash_machine_check_state.dart';

final cashMachineCheckControllerProvider =
    StateNotifierProvider<CashMachineCheckController, CashMachineCheckState>((
      ref,
    ) {
      final controller = CashMachineCheckController(ref);
      ref.listen<AppSettingsSnapshot?>(appSettingsSnapshotProvider, (_, next) {
        controller.onSettingsChanged(next);
      });
      ref.listen<ShopInfoModel?>(shopInfoProvider, (_, next) {
        controller.onShopInfoChanged(next);
      });
      return controller;
    });
