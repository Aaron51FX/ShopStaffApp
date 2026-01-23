

import 'package:flutter/material.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class CartContent extends StatelessWidget {
  const CartContent({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final orderNumber = (payload['orderNumber'] as num?)?.toInt() ?? 0;
    final orderMode = (payload['orderMode'] ?? '') as String? ?? '';
    final subtotal = (payload['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (payload['discount'] as num?)?.toDouble() ?? 0;
    final total = (payload['total'] as num?)?.toDouble() ?? 0;
    final items = (payload['items'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.customerOrderNumberTitle(orderNumber), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: orderMode == 'take_out' ? const Color(0xFFFFEDD5) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  orderMode == 'take_out' ? t.posOrderModeTakeout : t.posOrderModeDineIn,
                  style: TextStyle(
                    fontSize: 18,
                    color: orderMode == 'take_out' ? const Color(0xFFF97316) : const Color(0xFF0284C7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(t.posCartEmptyMessage))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = (item['name'] ?? '') as String? ?? '';
                      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
                      final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? 0;
                      final opts = (item['options'] as List?)
                              ?.whereType<Map>()
                              .map((e) => e.cast<String, dynamic>())
                              .toList() ??
                          const [];
                      final optionText = opts.isEmpty
                          ? ''
                          : opts
                              .map((o) {
                                final g = (o['groupName'] ?? '') as String? ?? '';
                                final n = (o['optionName'] ?? '') as String? ?? '';
                                final q = (o['quantity'] as num?)?.toInt() ?? 0;
                                final extra = (o['extraPrice'] as num?)?.toDouble() ?? 0;
                                final extraLabel = extra == 0 ? '' : '+¥${extra.toStringAsFixed(0)}';
                                final qtyLabel = q > 1 ? ' x$q' : '';
                                return '$g: $n$qtyLabel $extraLabel'.trim();
                              })
                              .join(' · ');

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                                if (optionText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(optionText, style: const TextStyle(color: AppColors.stone500, fontSize: 16)),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text('${t.commonUnitPriceLabel} ¥${unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.amberPrimary, fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('x$qty', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                              const SizedBox(height: 6),
                              Text(
                                '¥${lineTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.amberPrimary),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 20),
          _SummaryLine(label: t.posSubtotalLabel, value: subtotal),
          _SummaryLine(label: t.posDiscountLabel, value: -discount, muted: true),
          const SizedBox(height: 6),
          _SummaryLine(label: t.posTotalDueLabel, value: total, emphasized: true),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;
  final bool muted;
  const _SummaryLine({required this.label, required this.value, this.emphasized = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 24 : 18,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
      color: muted ? Colors.grey : null,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(
          '¥${value.toStringAsFixed(2)}',
          style: style.copyWith(color: emphasized ? const Color(0xFFEF4444) : style.color),
        ),
      ],
    );
  }
}