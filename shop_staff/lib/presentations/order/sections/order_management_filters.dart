import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class OrderManagementFilters extends StatelessWidget {
  const OrderManagementFilters({
    super.key,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
  });

  final ManagedOrderStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<ManagedOrderStatus> onStatusChanged;
  final ValueChanged<DateTimeRange> onDateRangeChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final formatter = DateFormat('yyyy-MM-dd', t.localeName);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SegmentedButton<ManagedOrderStatus>(
            segments: [
              ButtonSegment(
                value: ManagedOrderStatus.paid,
                label: Text(t.orderHistoryPaid),
                icon: const Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: ManagedOrderStatus.unpaid,
                label: Text(t.orderHistoryUnpaid),
                icon: const Icon(Icons.schedule_outlined),
              ),
              ButtonSegment(
                value: ManagedOrderStatus.canceled,
                label: Text(t.orderHistoryCanceled),
                icon: const Icon(Icons.cancel_outlined),
              ),
            ],
            selected: {status},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onStatusChanged(selection.first);
            },
          ),
          const Spacer(),
          Text(t.orderHistoryDateRange),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              '${formatter.format(startDate)}  —  ${formatter.format(endDate)}',
            ),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: DateTimeRange(start: startDate, end: endDate),
                firstDate: DateTime(2021),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (range != null) onDateRangeChanged(range);
            },
          ),
        ],
      ),
    );
  }
}
