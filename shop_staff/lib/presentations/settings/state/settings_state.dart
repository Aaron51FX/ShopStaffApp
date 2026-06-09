import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

enum SettingsSection { systemSettings, machineInfo, businessInfo }

enum SettingsErrorType { load, saveBasic, saveNetwork, savePrinter }

class SettingsState {
  const SettingsState({
    this.selected = SettingsSection.systemSettings,
    this.loading = false,
    this.error,
    this.errorType,
    this.snapshot = const AppSettingsSnapshot(),
    this.shopInfo,
  });

  final SettingsSection selected;
  final bool loading;
  final String? error;
  final SettingsErrorType? errorType;
  final AppSettingsSnapshot snapshot;
  final ShopInfoModel? shopInfo;

  SettingsState copyWith({
    SettingsSection? selected,
    bool? loading,
    String? error,
    SettingsErrorType? errorType,
    bool clearError = false,
    AppSettingsSnapshot? snapshot,
    ShopInfoModel? shopInfo,
  }) {
    return SettingsState(
      selected: selected ?? this.selected,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      errorType: clearError ? null : (errorType ?? this.errorType),
      snapshot: snapshot ?? this.snapshot,
      shopInfo: shopInfo ?? this.shopInfo,
    );
  }
}
