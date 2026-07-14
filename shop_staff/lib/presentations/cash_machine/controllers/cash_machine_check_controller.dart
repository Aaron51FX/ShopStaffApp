import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/cash_machine/check_cash_machine_usecase.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/services/app_settings_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

import '../state/cash_machine_check_state.dart';

class CashMachineCheckController extends StateNotifier<CashMachineCheckState> {
  CashMachineCheckController(this._ref)
    : _appSettingsService = _ref.read(appSettingsServiceProvider),
      _checkCashMachine = _ref.read(checkCashMachineUseCaseProvider),
      super(const CashMachineCheckState()) {
    _syncSupport();
    _syncEnabled();
  }

  final Ref _ref;
  final AppSettingsService _appSettingsService;
  final CheckCashMachineUseCase _checkCashMachine;
  bool _autoPrompted = false;
  bool _dialogSuppressed = false;

  void onSettingsChanged(AppSettingsSnapshot? snapshot) {
    final enabled =
        snapshot?.basic.cashMachine.enabled ??
        snapshot?.basic.cashMachineEnabled ??
        false;
    if (state.isEnabled != enabled) {
      state = state.copyWith(isEnabled: enabled);
    }
  }

  void onShopInfoChanged(ShopInfoModel? info) {
    final supports = _determineSupport(info);
    if (state.isSupported != supports) {
      state = state.copyWith(isSupported: supports);
    }
  }

  void maybePromptOnEntry() {
    if (_autoPrompted) return;
    _autoPrompted = true;
    _syncSupport();
    _syncEnabled();
    if (state.isSupported && state.isEnabled) {
      start(auto: true);
    }
  }

  Future<void> start({bool auto = false}) async {
    if (!state.isSupported || !state.isEnabled || state.isChecking) return;
    _dialogSuppressed = false;
    final message = auto ? '正在检测现金机状态…' : '正在重新检测现金机…';
    state = state.copyWith(
      isChecking: true,
      dialog: CashMachineDialogState.checking(message),
      clearError: true,
    );
    try {
      final result = await _checkCashMachine.execute();
      if (result.isReady) {
        await _persistEnabled(true);
        state = state.copyWith(
          isChecking: false,
          dialog: _dialogSuppressed
              ? const CashMachineDialogState.hidden()
              : const CashMachineDialogState.success('现金机正常，可使用现金支付'),
          isEnabled: true,
        );
      } else {
        await _persistEnabled(false);
        state = state.copyWith(
          isChecking: false,
          dialog: _dialogSuppressed
              ? const CashMachineDialogState.hidden()
              : CashMachineDialogState.failure(
                  result.message ?? '检测失败，请检查设备连接',
                ),
          isEnabled: false,
          lastError: result.message ?? '检测失败',
        );
      }
    } catch (error) {
      await _persistEnabled(false);
      state = state.copyWith(
        isChecking: false,
        dialog: _dialogSuppressed
            ? const CashMachineDialogState.hidden()
            : CashMachineDialogState.failure('检测发生异常: $error'),
        isEnabled: false,
        lastError: '检测发生异常: $error',
      );
    }
  }

  void skip() {
    _dialogSuppressed = true;
    state = state.copyWith(
      dialog: const CashMachineDialogState.hidden(),
      isChecking: false,
      isEnabled: state.isEnabled,
    );
  }

  void dismissDialog() {
    state = state.copyWith(dialog: const CashMachineDialogState.hidden());
  }

  Future<void> setEnabled(bool enabled) async {
    _dialogSuppressed = !enabled;
    await _persistEnabled(enabled);
    state = state.copyWith(
      isEnabled: enabled,
      dialog: const CashMachineDialogState.hidden(),
    );
  }

  Future<void> _persistEnabled(bool enabled) async {
    final snapshot = _ref.read(appSettingsSnapshotProvider);
    final currentBasic = snapshot?.basic ?? const BasicSettings();
    final currentCashMachine = currentBasic.cashMachine;
    if (currentBasic.cashMachineEnabled == enabled &&
        currentCashMachine.enabled == enabled &&
        snapshot != null) {
      return;
    }
    final updatedBasic = currentBasic.copyWith(
      cashMachineEnabled: enabled,
      cashMachine: currentCashMachine.copyWith(enabled: enabled),
    );
    final newSnapshot = AppSettingsSnapshot(
      basic: updatedBasic,
      posTerminal: snapshot?.posTerminal ?? const PosTerminalSettings(),
      printers: snapshot?.printers ?? const [],
    );
    _ref.read(appSettingsSnapshotProvider.notifier).state = newSnapshot;
    await _appSettingsService.saveBasicSettings(updatedBasic);
  }

  void _syncSupport() {
    onShopInfoChanged(_ref.read(shopInfoProvider));
  }

  void _syncEnabled() {
    onSettingsChanged(_ref.read(appSettingsSnapshotProvider));
  }

  bool _determineSupport(ShopInfoModel? info) {
    if (info == null) {
      return true;
    }
    return true;
  }
}
