import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/services/startup_service_impl.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';
import 'package:shop_staff/domain/services/app_settings_service.dart';
import 'package:shop_staff/domain/services/shop_logo_cache.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

void main() {
  test(
    'logout clears account identity and machine but preserves settings',
    () async {
      final storage = _MemoryKeyValueStore();
      final settings = _TrackingAppSettingsService();
      await storage.write(AppStorageKeys.activationCode, 'MACHINE-1');
      await storage.write(AppStorageKeys.staffEmail, 'staff@example.com');
      await storage.write(AppStorageKeys.appRole, 'staff');
      await storage.write(AppStorageKeys.settingsBasic, 'basic-settings');
      await storage.write(AppStorageKeys.settingsPosTerminal, 'pos-settings');
      await storage.write(AppStorageKeys.settingsPrinter, 'printer-settings');
      final service = StartupServiceImpl(
        store: storage,
        activationRepository: _UnusedActivationRepository(),
        appSettingsService: settings,
        shopLogoCache: _UnusedShopLogoCache(),
        appVersion: 'test',
      );

      await service.clear();

      expect(await storage.read(AppStorageKeys.activationCode), isNull);
      expect(
        await storage.read(AppStorageKeys.staffEmail),
        'staff@example.com',
        reason: 'logout must preserve the last email for login prefill',
      );
      expect(await storage.read(AppStorageKeys.appRole), 'staff');
      expect(
        await storage.read(AppStorageKeys.settingsBasic),
        'basic-settings',
      );
      expect(
        await storage.read(AppStorageKeys.settingsPosTerminal),
        'pos-settings',
      );
      expect(
        await storage.read(AppStorageKeys.settingsPrinter),
        'printer-settings',
      );
      expect(settings.clearCalls, 0);
    },
  );
}

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _UnusedActivationRepository implements ActivationRepository {
  @override
  Future<ShopInfoModel> activate({
    required String machineCode,
    required String version,
  }) {
    throw UnimplementedError();
  }
}

class _UnusedShopLogoCache implements ShopLogoCache {
  @override
  Future<CachedShopLogo?> cache(String? imageUrl) {
    throw UnimplementedError();
  }
}

class _TrackingAppSettingsService implements AppSettingsService {
  int clearCalls = 0;

  @override
  Future<void> clearAll() async {
    clearCalls += 1;
  }

  @override
  Future<AppSettingsSnapshot> loadAll() {
    throw UnimplementedError();
  }

  @override
  Future<BasicSettings> loadBasicSettings() {
    throw UnimplementedError();
  }

  @override
  Future<List<PrinterSettings>> loadPrinterSettings() {
    throw UnimplementedError();
  }

  @override
  Future<PosTerminalSettings> loadPosTerminalSettings() {
    throw UnimplementedError();
  }

  @override
  Future<void> saveBasicSettings(BasicSettings settings) {
    throw UnimplementedError();
  }

  @override
  Future<void> savePrinterSettings(List<PrinterSettings> settings) {
    throw UnimplementedError();
  }

  @override
  Future<void> savePosTerminalSettings(PosTerminalSettings settings) {
    throw UnimplementedError();
  }
}
