import '../../data/models/shop_info_models.dart';
import '../settings/app_settings_models.dart';

class StartupResult {
  const StartupResult({
    required this.shopInfo,
    required this.settings,
    required this.machineCode,
  });

  final ShopInfoModel shopInfo;
  final AppSettingsSnapshot settings;
  final String machineCode;
}

abstract class StartupService {
  Future<StartupResult> activate(String machineCode);
  Future<StartupResult?> resume();
  Future<void> clear();
}
