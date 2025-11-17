import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/shop_info_models.dart';
import '../../../data/providers.dart';
import '../../../domain/settings/app_settings_models.dart';
import '../../../domain/services/app_settings_service.dart';

enum SettingsSection { businessInfo, systemSettings, machineInfo }

extension SettingsSectionLabel on SettingsSection {
	String get title {
		switch (this) {
			case SettingsSection.businessInfo:
				return '营业信息';
			case SettingsSection.systemSettings:
				return '系统设置';
			case SettingsSection.machineInfo:
				return '机器信息';
		}
	}

	String get subtitle {
		switch (this) {
			case SettingsSection.businessInfo:
				return '店铺档案与对外展示信息';
			case SettingsSection.systemSettings:
				return '终端网络与打印配置';
			case SettingsSection.machineInfo:
				return '当前设备与运行环境';
		}
	}
}

class SettingsState {
	const SettingsState({
		this.selected = SettingsSection.businessInfo,
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
	SettingsViewModel({
		required AppSettingsService appSettingsService,
		required AppSettingsSnapshot? initialSnapshot,
		required ShopInfoModel? initialShopInfo,
		required void Function(AppSettingsSnapshot snapshot) sharedSnapshotUpdater,
	})  : _appSettingsService = appSettingsService,
				_updateSharedSnapshot = sharedSnapshotUpdater,
				super(SettingsState(
					snapshot: initialSnapshot ?? const AppSettingsSnapshot(),
					shopInfo: initialShopInfo,
				));

	final AppSettingsService _appSettingsService;
	final void Function(AppSettingsSnapshot snapshot) _updateSharedSnapshot;
	bool _initialized = false;

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
				error: '加载设置失败: $e',
			);
		}
	}

	void select(SettingsSection section) {
		if (state.selected == section) return;
		state = state.copyWith(selected: section);
	}

	void updateSnapshot(AppSettingsSnapshot snapshot) {
		state = state.copyWith(snapshot: snapshot);
	}

	void updateShopInfo(ShopInfoModel? info) {
		state = state.copyWith(shopInfo: info);
	}

	void clearError() {
		if (state.error != null) {
			state = state.copyWith(clearError: true);
		}
	}
}

final settingsViewModelProvider =
		StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
	final service = ref.read(appSettingsServiceProvider);
	void updateShared(AppSettingsSnapshot snapshot) {
		ref.read(appSettingsSnapshotProvider.notifier).state = snapshot;
	}

	final vm = SettingsViewModel(
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
