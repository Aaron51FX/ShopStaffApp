import 'package:flutter/material.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

import 'entry_option_button.dart';

class EntryOptionGrid extends StatelessWidget {
  const EntryOptionGrid({
    super.key,
    required this.onDineIn,
    required this.onTakeout,
  });

  final VoidCallback onDineIn;
  final VoidCallback onTakeout;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final options = [
          EntryOptionButton(
            title: t.entryDineInTitle,
            subtitle: t.entryDineInSubtitle,
            icon: Icons.restaurant_menu_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFF6366F1)],
            ),
            onTap: onDineIn,
          ),
          EntryOptionButton(
            title: t.entryTakeoutTitle,
            subtitle: t.entryTakeoutSubtitle,
            icon: Icons.shopping_bag_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFF43F5E)],
            ),
            onTap: onTakeout,
          ),
        ];
        if (isNarrow) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [options[0], const SizedBox(height: 20), options[1]],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: options[0]),
            const SizedBox(width: 24),
            Expanded(child: options[1]),
          ],
        );
      },
    );
  }
}
