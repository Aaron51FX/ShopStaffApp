import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/domain/services/app_settings_service.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/presentations/settings/state/settings_state.dart';

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(
    this._ref, {
    required AppSettingsService appSettingsService,
    required AppSettingsSnapshot? initialSnapshot,
    required ShopInfoModel? initialShopInfo,
    required void Function(AppSettingsSnapshot snapshot) sharedSnapshotUpdater,
  }) : _appSettingsService = appSettingsService,
       _updateSharedSnapshot = sharedSnapshotUpdater,
       super(
         SettingsState(
           snapshot: initialSnapshot ?? const AppSettingsSnapshot(),
           shopInfo: initialShopInfo,
         ),
       );

  final AppSettingsService _appSettingsService;
  final void Function(AppSettingsSnapshot snapshot) _updateSharedSnapshot;
  bool _initialized = false;
  final Ref _ref;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (_shouldBootstrap(state.snapshot)) {
      await refreshSettings();
    }
  }

  bool _shouldBootstrap(AppSettingsSnapshot snapshot) {
    final basic = snapshot.basic;
    final hasBasic = (basic.shopName ?? basic.shopCode)?.isNotEmpty == true;
    final hasPrinters = snapshot.printers.isNotEmpty;
    return !hasBasic && !hasPrinters;
  }

  Future<void> refreshSettings() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final loaded = await _appSettingsService.loadAll();
      state = state.copyWith(snapshot: loaded, loading: false);
      _updateSharedSnapshot(loaded);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        errorType: SettingsErrorType.load,
      );
    }
  }

  void select(SettingsSection section) {
    if (state.selected == section) return;
    state = state.copyWith(selected: section);
  }

  Future<void> saveBasicSettings(BasicSettings basic) async {
    final previousSnapshot = state.snapshot;
    if (mapEquals(previousSnapshot.basic.toJson(), basic.toJson())) {
      return;
    }

    final updatedSnapshot = AppSettingsSnapshot(
      basic: basic,
      posTerminal: previousSnapshot.posTerminal,
      printers: previousSnapshot.printers,
    );

    state = state.copyWith(snapshot: updatedSnapshot, clearError: true);
    _updateSharedSnapshot(updatedSnapshot);

    try {
      await _appSettingsService.saveBasicSettings(basic);
    } catch (e) {
      state = state.copyWith(
        snapshot: previousSnapshot,
        error: e.toString(),
        errorType: SettingsErrorType.saveBasic,
      );
      _updateSharedSnapshot(previousSnapshot);
    }
  }

  void updateSnapshot(AppSettingsSnapshot snapshot) {
    state = state.copyWith(snapshot: snapshot);
  }

  void updateShopInfo(ShopInfoModel? info) {
    state = state.copyWith(shopInfo: info);
  }

  void logout({required String title, required String message}) async {
    final ok = await _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: title, message: message, destructive: true);
    if (ok) {
      try {
        await _ref.read(startupServiceProvider).clear();
        _ref.read(shopInfoProvider.notifier).state = null;
        _ref.read(appSettingsSnapshotProvider.notifier).state = null;
        _ref.read(orderModeSelectionProvider.notifier).state = 'dine_in';
        final router = _ref.read(appRouterProvider);
        router.go('/login');
      } catch (e) {
        debugPrint('Logout failed: $e');
      }
    }
  }

  Future<void> savePosTerminal(PosTerminalSettings settings) async {
    final previousSnapshot = state.snapshot;
    if (previousSnapshot.posTerminal.posIp == settings.posIp &&
        previousSnapshot.posTerminal.posPort == settings.posPort) {
      return;
    }
    final updatedSnapshot = AppSettingsSnapshot(
      basic: previousSnapshot.basic,
      posTerminal: settings,
      printers: previousSnapshot.printers,
    );
    state = state.copyWith(snapshot: updatedSnapshot, clearError: true);
    _updateSharedSnapshot(updatedSnapshot);
    try {
      await _appSettingsService.savePosTerminalSettings(settings);
    } catch (e) {
      state = state.copyWith(
        snapshot: previousSnapshot,
        error: e.toString(),
        errorType: SettingsErrorType.saveNetwork,
      );
      _updateSharedSnapshot(previousSnapshot);
    }
  }

  Future<void> savePrinter(PrinterSettings printer) async {
    final previousSnapshot = state.snapshot;
    final printers = previousSnapshot.printers;
    final index = printers.indexWhere(
      (element) =>
          element.type == printer.type && element.receipt == printer.receipt,
    );
    if (index == -1) {
      return;
    }

    final current = printers[index];
    if (_printerEquals(current, printer)) {
      return;
    }

    final updatedPrinters = [...printers];
    updatedPrinters[index] = printer;

    if (printer.type == 10 && printer.isOn) {
      for (var i = 0; i < updatedPrinters.length; i++) {
        if (i == index) continue;
        final candidate = updatedPrinters[i];
        if (candidate.type == 10 &&
            candidate.receipt != printer.receipt &&
            candidate.isOn) {
          updatedPrinters[i] = candidate.copyWith(isOn: false);
        }
      }
    }

    final updatedSnapshot = AppSettingsSnapshot(
      basic: previousSnapshot.basic,
      posTerminal: previousSnapshot.posTerminal,
      printers: updatedPrinters,
    );

    state = state.copyWith(snapshot: updatedSnapshot, clearError: true);
    _updateSharedSnapshot(updatedSnapshot);

    try {
      await _appSettingsService.savePrinterSettings(updatedPrinters);
    } catch (e) {
      state = state.copyWith(
        snapshot: previousSnapshot,
        error: e.toString(),
        errorType: SettingsErrorType.savePrinter,
      );
      _updateSharedSnapshot(previousSnapshot);
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  bool _printerEquals(PrinterSettings a, PrinterSettings b) {
    return mapEquals(a.toJson(), b.toJson());
  }
}
