import 'package:equatable/equatable.dart';

import 'package:shop_staff/domain/entities/local_order_record.dart';

class LocalOrdersState extends Equatable {
  const LocalOrdersState({
    required this.loading,
    required this.error,
    required this.orders,
    required this.query,
    required this.onlyAbnormal,
    required this.selectedOrderId,
  });

  final bool loading;
  final String? error;
  final List<LocalOrderRecord> orders;
  final String query;
  final bool onlyAbnormal;
  final String? selectedOrderId;

  factory LocalOrdersState.initial() {
    return const LocalOrdersState(
      loading: false,
      error: null,
      orders: <LocalOrderRecord>[],
      query: '',
      onlyAbnormal: false,
      selectedOrderId: null,
    );
  }

  LocalOrdersState copyWith({
    bool? loading,
    String? error,
    List<LocalOrderRecord>? orders,
    String? query,
    bool? onlyAbnormal,
    String? selectedOrderId,
    bool clearSelected = false,
  }) {
    return LocalOrdersState(
      loading: loading ?? this.loading,
      error: error,
      orders: orders ?? this.orders,
      query: query ?? this.query,
      onlyAbnormal: onlyAbnormal ?? this.onlyAbnormal,
      selectedOrderId: clearSelected ? null : (selectedOrderId ?? this.selectedOrderId),
    );
  }

  @override
  List<Object?> get props => [loading, error, orders, query, onlyAbnormal, selectedOrderId];
}
