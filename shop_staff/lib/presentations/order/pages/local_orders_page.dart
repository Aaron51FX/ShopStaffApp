import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_staff/application/order/usecases/order_reprint_usecase.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/order/dialogs/order_management_dialogs.dart';
import 'package:shop_staff/presentations/order/controllers/order_management_controller.dart';
import 'package:shop_staff/presentations/order/providers/order_management_providers.dart';
import 'package:shop_staff/presentations/order/sections/order_management_detail.dart';
import 'package:shop_staff/presentations/order/sections/order_management_filters.dart';
import 'package:shop_staff/presentations/order/sections/order_management_list.dart';
import 'package:shop_staff/presentations/order/state/order_management_state.dart';
import 'package:shop_staff/presentations/pos/order/providers/pos_order_providers.dart';

class LocalOrdersPage extends ConsumerWidget {
  const LocalOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderManagementControllerProvider);
    final controller = ref.read(orderManagementControllerProvider.notifier);
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.orderHistoryTitle),
        backgroundColor: AppColors.amberPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: t.orderHistoryRefreshTooltip,
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          OrderManagementFilters(
            status: state.status,
            startDate: state.startDate,
            endDate: state.endDate,
            onStatusChanged: controller.setStatus,
            onDateRangeChanged: controller.setDateRange,
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildList(context, state, controller),
                ),
                Expanded(
                  child: OrderManagementDetail(
                    detail: state.detail,
                    loading: state.detailLoading,
                    actionRunning: state.actionOrderId != null,
                    onClose: () => controller.selectOrder(null),
                    onReorder: () => _reorder(context, ref, state.detail),
                    onPrintReceipt: () =>
                        _print(context, ref, state.detail, receipt: true),
                    onPrintKitchen: () =>
                        _print(context, ref, state.detail, receipt: false),
                    onChangePayment: () => _changePayment(context, controller),
                    onCancel: () => _cancel(context, controller, state.detail),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    OrderManagementState state,
    OrderManagementController controller,
  ) {
    final t = AppLocalizations.of(context);
    if (state.loading) return const Center(child: CircularProgressIndicator());
    if (state.error != null && state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.orderHistoryLoadFailed),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.orderHistoryRefreshTooltip),
            ),
          ],
        ),
      );
    }
    return OrderManagementList(
      orders: state.orders,
      selectedOrderId: state.selectedOrderId,
      loadingMore: state.loadingMore,
      hasMore: state.hasMore,
      onSelected: (order) => _select(context, controller, order),
      onLoadMore: controller.loadMore,
    );
  }

  Future<void> _select(
    BuildContext context,
    OrderManagementController controller,
    ManagedOrder order,
  ) async {
    try {
      await controller.selectOrder(order);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(
        context,
        AppLocalizations.of(context).orderHistoryDetailFailed,
      );
    }
  }

  Future<void> _changePayment(
    BuildContext context,
    OrderManagementController controller,
  ) async {
    final channel = await showManagedOrderPaymentDialog(context);
    if (channel == null || !context.mounted) return;
    try {
      await controller.markPaid(channel);
      if (!context.mounted) return;
      _showMessage(
        context,
        AppLocalizations.of(context).orderHistoryActionSuccess,
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.toString());
    }
  }

  Future<void> _cancel(
    BuildContext context,
    OrderManagementController controller,
    ManagedOrderDetail? detail,
  ) async {
    if (detail == null) return;
    final confirmed = await showManagedOrderCancelDialog(context, detail.order);
    if (!confirmed || !context.mounted) return;
    try {
      await controller.cancelSelected();
      if (!context.mounted) return;
      _showMessage(
        context,
        AppLocalizations.of(context).orderHistoryActionSuccess,
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.toString());
    }
  }

  Future<void> _print(
    BuildContext context,
    WidgetRef ref,
    ManagedOrderDetail? detail, {
    required bool receipt,
  }) async {
    if (detail == null) return;
    final useCase = ref.read(orderReprintUseCaseProvider);
    final result = receipt
        ? await useCase.reprintReceiptByOrder(
            orderId: detail.order.orderId,
            amount: detail.order.price,
          )
        : await useCase.reprintKitchenTicketsByOrder(
            orderId: detail.order.orderId,
            amount: detail.order.price,
          );
    if (!context.mounted) return;
    _showMessage(context, result.message);
  }

  void _reorder(
    BuildContext context,
    WidgetRef ref,
    ManagedOrderDetail? detail,
  ) {
    if (detail == null) return;
    final machineCode = ref.read(machineCodeProvider)?.trim() ?? '';
    final language = ref.read(shopLanguageProvider);
    ref
        .read(posOrderControllerProvider.notifier)
        .loadFromLocalOrder(
          detail.toLocalOrder(machineCode: machineCode, language: language),
        );
    context.replace('/pos');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
