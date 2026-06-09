part of '../pages/cash_register_closure_detail_page.dart';

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail({
    required this.summary,
    required this.currency,
    required this.isHistory,
  });

  final CashRegisterClosureSummary summary;
  final NumberFormat currency;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClosureHeader(summary: summary),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final sales = _SalesOverview(summary: summary, currency: currency);
            final payments = _PaymentPiePanel(
              summary: summary,
              currency: currency,
            );
            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [sales, const SizedBox(height: 16), payments],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: sales),
                const SizedBox(width: 16),
                Expanded(flex: 10, child: payments),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ClosureHeader extends StatelessWidget {
  const _ClosureHeader({required this.summary});

  final CashRegisterClosureSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopName = summary.shopName.trim().isEmpty ? '-' : summary.shopName;
    final machineCode = summary.machineCode.trim().isEmpty
        ? '-'
        : summary.machineCode;
    return CashRegisterClosurePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.stone600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '機番 $machineCode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.stone500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TimePill(label: '開始', value: summary.startTime),
              const SizedBox(height: 8),
              _TimePill(label: '終了', value: summary.endTime),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.stone500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview({required this.summary, required this.currency});

  final CashRegisterClosureSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final grossBeforeAdjustment =
        summary.total + summary.discountTotal + summary.voucherAmountTotal;
    return CashRegisterClosurePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '売上',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _BigAmount(
            label: '販売額',
            value: currency.format(summary.total),
            helper: '税込 / 税抜 / 税額を含む集計',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CashRegisterClosureMetric(
                label: '税抜',
                value: currency.format(summary.noTaxTotal),
              ),
              CashRegisterClosureMetric(
                label: '税額',
                value: currency.format(summary.taxTotal),
              ),
              CashRegisterClosureMetric(
                label: '税込前',
                value: currency.format(grossBeforeAdjustment),
              ),
              CashRegisterClosureMetric(
                label: '割引',
                value: currency.format(summary.discountTotal),
              ),
              CashRegisterClosureMetric(
                label: '代金券',
                value: currency.format(summary.voucherAmountTotal),
              ),
              CashRegisterClosureMetric(
                label: '販売数量',
                value: '${summary.qty} 点',
              ),
              CashRegisterClosureMetric(
                label: '返金額',
                value: currency.format(summary.repaymentTotal),
              ),
              CashRegisterClosureMetric(
                label: '返金数量',
                value: '${summary.repaymentQty} 点',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigAmount extends StatelessWidget {
  const _BigAmount({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amberPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.stone500,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.stone600,
            ),
          ),
          const SizedBox(height: 6),
          Text(helper, style: const TextStyle(color: AppColors.stone500)),
        ],
      ),
    );
  }
}
