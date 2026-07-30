import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/presentations/settings/controllers/settings_controller.dart';
import 'package:shop_staff/presentations/settings/state/settings_state.dart';

final currentStaffEmailProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(authTokenStoreProvider).readStaffEmail();
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final service = ref.read(appSettingsServiceProvider);
      void updateShared(AppSettingsSnapshot snapshot) {
        ref.read(appSettingsSnapshotProvider.notifier).state = snapshot;
      }

      final controller = SettingsController(
        ref,
        appSettingsService: service,
        initialSnapshot: ref.read(appSettingsSnapshotProvider),
        initialShopInfo: ref.read(shopInfoProvider),
        sharedSnapshotUpdater: updateShared,
      );

      ref.listen<ShopInfoModel?>(shopInfoProvider, (_, next) {
        controller.updateShopInfo(next);
      });

      ref.listen<AppSettingsSnapshot?>(appSettingsSnapshotProvider, (_, next) {
        if (next != null) {
          controller.updateSnapshot(next);
        }
      });

      return controller;
    });
