part of '../pages/cash_register_closure_detail_page.dart';

class _PaymentPiePanel extends StatelessWidget {
  const _PaymentPiePanel({required this.summary, required this.currency});

  final CashRegisterClosureSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entries = _paymentEntries(summary);
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.amount);
    return CashRegisterClosurePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '決済構成',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty || total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: Text('決済データがありません')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final pie = _PaymentPie(
                  entries: entries,
                  total: total,
                  currency: currency,
                );
                final legend = Column(
                  children: [
                    for (final entry in entries)
                      _PaymentLegendRow(
                        entry: entry,
                        total: total,
                        currency: currency,
                      ),
                  ],
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    children: [
                      Center(child: pie),
                      const SizedBox(height: 18),
                      legend,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    pie,
                    const SizedBox(width: 20),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PaymentPie extends StatelessWidget {
  const _PaymentPie({
    required this.entries,
    required this.total,
    required this.currency,
  });

  final List<_PaymentEntry> entries;
  final int total;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _PaymentPiePainter(entries: entries),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('合計', style: TextStyle(color: AppColors.stone500)),
              const SizedBox(height: 4),
              Text(
                currency.format(total),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentLegendRow extends StatelessWidget {
  const _PaymentLegendRow({
    required this.entry,
    required this.total,
    required this.currency,
  });

  final _PaymentEntry entry;
  final int total;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : entry.amount / total * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: entry.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency.format(entry.amount)),
              Text(
                '${ratio.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.stone500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentPiePainter extends CustomPainter {
  const _PaymentPiePainter({required this.entries});

  final List<_PaymentEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.amount);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = math.min(size.width, size.height) * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;
    for (final entry in entries) {
      final sweep = entry.amount / total * math.pi * 2;
      paint.color = entry.color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PaymentPiePainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

List<_PaymentEntry> _paymentEntries(CashRegisterClosureSummary summary) {
  final otherQr =
      summary.auPayTotal +
      summary.dPayTotal +
      summary.mPayTotal +
      summary.rPayTotal;
  final entries = [
    _PaymentEntry('現金', summary.cashTotal, AppColors.emerald600),
    _PaymentEntry('クレジット', summary.creditCardTotal, const Color(0xFF2563EB)),
    _PaymentEntry('PayPay', summary.payPayTotal, const Color(0xFFDC2626)),
    _PaymentEntry('Alipay', summary.aliPayTotal, const Color(0xFF0891B2)),
    _PaymentEntry('WeChat', summary.wechatTotal, const Color(0xFF16A34A)),
    _PaymentEntry('交通系', summary.trafficTotal, const Color(0xFF7C3AED)),
    _PaymentEntry('その他QR', otherQr, const Color(0xFFF97316)),
  ].where((entry) => entry.amount > 0).toList(growable: false);
  return entries..sort((a, b) => b.amount.compareTo(a.amount));
}

class _PaymentEntry {
  const _PaymentEntry(this.label, this.amount, this.color);

  final String label;
  final int amount;
  final Color color;
}
