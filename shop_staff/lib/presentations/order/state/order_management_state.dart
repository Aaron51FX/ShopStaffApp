import 'package:equatable/equatable.dart';

import 'package:shop_staff/domain/entities/managed_order.dart';

class OrderManagementState extends Equatable {
  const OrderManagementState({
    required this.startDate,
    required this.endDate,
    required this.status,
    this.orders = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.error,
    this.selectedOrderId,
    this.detail,
    this.detailLoading = false,
    this.actionOrderId,
  });

  final DateTime startDate;
  final DateTime endDate;
  final ManagedOrderStatus status;
  final List<ManagedOrder> orders;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final String? selectedOrderId;
  final ManagedOrderDetail? detail;
  final bool detailLoading;
  final String? actionOrderId;

  factory OrderManagementState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return OrderManagementState(
      startDate: today,
      endDate: today,
      status: ManagedOrderStatus.paid,
    );
  }

  static const _unset = Object();

  OrderManagementState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    ManagedOrderStatus? status,
    List<ManagedOrder>? orders,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    Object? error = _unset,
    Object? selectedOrderId = _unset,
    Object? detail = _unset,
    bool? detailLoading,
    Object? actionOrderId = _unset,
  }) {
    return OrderManagementState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: identical(error, _unset) ? this.error : error as String?,
      selectedOrderId: identical(selectedOrderId, _unset)
          ? this.selectedOrderId
          : selectedOrderId as String?,
      detail: identical(detail, _unset)
          ? this.detail
          : detail as ManagedOrderDetail?,
      detailLoading: detailLoading ?? this.detailLoading,
      actionOrderId: identical(actionOrderId, _unset)
          ? this.actionOrderId
          : actionOrderId as String?,
    );
  }

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    status,
    orders,
    loading,
    loadingMore,
    hasMore,
    page,
    error,
    selectedOrderId,
    detail,
    detailLoading,
    actionOrderId,
  ];
}
