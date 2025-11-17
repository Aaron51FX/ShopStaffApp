import 'package:logging/logging.dart';

import '../../core/storage/key_value_store.dart';
import '../../domain/services/app_settings_service.dart';
import '../../domain/services/startup_service.dart';
import '../models/shop_info_models.dart';
import '../../domain/repositories/activation_repository.dart';

class StartupServiceImpl implements StartupService {
  StartupServiceImpl({
    required KeyValueStore store,
    required ActivationRepository activationRepository,
    required AppSettingsService appSettingsService,
    required String appVersion,
    Logger? logger,
  })  : _store = store,
        _activationRepository = activationRepository,
        _appSettingsService = appSettingsService,
        _appVersion = appVersion,
        _logger = logger ?? Logger('StartupService');

  final KeyValueStore _store;
  final ActivationRepository _activationRepository;
  final AppSettingsService _appSettingsService;
  final String _appVersion;
  final Logger _logger;

  @override
  Future<StartupResult> activate(String machineCode) async {
    final trimmed = machineCode.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('machineCode must not be empty');
    }

    _logger.fine('Starting activation flow for machineCode=$trimmed');
    final shop = await _activationRepository.activate(
      machineCode: trimmed,
      version: _appVersion,
    );

    final normalizedShop = _normalizeShopInfo(shop, trimmed);
    await _store.write(AppStorageKeys.activationCode, trimmed);

    final settings = await _appSettingsService.loadAll();
    _logger.fine('Loaded settings: basic=${settings.basic.shopName ?? '-'}, printers=${settings.printers.length}');

    return StartupResult(
      shopInfo: normalizedShop,
      settings: settings,
      machineCode: trimmed,
    );
  }

  @override
  Future<StartupResult?> resume() async {
    final existing = await _store.read(AppStorageKeys.activationCode);
    final machineCode = existing?.trim();
    if (machineCode == null || machineCode.isEmpty) {
      return null;
    }
    return activate(machineCode);
  }

  @override
  Future<void> clear() async {
    await _store.delete(AppStorageKeys.activationCode);
    await _appSettingsService.clearAll();
  }

  ShopInfoModel _normalizeShopInfo(ShopInfoModel shop, String machineCode) {
    if (shop.machineCode != null && shop.machineCode!.isNotEmpty) {
      return shop;
    }
    _logger.fine('Shop info missing machineCode, injecting $machineCode');
    return shop.copyWith(machineCode: machineCode);
  }
}
