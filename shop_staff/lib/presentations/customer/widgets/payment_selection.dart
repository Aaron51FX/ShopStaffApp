

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/presentations/entry/viewmodels/peer_link_controller.dart';

class PaymentSelectionContent extends StatelessWidget {
  const PaymentSelectionContent({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final orderNumber = (payload['orderNumber'] as num?)?.toInt() ?? 0;
    final total = (payload['total'] as num?)?.toDouble() ?? 0;
    final options = (payload['options'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    final controller = ProviderScope.containerOf(context, listen: false)
        .read(customerPeerLinkControllerProvider.notifier);

    void sendChoice(Map<String, dynamic> opt) {
      controller.clearLocalMessage();
      controller.sendMessage(
        PeerMessage(
          type: 'payment_choice',
          payload: {
            'group': opt['group'],
            'code': opt['code'],
            'label': opt['label'],
          },
        ),
      );
    }

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
              Text('订单 #$orderNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('应付 ¥${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final label = (opt['label'] ?? '') as String? ?? '';
                final enabled = opt['enabled'] as bool? ?? true;
                IconData icon;
                if (opt['group'] == 'cash') {
                  icon = Icons.attach_money_rounded;
                } else if (opt['group'] == 'qr') {
                  icon = Icons.qr_code_2_rounded;
                } else {
                  icon = Icons.credit_card_rounded;
                }
                return Opacity(
                  opacity: enabled ? 1 : 0.35,
                  child: InkWell(
                    onTap: enabled ? () => sendChoice(opt) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 8)),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 36, color: enabled ? const Color(0xFF0EA5E9) : Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: enabled ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            enabled ? '点击选择' : '暂不可用',
                            style: TextStyle(fontSize: 12, color: enabled ? Colors.grey.shade600 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}