import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class OrderManagementDetail extends StatelessWidget {
  const OrderManagementDetail({
    super.key,
    required this.detail,
    required this.loading,
    required this.actionRunning,
    required this.onClose,
    required this.onReorder,
    required this.onPrintReceipt,
    required this.onPrintKitchen,
    required this.onChangePayment,
    required this.onCancel,
  });

  final ManagedOrderDetail? detail;
  final bool loading;
  final bool actionRunning;
  final VoidCallback onClose;
  final VoidCallback onReorder;
  final VoidCallback onPrintReceipt;
  final VoidCallback onPrintKitchen;
  final VoidCallback onChangePayment;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.stone200)),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(child: Text(t.orderHistorySelectOrder))
          : _buildDetail(context, detail!),
    );
  }

  Widget _buildDetail(BuildContext context, ManagedOrderDetail value) {
    final t = AppLocalizations.of(context);
    final order = value.order;
    final createdAt = order.createdAt == null
        ? '-'
        : DateFormat(
            t.orderHistoryDatePatternLong,
            t.localeName,
          ).format(order.createdAt!.toLocal());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.orderHistoryDetailsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.orderHistoryCloseTooltip,
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _keyValue(t.orderHistoryDetailOrderIdLabel, order.orderId),
              if (order.serialNumber.isNotEmpty)
                _keyValue(t.orderHistorySerialNumberLabel, order.serialNumber),
              _keyValue(t.orderHistoryDetailTimeLabel, createdAt),
              _keyValue(
                t.orderHistoryDetailStatusLabel,
                _statusText(t, order.status),
              ),
              _keyValue(
                t.orderHistoryDetailPayMethodLabel,
                order.payChannel.isEmpty || order.payChannel == '0'
                    ? t.orderHistoryPayMethodUnknown
                    : order.payChannel,
              ),
              _keyValue(
                t.orderHistoryDetailAmountLabel,
                '¥${order.price.toStringAsFixed(0)}',
              ),
              _keyValue(
                t.orderHistoryDetailModeLabel,
                order.takeout ? t.posOrderModeTakeout : t.posOrderModeDineIn,
              ),
              if (order.discount != 0)
                _keyValue(
                  t.orderHistoryDiscountLabel,
                  '¥${order.discount.toStringAsFixed(0)}',
                ),
              if (order.changeAmount != 0)
                _keyValue(
                  t.orderHistoryChangeAmountLabel,
                  '¥${order.changeAmount.toStringAsFixed(0)}',
                ),
              _keyValue(
                t.orderHistoryDetailItemCountLabel,
                '${value.itemCount}',
              ),
              const SizedBox(height: 12),
              Text(
                t.orderHistoryDetailProductsTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...value.lines.map((line) => _lineItem(line)),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _actions(context, order.status),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, ManagedOrderStatus status) {
    final t = AppLocalizations.of(context);
    final buttons = <Widget>[];
    if (status == ManagedOrderStatus.paid) {
      buttons.addAll([
        FilledButton(
          onPressed: actionRunning ? null : onReorder,
          child: Text(t.orderHistoryReorder),
        ),
        OutlinedButton(
          onPressed: actionRunning ? null : onPrintReceipt,
          child: Text(t.orderHistoryPrintReceipt),
        ),
      ]);
    }
    buttons.add(
      OutlinedButton(
        onPressed: actionRunning ? null : onPrintKitchen,
        child: Text(t.orderHistoryPrintKitchen),
      ),
    );
    if (status != ManagedOrderStatus.paid) {
      buttons.add(
        FilledButton.tonal(
          onPressed: actionRunning ? null : onChangePayment,
          child: Text(t.orderHistoryChangePayment),
        ),
      );
    }
    if (status != ManagedOrderStatus.canceled) {
      buttons.add(
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
          onPressed: actionRunning ? null : onCancel,
          child: Text(t.orderHistoryCancel),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionRunning) const LinearProgressIndicator(),
        if (actionRunning) const SizedBox(height: 8),
        ...buttons.expand((button) => [button, const SizedBox(height: 8)]),
      ],
    );
  }

  Widget _lineItem(ManagedOrderLine line) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.stone200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${line.name}  × ${line.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('¥${line.price.toStringAsFixed(0)}'),
            ],
          ),
          ...line.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                '${option.groupName}: ${option.name}${option.quantity > 1 ? ' × ${option.quantity}' : ''}',
                style: const TextStyle(color: AppColors.stone600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.stone600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(AppLocalizations t, ManagedOrderStatus status) {
    return switch (status) {
      ManagedOrderStatus.paid => t.orderHistoryPaid,
      ManagedOrderStatus.unpaid => t.orderHistoryUnpaid,
      ManagedOrderStatus.canceled => t.orderHistoryCanceled,
    };
  }
}
