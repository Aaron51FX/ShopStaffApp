import 'dart:convert';

import 'package:logging/logging.dart';

import '../../core/storage/key_value_store.dart';
import '../../domain/services/app_settings_service.dart';
import '../../domain/settings/app_settings_models.dart';

class KeyValueAppSettingsService implements AppSettingsService {
  KeyValueAppSettingsService(this._store, {Logger? logger})
      : _logger = logger ?? Logger('KeyValueAppSettingsService');

  final KeyValueStore _store;
  final Logger _logger;

  @override
  Future<void> clearAll() async {
    await _store.delete(AppStorageKeys.settingsBasic);
    await _store.delete(AppStorageKeys.settingsPosTerminal);
    await _store.delete(AppStorageKeys.settingsPrinter);
  }

  @override
  Future<AppSettingsSnapshot> loadAll() async {
    final basic = await loadBasicSettings();
    final pos = await loadPosTerminalSettings();
    final printers = await loadPrinterSettings();
    return AppSettingsSnapshot(basic: basic, posTerminal: pos, printers: printers);
  }

  @override
  Future<BasicSettings> loadBasicSettings() async {
    final jsonString = await _store.read(AppStorageKeys.settingsBasic);
    if (jsonString == null || jsonString.isEmpty) {
      return const BasicSettings();
    }
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return BasicSettings.fromJson(map);
    } catch (e, stack) {
      _logger.warning('Failed to parse basic settings', e, stack);
      return const BasicSettings();
    }
  }

  @override
  Future<List<PrinterSettings>> loadPrinterSettings() async {
    final jsonString = await _store.read(AppStorageKeys.settingsPrinter);
    if (jsonString == null || jsonString.isEmpty) {
      return PrinterSettings.defaultProfiles();
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        final printers = decoded
            .whereType<Map<String, dynamic>>()
            .map(PrinterSettings.fromJson)
            .toList();
        return printers.isEmpty ? PrinterSettings.defaultProfiles() : printers;
      }
      if (decoded is Map<String, dynamic>) {
        return [PrinterSettings.fromJson(decoded)];
      }
    } catch (e, stack) {
      _logger.warning('Failed to parse printer settings', e, stack);
    }
    return PrinterSettings.defaultProfiles();
  }

  @override
  Future<PosTerminalSettings> loadPosTerminalSettings() async {
    final jsonString = await _store.read(AppStorageKeys.settingsPosTerminal);
    if (jsonString == null || jsonString.isEmpty) {
      return const PosTerminalSettings();
    }
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return PosTerminalSettings.fromJson(map);
    } catch (e, stack) {
      _logger.warning('Failed to parse POS settings', e, stack);
      return const PosTerminalSettings();
    }
  }

  @override
  Future<void> saveBasicSettings(BasicSettings settings) {
    final payload = jsonEncode(settings.toJson());
    return _store.write(AppStorageKeys.settingsBasic, payload);
  }

  @override
  Future<void> savePosTerminalSettings(PosTerminalSettings settings) {
    final payload = jsonEncode(settings.toJson());
    return _store.write(AppStorageKeys.settingsPosTerminal, payload);
  }

  @override
  Future<void> savePrinterSettings(List<PrinterSettings> settings) {
    final payload = jsonEncode(settings.map((e) => e.toJson()).toList());
    return _store.write(AppStorageKeys.settingsPrinter, payload);
  }
}
