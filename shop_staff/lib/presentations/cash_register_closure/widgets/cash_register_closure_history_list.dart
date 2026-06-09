part of '../pages/cash_register_closure_page.dart';

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.records,
    required this.currency,
    required this.onTap,
  });

  final List<CashRegisterClosureHistoryRecord> records;
  final NumberFormat currency;
  final ValueChanged<CashRegisterClosureHistoryRecord> onTap;

  @override
  Widget build(BuildContext context) {
    return CashRegisterClosurePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '履歴',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('最近一ヶ月の履歴はありません'),
            )
          else
            for (final record in records)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(
                  record.summary.printTime.isNotEmpty
                      ? record.summary.printTime
                      : record.savedAt.toString(),
                ),
                subtitle: Text(record.summary.shopName),
                trailing: Text(currency.format(record.summary.total)),
                onTap: () => onTap(record),
              ),
        ],
      ),
    );
  }
}
