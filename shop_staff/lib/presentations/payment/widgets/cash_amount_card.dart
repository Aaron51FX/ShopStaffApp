
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

class CashAmountCard extends StatelessWidget {
  const CashAmountCard({super.key, required this.state, required this.expectedTotal});

  final PaymentFlowState state;
  final num expectedTotal;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final details = state.currentStatus?.details ?? {};
    final amount = details['amount'] is num ? details['amount'] as num : 0;
    final isFinal = details['isFinal'] == true;
    final amountText = formatter.format(amount);
    final expectedText = formatter.format(expectedTotal);
    final difference = amount - expectedTotal;
    final diffText = difference == 0
        ? '金额已匹配订单金额'
        : difference > 0
            ? '需找零 ${formatter.format(difference)}'
            : '仍差 ${formatter.format(difference.abs())}';
    final label = isFinal ? '已确认现金金额' : '识别中的现金金额';
    final icon = isFinal ? Icons.check_circle_rounded : Icons.attach_money_rounded;
    final color = isFinal ? Colors.green : Colors.blueAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(amountText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('订单金额：$expectedText', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(diffText, style: TextStyle(color: difference > 0 ? Colors.orange : Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}