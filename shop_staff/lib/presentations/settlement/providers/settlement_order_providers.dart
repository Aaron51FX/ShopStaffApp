import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/settlement/order_key_parser.dart';
import '../../../data/providers.dart';
import '../../../data/repositories_impl/settlement_order_repository_impl.dart';
import '../../../domain/entities/settlement_order.dart';
import '../../../domain/repositories/settlement_order_repository.dart';

final settlementOrderRepositoryProvider = Provider<SettlementOrderRepository>((
  ref,
) {
  return SettlementOrderRepositoryImpl(ref.watch(posRemoteDataSourceProvider));
});

class SettlementOrderState {
  const SettlementOrderState({
    this.loading = false,
    this.order,
    this.errorCode,
  });

  final bool loading;
  final SettlementOrder? order;
  final String? errorCode;

  SettlementOrderState copyWith({
    bool? loading,
    SettlementOrder? order,
    String? errorCode,
    bool clearOrder = false,
    bool clearError = false,
  }) {
    return SettlementOrderState(
      loading: loading ?? this.loading,
      order: clearOrder ? null : order ?? this.order,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
    );
  }
}

class SettlementOrderController extends StateNotifier<SettlementOrderState> {
  SettlementOrderController({
    required SettlementOrderRepository repository,
    required String? Function() readMachineCode,
    required String Function() readLanguage,
  }) : _repository = repository,
       _readMachineCode = readMachineCode,
       _readLanguage = readLanguage,
       super(const SettlementOrderState());

  final SettlementOrderRepository _repository;
  final String? Function() _readMachineCode;
  final String Function() _readLanguage;
  int _requestGeneration = 0;

  Future<bool> fetch(String scannedValue) async {
    if (state.loading) return false;

    late final String orderKey;
    try {
      orderKey = parseSettlementOrderKey(scannedValue);
    } on FormatException {
      state = state.copyWith(errorCode: 'invalid_code', clearOrder: true);
      return false;
    }

    final machineCode = _readMachineCode()?.trim() ?? '';
    if (machineCode.isEmpty) {
      state = state.copyWith(errorCode: 'machine_code_missing');
      return false;
    }

    final generation = ++_requestGeneration;
    state = state.copyWith(loading: true, clearError: true, clearOrder: true);
    try {
      final order = await _repository.fetchOrder(
        orderKey: orderKey,
        language: _readLanguage(),
        machineCode: machineCode,
      );
      if (generation != _requestGeneration) return false;
      state = SettlementOrderState(order: order);
      return true;
    } catch (_) {
      if (generation != _requestGeneration) return false;
      state = const SettlementOrderState(errorCode: 'request_failed');
      return false;
    }
  }
}

final settlementOrderControllerProvider =
    StateNotifierProvider.autoDispose<
      SettlementOrderController,
      SettlementOrderState
    >((ref) {
      return SettlementOrderController(
        repository: ref.watch(settlementOrderRepositoryProvider),
        readMachineCode: () => ref.read(machineCodeProvider),
        readLanguage: () => ref.read(shopLanguageProvider),
      );
    });
