import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';
// shopInfoProviders imported via data/providers.dart already

class ActivationState {
  final String machineCode;
  final bool isLoading;
  final String? error;
  const ActivationState({this.machineCode = '', this.isLoading = false, this.error});
  ActivationState copyWith({String? machineCode, bool? isLoading, String? error}) => ActivationState(
        machineCode: machineCode ?? this.machineCode,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ActivationViewModel extends StateNotifier<ActivationState> {
  final KeyValueStore _store;
  final ActivationRepository _repo;
  final Ref _ref;
  final TextEditingController machineCodeController = TextEditingController();
  // For now we hardcode app version; can be replaced with package_info_plus
  static const String _appVersion = '1.0.0';
  ActivationViewModel(this._store, this._repo, this._ref) : super(const ActivationState()) {
    machineCodeController.addListener(() {
      state = state.copyWith(machineCode: machineCodeController.text, error: null);
    });
  }

  Future<void> mockScan() async {
    // TODO integrate real QR scanner for machine code
    machineCodeController.text = 'X3V9YPJABVZGAELIZ9';
  }

  Future<void> submit(BuildContext context) async {
    final mc = state.machineCode.trim();
    if (mc.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
  debugPrint('[Activation] submit start machineCode=$mc');
  final shop = await _repo.activate(machineCode: mc, version: _appVersion);
  // 先注入
  _ref.read(shopInfoProvider.notifier).state = shop;
  // 如果后端未回 machineCode, 用输入值补齐
  updateShopInfoMachineCode(_ref, mc);
      debugPrint('[Activation] backend success, writing storage');
      // Persist machineCode under existing key for backward compatibility
      await _store.write(AppStorageKeys.activationCode, mc);
      final has = await _store.contains(AppStorageKeys.activationCode);
      debugPrint('[Activation] storage contains=$has');
      if (context.mounted) {
        debugPrint('[Activation] navigating to /pos');
        context.go('/pos');
      }
    } catch (e) {
      debugPrint('[Activation] error: $e');
      state = state.copyWith(isLoading: false, error: '激活失败: $e');
      return;
    }
    state = state.copyWith(isLoading: false);
  }

  @override
  void dispose() {
    machineCodeController.dispose();
    super.dispose();
  }
}

final activationViewModelProvider = StateNotifierProvider<ActivationViewModel, ActivationState>((ref) {
  final store = ref.read(keyValueStoreProvider);
  final repo = ref.read(activationRepositoryProvider);
  return ActivationViewModel(store, repo, ref);
});
