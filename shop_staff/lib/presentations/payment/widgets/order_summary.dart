
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key, required this.args});

  final PaymentFlowPageArgs args;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('订单号 ${args.order.orderId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('选择方式: ${args.channelDisplayName ?? args.channelCode}', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Text(formatter.format(args.order.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}