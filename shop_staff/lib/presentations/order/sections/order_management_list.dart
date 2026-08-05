import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class OrderManagementList extends StatelessWidget {
  const OrderManagementList({
    super.key,
    required this.orders,
    required this.selectedOrderId,
    required this.loadingMore,
    required this.hasMore,
    required this.onSelected,
    required this.onLoadMore,
  });

  final List<ManagedOrder> orders;
  final String? selectedOrderId;
  final bool loadingMore;
  final bool hasMore;
  final ValueChanged<ManagedOrder> onSelected;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (orders.isEmpty) return Center(child: Text(t.orderHistoryEmpty));
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore && notification.metrics.extentAfter < 240 && !loadingMore) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        itemCount: orders.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == orders.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = orders[index];
          return _ManagedOrderTile(
            order: order,
            selected: order.orderId == selectedOrderId,
            onTap: () => onSelected(order),
          );
        },
      ),
    );
  }
}

class _ManagedOrderTile extends StatelessWidget {
  const _ManagedOrderTile({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final ManagedOrder order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final createdAt = order.createdAt == null
        ? '-'
        : DateFormat(
            t.orderHistoryDatePatternShort,
            t.localeName,
          ).format(order.createdAt!.toLocal());
    return Material(
      color: selected
          ? AppColors.amberPrimary.withValues(alpha: 0.12)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.amberPrimary : AppColors.stone200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.serialNumber.isEmpty
                          ? _shortId(order.orderId)
                          : order.serialNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: const TextStyle(color: AppColors.stone600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.payChannel.isEmpty || order.payChannel == '0'
                          ? t.orderHistoryPayMethodUnknown
                          : order.payChannel,
                      style: const TextStyle(color: AppColors.stone600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '¥${order.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  String _shortId(String value) {
    if (value.length <= 6) return value;
    return value.substring(value.length - 6);
  }
}
