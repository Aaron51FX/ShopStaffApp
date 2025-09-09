import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';

class ActivationState {
  final String code;
  final bool isLoading;
  final String? error;
  const ActivationState({this.code = '', this.isLoading = false, this.error});
  ActivationState copyWith({String? code, bool? isLoading, String? error}) => ActivationState(
        code: code ?? this.code,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ActivationViewModel extends StateNotifier<ActivationState> {
  final KeyValueStore _store;
  final ActivationRepository _repo;
  final TextEditingController codeController = TextEditingController();
  ActivationViewModel(this._store, this._repo) : super(const ActivationState()) {
    codeController.addListener(() {
      state = state.copyWith(code: codeController.text, error: null);
    });
  }

  Future<void> mockScan() async {
    // TODO integrate real QR scanner
    codeController.text = 'X3V9YPJABVZGAELIZ9';
  }

  Future<void> submit(BuildContext context) async {
    final raw = state.code.trim();
    if (raw.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.activate(raw);
      await _store.write(AppStorageKeys.activationCode, raw);
      if (context.mounted) {
        context.go('/pos');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '激活失败: $e');
      return;
    }
    state = state.copyWith(isLoading: false);
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}

final activationViewModelProvider = StateNotifierProvider<ActivationViewModel, ActivationState>((ref) {
  final store = ref.read(keyValueStoreProvider);
  final repo = ref.read(activationRepositoryProvider);
  return ActivationViewModel(store, repo);
});
