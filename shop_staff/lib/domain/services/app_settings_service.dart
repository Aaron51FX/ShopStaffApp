import '../settings/app_settings_models.dart';

abstract class AppSettingsService {
  Future<BasicSettings> loadBasicSettings();
  Future<void> saveBasicSettings(BasicSettings settings);

  Future<PosTerminalSettings> loadPosTerminalSettings();
  Future<void> savePosTerminalSettings(PosTerminalSettings settings);

  Future<List<PrinterSettings>> loadPrinterSettings();
  Future<void> savePrinterSettings(List<PrinterSettings> settings);

  Future<AppSettingsSnapshot> loadAll();
  Future<void> clearAll();
}
