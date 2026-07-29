import 'package:flutter/material.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

import 'entry_option_button.dart';

class EntryOptionGrid extends StatelessWidget {
  const EntryOptionGrid({
    super.key,
    required this.onDineIn,
    required this.onTakeout,
    required this.onSettlement,
    required this.showDineIn,
    required this.showTakeout,
    required this.showSettlement,
  });

  final VoidCallback onDineIn;
  final VoidCallback onTakeout;
  final VoidCallback onSettlement;
  final bool showDineIn;
  final bool showTakeout;
  final bool showSettlement;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final options = <Widget>[
          if (showDineIn)
            EntryOptionButton(
              title: t.entryDineInTitle,
              subtitle: t.entryDineInSubtitle,
              icon: Icons.restaurant_menu_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFF6366F1)],
              ),
              onTap: onDineIn,
            ),
          if (showTakeout)
            EntryOptionButton(
              title: t.entryTakeoutTitle,
              subtitle: t.entryTakeoutSubtitle,
              icon: Icons.shopping_bag_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFF43F5E)],
              ),
              onTap: onTakeout,
            ),
          if (showSettlement)
            EntryOptionButton(
              title: t.entrySettlementTitle,
              subtitle: t.entrySettlementSubtitle,
              icon: Icons.qr_code,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF0F766E)],
              ),
              actionLabel: t.entryStartSettlement,
              onTap: onSettlement,
            ),
        ];
        if (options.isEmpty) return const SizedBox.shrink();
        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < options.length; index++) ...[
                if (index > 0) const SizedBox(height: 20),
                options[index],
              ],
            ],
          );
        }
        const spacing = 24.0;
        final itemWidth = options.length <= 2
            ? (constraints.maxWidth - spacing) / 2
            : (constraints.maxWidth - spacing * 2) / 3;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < options.length; index++) ...[
              if (index > 0) const SizedBox(width: spacing),
              SizedBox(width: itemWidth, child: options[index]),
            ],
          ],
        );
      },
    );
  }
}
