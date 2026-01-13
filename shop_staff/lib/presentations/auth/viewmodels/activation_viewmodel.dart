import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/application/auth/login_flow_usecase.dart';
import 'package:shop_staff/data/providers.dart';
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
  final LoginFlowUseCase _login;
  final Ref _ref;
  final TextEditingController machineCodeController = TextEditingController();
  ActivationViewModel(this._login, this._ref)
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
      final result = await _login.activate(mc);
      _ref.read(shopInfoProvider.notifier).state = result.startup.shopInfo;
      _ref.read(appSettingsSnapshotProvider.notifier).state = result.startup.settings;
      _ref.read(appRoleProvider.notifier).state = result.role;
      debugPrint('[Activation] backend success, writing storage');
      if (context.mounted) {
        debugPrint('[Activation] navigating to role=${result.role.name}');
        context.go(result.role == AppRole.customer ? '/customer' : '/entry');
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
      final login = ref.read(loginFlowUseCaseProvider);
      return ActivationViewModel(login, ref);
    });
