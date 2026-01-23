

import 'package:flutter/material.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class OptionsContent extends StatelessWidget {
  const OptionsContent({required this.payload, super.key});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final name = (payload['name'] ?? '') as String? ?? '';
    final image = (payload['image'] ?? '') as String? ?? '';
    final basePrice = (payload['basePrice'] as num?)?.toDouble() ?? 0;
    final totalPrice = (payload['totalPrice'] as num?)?.toDouble() ?? basePrice;
    final options = (payload['options'] as List?)
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
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: image.isEmpty
                        ? _OptionsImagePlaceholder()
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _OptionsImagePlaceholder(),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${t.customerOptionsBasePricePrefix}¥${basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.customerOptionsSelectedTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: 
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: options.isEmpty
                      ? Center(child: Text(t.optionGroupNoOptions))
                        : ListView.separated(
                            itemCount: options.length,
                            separatorBuilder: (_, __) => const Divider(height: 14),
                            itemBuilder: (context, index) {
                              final opt = options[index];
                              final groupName = (opt['groupName'] ?? '') as String? ?? '';
                              final optName = (opt['optionName'] ?? '') as String? ?? '';
                              final qty = (opt['quantity'] as num?)?.toInt() ?? 1;
                              final extra = (opt['extraPrice'] as num?)?.toDouble() ?? 0;
                              final line = extra * qty;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          optName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                                        ),
                                      ),
                                      Text('x$qty', style: const TextStyle(color: Colors.black, fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text('+¥${line.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0EA5E9))),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(t.customerOptionsTotalLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24)),
                    const Spacer(),
                    Text(
                      '¥${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood_rounded, size: 48, color: Colors.grey.shade400),
    );
  }
}