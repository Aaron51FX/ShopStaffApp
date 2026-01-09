import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';

import '../../../data/models/shop_info_models.dart';
import '../../../data/providers.dart';
import '../../../domain/settings/app_settings_models.dart';
import '../../../domain/services/app_settings_service.dart';

enum SettingsSection { systemSettings, machineInfo, businessInfo }

class SettingsState {
  const SettingsState({
    this.selected = SettingsSection.systemSettings,
    this.loading = false,
    this.error,
    this.snapshot = const AppSettingsSnapshot(),
    this.shopInfo,
  });

  final SettingsSection selected;
  final bool loading;
  final String? error;
  final AppSettingsSnapshot snapshot;
  final ShopInfoModel? shopInfo;

  SettingsState copyWith({
    SettingsSection? selected,
    bool? loading,
    String? error,
    bool clearError = false,
    AppSettingsSnapshot? snapshot,
    ShopInfoModel? shopInfo,
  }) {
    return SettingsState(
      selected: selected ?? this.selected,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      snapshot: snapshot ?? this.snapshot,
      shopInfo: shopInfo ?? this.shopInfo,
    );
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel(this._ref, {
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
      state = state.copyWith(loading: false, error: '加载设置失败: $e');
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
        error: '保存基础设置失败: $e',
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

  void logout() async {
    final ok = await _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: '注销', message: '确认要注销吗？', destructive: true);
    if (ok) {
      try {
        // 清空购物车与本地状态
        //state = PosState.initial();
        // // 清理仓库缓存
        // _menuRepository.clearCache();
        // 删除激活码与本地设置
        await _ref.read(startupServiceProvider).clear();
        // 清空全局店铺信息与设置快照
        _ref.read(shopInfoProvider.notifier).state = null;
        _ref.read(appSettingsSnapshotProvider.notifier).state = null;
        _ref.read(orderModeSelectionProvider.notifier).state = 'dine_in';
        // 跳转登录
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
      state = state.copyWith(snapshot: previousSnapshot, error: '保存网络设置失败: $e');
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
        error: '保存打印机设置失败: $e',
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

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
      final service = ref.read(appSettingsServiceProvider);
      void updateShared(AppSettingsSnapshot snapshot) {
        ref.read(appSettingsSnapshotProvider.notifier).state = snapshot;
      }

      final vm = SettingsViewModel(
        ref,
        appSettingsService: service,
        initialSnapshot: ref.read(appSettingsSnapshotProvider),
        initialShopInfo: ref.read(shopInfoProvider),
        sharedSnapshotUpdater: updateShared,
      );

      ref.listen<ShopInfoModel?>(shopInfoProvider, (_, next) {
        vm.updateShopInfo(next);
      });

      ref.listen<AppSettingsSnapshot?>(appSettingsSnapshotProvider, (_, next) {
        if (next != null) {
          vm.updateSnapshot(next);
        }
      });

      return vm;
    });
