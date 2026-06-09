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
            AppLocalizations.of(context).cashRegisterClosureHistoryTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                AppLocalizations.of(context).cashRegisterClosureHistoryEmpty,
              ),
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
