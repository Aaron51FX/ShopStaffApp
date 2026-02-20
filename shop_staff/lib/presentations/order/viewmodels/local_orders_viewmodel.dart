import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';

import 'local_orders_state.dart';

final localOrdersViewModelProvider =
    StateNotifierProvider.autoDispose<LocalOrdersViewModel, LocalOrdersState>((ref) {
  final vm = LocalOrdersViewModel(
    useCases: ref.read(localOrdersUseCasesProvider),
  );
  vm.load();
  return vm;
});

class LocalOrdersViewModel extends StateNotifier<LocalOrdersState> {
  LocalOrdersViewModel(
    {
    required LocalOrdersUseCases useCases,
  })  : _useCases = useCases,
        super(LocalOrdersState.initial());

  final LocalOrdersUseCases _useCases;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _useCases.loadAll();
      final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(loading: false, orders: sorted, error: null);
    } catch (e) {
      debugPrint('Failed to load local orders: $e');
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setOnlyAbnormal(bool enabled) {
    state = state.copyWith(onlyAbnormal: enabled, clearSelected: true);
  }

  void selectOrder(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      state = state.copyWith(clearSelected: true);
      return;
    }
    state = state.copyWith(selectedOrderId: orderId);
  }

  LocalOrderRecord? get selected {
    final id = state.selectedOrderId;
    if (id == null) return null;
    for (final o in state.orders) {
      if (o.orderId == id) return o;
    }
    return null;
  }

  List<LocalOrderRecord> get filtered {
    final source = state.onlyAbnormal
        ? state.orders.where((o) => o.isAbnormalForceExit).toList()
        : state.orders;
    final q = state.query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((o) => _match(o, q)).toList();
  }

  bool _match(LocalOrderRecord order, String q) {
    if (order.orderId.toLowerCase().contains(q)) return true;
    final total = order.clientTotal.toStringAsFixed(2);
    if (total.contains(q)) return true;
    if (order.payMethod.toLowerCase().contains(q)) return true;
    if ((order.abnormalReason ?? '').toLowerCase().contains(q)) return true;
    if ((order.abnormalSessionId ?? '').toLowerCase().contains(q)) return true;
    for (final item in order.items) {
      if (item.product.name.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  int itemCount(LocalOrderRecord order) {
    return order.items.fold<int>(0, (p, CartItem e) => p + e.quantity);
  }

  String preview(LocalOrderRecord order) {
    final names = <String>[];
    for (final item in order.items) {
      final options = item.options.isEmpty
          ? ''
          : '（${item.options.map((o) => '${o.optionName}${o.quantity > 1 ? 'x${o.quantity}' : ''}').join('、')}）';
      names.add(
        '${item.product.name}$options${item.quantity > 1 ? ' x${item.quantity}' : ''}',
      );
      if (names.length >= 3) break;
    }
    if (order.items.length > 3) names.add('...');
    return names.join('，');
  }
}
