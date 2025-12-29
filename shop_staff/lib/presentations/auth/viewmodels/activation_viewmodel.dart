import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/services/startup_service.dart';
import '../../../core/app_role.dart';
// shopInfoProviders imported via data/providers.dart already

class ActivationState {
  final String machineCode;
  final bool isLoading;
  final String? error;
  const ActivationState({
    this.machineCode = '',
    this.isLoading = false,
    this.error,
  });
  ActivationState copyWith({
    String? machineCode,
    bool? isLoading,
    String? error,
  }) => ActivationState(
    machineCode: machineCode ?? this.machineCode,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ActivationViewModel extends StateNotifier<ActivationState> {
  final StartupService _startupService;
  final Ref _ref;
  final TextEditingController machineCodeController = TextEditingController();
  ActivationViewModel(this._startupService, this._ref)
    : super(const ActivationState()) {
    machineCodeController.addListener(() {
      state = state.copyWith(
        machineCode: machineCodeController.text,
        error: null,
      );
    });
  }

  Future<void> mockScan() async {
    // TODO integrate real QR scanner for machine code
    machineCodeController.text = '3vYrTAYeWZrW4nzwEY';
  }

  Future<void> submit(BuildContext context) async {
    final mc = state.machineCode.trim();
    if (mc.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('[Activation] submit start machineCode=$mc');
      final result = await _startupService.activate(mc);
      _ref.read(shopInfoProvider.notifier).state = result.shopInfo;
      _ref.read(appSettingsSnapshotProvider.notifier).state = result.settings;
      final role = await _ref.read(appRoleServiceProvider).loadRole();
      _ref.read(appRoleProvider.notifier).state = role;
      debugPrint('[Activation] backend success, writing storage');
      if (context.mounted) {
        debugPrint('[Activation] navigating to role=${role.name}');
        context.go(role == AppRole.customer ? '/customer' : '/entry');
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

final activationViewModelProvider =
    StateNotifierProvider<ActivationViewModel, ActivationState>((ref) {
      final startupService = ref.read(startupServiceProvider);
      return ActivationViewModel(startupService, ref);
    });
