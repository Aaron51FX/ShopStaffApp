
import 'package:flutter/material.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class UnknownContent extends StatelessWidget {
  const UnknownContent({super.key, required this.type});
  final String type;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Text(t.customerUnknownMessage(type)),
    );
  }
}