import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/shop_info_models.dart';
import '../../../data/providers.dart';
import '../../../domain/services/app_settings_service.dart';
import '../../../domain/services/cash_machine_service.dart';
import '../../../domain/settings/app_settings_models.dart';

enum CashMachineDialogStatus { hidden, checking, success, failure }

@immutable
class CashMachineDialogState {
	const CashMachineDialogState._(this.status, this.message);

	final CashMachineDialogStatus status;
	final String? message;

	const CashMachineDialogState.hidden() : this._(CashMachineDialogStatus.hidden, null);

	const CashMachineDialogState.checking([String? message])
			: this._(CashMachineDialogStatus.checking, message);

	const CashMachineDialogState.success([String? message])
			: this._(CashMachineDialogStatus.success, message);

	const CashMachineDialogState.failure([String? message])
			: this._(CashMachineDialogStatus.failure, message);

	@override
	bool operator ==(Object other) {
		return other is CashMachineDialogState &&
				other.status == status &&
				other.message == message;
	}

	@override
	int get hashCode => Object.hash(status, message);
}

@immutable
class CashMachineCheckState {
	const CashMachineCheckState({
		this.isSupported = false,
		this.isEnabled = false,
		this.isChecking = false,
		this.dialog = const CashMachineDialogState.hidden(),
		this.lastError,
	});

	final bool isSupported;
	final bool isEnabled;
	final bool isChecking;
	final CashMachineDialogState dialog;
	final String? lastError;

	CashMachineCheckState copyWith({
		bool? isSupported,
		bool? isEnabled,
		bool? isChecking,
		CashMachineDialogState? dialog,
		String? lastError,
		bool clearError = false,
	}) {
		return CashMachineCheckState(
			isSupported: isSupported ?? this.isSupported,
			isEnabled: isEnabled ?? this.isEnabled,
			isChecking: isChecking ?? this.isChecking,
			dialog: dialog ?? this.dialog,
			lastError: clearError ? null : (lastError ?? this.lastError),
		);
	}
}

class CashMachineCheckController extends StateNotifier<CashMachineCheckState> {
	CashMachineCheckController(this._ref)
			: _appSettingsService = _ref.read(appSettingsServiceProvider),
				_cashService = _ref.read(cashMachineServiceProvider),
				super(const CashMachineCheckState()) {
		_syncSupport();
		_syncEnabled();
	}

	final Ref _ref;
	final AppSettingsService _appSettingsService;
	final CashMachineService _cashService;
	bool _autoPrompted = false;
	bool _dialogSuppressed = false;

	void onSettingsChanged(AppSettingsSnapshot? snapshot) {
		final enabled = snapshot?.basic.cashMachineEnabled ?? false;
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
		if (state.isSupported && !state.isEnabled) {
			start(auto: true);
		}
	}

	Future<void> start({bool auto = false}) async {
		if (!state.isSupported || state.isChecking) return;
		_dialogSuppressed = false;
		final message = auto ? '正在检测现金机状态…' : '正在重新检测现金机…';
		state = state.copyWith(
			isChecking: true,
			dialog: CashMachineDialogState.checking(message),
			clearError: true,
		);
		try {
			final result = await _cashService.initialize();
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
							: CashMachineDialogState.failure(result.message ?? '检测失败，请检查设备连接'),
					isEnabled: false,
					lastError: result.message ?? '检测失败',
				);
			}
		} catch (e) {
			await _persistEnabled(false);
			state = state.copyWith(
				isChecking: false,
				dialog: _dialogSuppressed
						? const CashMachineDialogState.hidden()
						: CashMachineDialogState.failure('检测发生异常: $e'),
				isEnabled: false,
				lastError: '检测发生异常: $e',
			);
		}
	}

	void skip() {
		_dialogSuppressed = true;
		state = state.copyWith(
			dialog: const CashMachineDialogState.hidden(),
			isChecking: false,
		);
	}

	void dismissDialog() {
		state = state.copyWith(dialog: const CashMachineDialogState.hidden());
	}

	Future<void> _persistEnabled(bool enabled) async {
		final snapshot = _ref.read(appSettingsSnapshotProvider);
		final currentBasic = snapshot?.basic ?? const BasicSettings();
		if (currentBasic.cashMachineEnabled == enabled && snapshot != null) {
			return;
		}
		final updatedBasic = currentBasic.copyWith(cashMachineEnabled: enabled);
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
		// 若门店信息未加载，则默认支持现金，后续可根据能力标记调整。
		if (info == null) {
			return true;
		}
		// TODO: 根据门店授权字段决定是否启用现金支付。
		return true;
	}
}

final cashMachineCheckControllerProvider =
		StateNotifierProvider<CashMachineCheckController, CashMachineCheckState>((ref) {
			final controller = CashMachineCheckController(ref);
			ref.listen<AppSettingsSnapshot?>(appSettingsSnapshotProvider, (_, next) {
				controller.onSettingsChanged(next);
			});
			ref.listen<ShopInfoModel?>(shopInfoProvider, (_, next) {
				controller.onShopInfoChanged(next);
			});
			return controller;
		});
