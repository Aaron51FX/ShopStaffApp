import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/peer_link/peer_link.dart';

import 'customer_status_chip.dart';

class EntryTopBar extends ConsumerWidget {
  const EntryTopBar({
    super.key,
    required this.timeText,
    required this.dateText,
    required this.linkState,
    required this.peerLinkEnabled,
    required this.onSearchPeer,
  });

  final String timeText;
  final String dateText;
  final PeerLinkState linkState;
  final bool peerLinkEnabled;
  final VoidCallback onSearchPeer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(appRouterProvider);
    final t = AppLocalizations.of(context);
    final role = ref.watch(appRoleProvider);
    return Row(
      children: [
        _TopBarButton(
          onPressed: () => router.push('/pos/suspended'),
          icon: Icons.assignment_returned_outlined,
          label: t.entryPickup,
        ),
        const SizedBox(width: 12),
        _TopBarButton(
          onPressed: () => router.push('/orders'),
          icon: Icons.receipt_long_rounded,
          label: t.entryHistoryOrders,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        if (peerLinkEnabled)
          CustomerStatusChip(
            role: role,
            linkState: linkState,
            onTap: onSearchPeer,
          ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: () => router.push('/settings'),
          icon: const Icon(Icons.settings_rounded),
          tooltip: t.entrySettingsTooltip,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
