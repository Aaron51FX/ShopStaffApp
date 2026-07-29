part of '../pages/payment_selection_page.dart';

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.args,
    required this.summary,
    required this.formatter,
    required this.submittedOrder,
    required this.submittedTotal,
  });

  final PaymentSelectionPageArgs args;
  final _PaymentSummaryData summary;
  final NumberFormat formatter;
  final OrderSubmissionResult? submittedOrder;
  final double? submittedTotal;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final amount =
        submittedTotal ?? submittedOrder?.total.toDouble() ?? args.total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stone200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.paymentSelectionSummaryTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(amount),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.stone600,
            ),
          ),
          Text(
            t.paymentSelectionAmountDue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 20),
          if (args.tableNumber case final tableNumber?
              when tableNumber.isNotEmpty)
            _SummaryRow(
              label: args.tableNumberText?.isNotEmpty == true
                  ? args.tableNumberText!
                  : t.settlementTableLabel,
              value: tableNumber,
            ),
          if (submittedOrder != null)
            _SummaryRow(
              label: t.paymentOrderIdLabel,
              value: submittedOrder!.orderId,
            ),
          if (args.tableNumber == null || args.tableNumber!.isEmpty)
            _SummaryRow(
              label: t.paymentSelectionOrderNumberLabel,
              value: '#${args.orderNumber}',
            ),
          _SummaryRow(
            label: t.posSubtotalLabel,
            value: formatter.format(summary.subtotal),
          ),
          if (summary.discount > 0)
            _SummaryRow(
              label: t.paymentSelectionDiscountLabel,
              value: '-${formatter.format(summary.discount)}',
            ),
          if (summary.tax10 > 0)
            _SummaryRow(
              label: t.paymentSelectionTax10Label,
              value: formatter.format(summary.tax10),
            ),
          if (summary.tax8 > 0)
            _SummaryRow(
              label: t.paymentSelectionTax8Label,
              value: formatter.format(summary.tax8),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  t.paymentSelectionAmountDue,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stone600,
                  ),
                ),
                const Spacer(),
                Text(
                  formatter.format(amount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
