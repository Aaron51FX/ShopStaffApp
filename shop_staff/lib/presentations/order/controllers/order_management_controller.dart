import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/domain/repositories/order_management_repository.dart';
import 'package:shop_staff/presentations/order/state/order_management_state.dart';

class OrderManagementController extends StateNotifier<OrderManagementState> {
  OrderManagementController({
    required OrderManagementRepository repository,
    required String Function() readShopCode,
  }) : _repository = repository,
       _readShopCode = readShopCode,
       super(OrderManagementState.initial());

  static const _pageSize = 50;

  final OrderManagementRepository _repository;
  final String Function() _readShopCode;

  Future<void> load() async {
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      error: null,
      page: 1,
      orders: const <ManagedOrder>[],
      selectedOrderId: null,
      detail: null,
      detailLoading: false,
    );
    try {
      final result = await _fetchPage(1);
      state = state.copyWith(
        loading: false,
        orders: result.orders,
        hasMore: result.hasMore,
        page: 1,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(loadingMore: true);
    try {
      final result = await _fetchPage(nextPage);
      state = state.copyWith(
        loadingMore: false,
        orders: [...state.orders, ...result.orders],
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (error) {
      state = state.copyWith(loadingMore: false, error: error.toString());
    }
  }

  Future<void> setStatus(ManagedOrderStatus status) async {
    if (state.status == status) return;
    state = state.copyWith(status: status);
    await load();
  }

  Future<void> setDateRange(DateTimeRange range) async {
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    state = state.copyWith(startDate: start, endDate: end);
    await load();
  }

  Future<void> selectOrder(ManagedOrder? order) async {
    if (order == null) {
      state = state.copyWith(
        selectedOrderId: null,
        detail: null,
        detailLoading: false,
      );
      return;
    }
    state = state.copyWith(
      selectedOrderId: order.orderId,
      detail: null,
      detailLoading: true,
    );
    try {
      final detail = await _repository.fetchOrderDetail(order);
      if (state.selectedOrderId != order.orderId) return;
      state = state.copyWith(detail: detail, detailLoading: false);
    } catch (error) {
      if (state.selectedOrderId != order.orderId) return;
      state = state.copyWith(detailLoading: false, error: error.toString());
      rethrow;
    }
  }

  Future<void> markPaid(String payChannel) async {
    final order = state.detail?.order;
    if (order == null || state.actionOrderId != null) return;
    await _runAction(
      order.orderId,
      () =>
          _repository.markPaid(orderId: order.orderId, payChannel: payChannel),
    );
  }

  Future<void> cancelSelected() async {
    final order = state.detail?.order;
    if (order == null || state.actionOrderId != null) return;
    await _runAction(order.orderId, () {
      if (order.status == ManagedOrderStatus.unpaid) {
        return _repository.cancelUnpaid(order.orderId);
      }
      return _repository.cancelPaid(order);
    });
  }

  Future<void> _runAction(
    String orderId,
    Future<void> Function() action,
  ) async {
    state = state.copyWith(actionOrderId: orderId, error: null);
    try {
      await action();
      state = state.copyWith(actionOrderId: null);
      await load();
    } catch (error) {
      state = state.copyWith(actionOrderId: null, error: error.toString());
      rethrow;
    }
  }

  Future<ManagedOrderPage> _fetchPage(int page) {
    final shopCode = _readShopCode().trim();
    if (shopCode.isEmpty) {
      throw StateError('Shop code is missing');
    }
    return _repository.fetchOrders(
      ManagedOrderQuery(
        shopCode: shopCode,
        status: state.status,
        startDate: state.startDate,
        endDate: state.endDate,
        page: page,
        limit: _pageSize,
      ),
    );
  }
}
