
import 'package:flutter/material.dart';

class OptionGroupContent extends StatelessWidget {
  const OptionGroupContent({required this.payload, super.key});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    //final productName = (payload['productName'] ?? '') as String? ?? '';
    final groupName = (payload['groupName'] ?? '') as String? ?? '';
    final multiple = payload['multiple'] as bool? ?? false;
    final minSelect = (payload['minSelect'] as num?)?.toInt();
    final maxSelect = (payload['maxSelect'] as num?)?.toInt();
    final options = (payload['options'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    final subtitleParts = <String>[];
    subtitleParts.add(multiple ? '可多选' : '单选');
    if (minSelect != null && minSelect > 0) subtitleParts.add('最少$minSelect');
    if (maxSelect != null) subtitleParts.add('最多$maxSelect');
    final subtitle = subtitleParts.join(' · ');

    const accent = Color(0xFF0EA5E9);
    const cardShadow = BoxShadow(
      color: Color(0x22000000),
      blurRadius: 18,
      offset: Offset(0, 12),
    );

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  multiple ? Icons.checklist_rtl_rounded : Icons.list_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // if (productName.isNotEmpty)
              //   Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: accent.withOpacity(0.12),
              //       borderRadius: BorderRadius.circular(12),
              //       border: Border.all(color: accent.withOpacity(0.2)),
              //     ),
              //     child: Text(
              //       productName,
              //       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              //       maxLines: 1,
              //       overflow: TextOverflow.ellipsis,
              //     ),
              //   ),
              // if (productName.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: options.isEmpty
                ? const Center(child: Text('暂无选项'))
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: options.map((opt) {
                        final name = (opt['optionName'] ?? '') as String? ?? '';
                        final selected = opt['selected'] as bool? ?? false;
                        final qty = (opt['quantity'] as num?)?.toInt() ?? 0;
                        final extra = ((opt['extraPrice'] as num?)?.toDouble() ?? 0) * qty;
                        final hasQty = qty > 0;

                        final gradient = selected
                            ? const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF312E81)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.white.withOpacity(0.82), Colors.white.withOpacity(0.66)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              );

                        final borderColor = selected
                            ? Colors.white.withOpacity(0.42)
                            : Colors.black.withOpacity(0.06);

                        return ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: const [cardShadow],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      color: selected ? Colors.white : accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: selected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: selected ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        selected ? '已选' : '未选',
                                        style: TextStyle(
                                          color: selected ? Colors.white : Colors.black54,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (hasQty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: selected ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'x$qty',
                                          style: TextStyle(
                                            color: selected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (extra != 0) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        '+¥${extra.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: selected ? Colors.white : accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}