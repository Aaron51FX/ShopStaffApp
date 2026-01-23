

import 'package:flutter/material.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/entry/viewmodels/peer_link_controller.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.state});

  final PeerLinkState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final staffName = state.peerName ?? t.peerLabelStaff;

    final (icon, title, description, accent, showSpinner) = switch (state.status) {
      PeerLinkStatus.connected => (
          Icons.cloud_done_rounded,
        t.customerStatusConnectedTitle,
        t.customerStatusSyncing(staffName),
          const Color(0xFF22D3EE),
          false),
      PeerLinkStatus.searching => (
          Icons.wifi_tethering_rounded,
        t.customerPeerSearchingStaff,
        t.customerStatusSearchingDescription,
          const Color(0xFFFCD34D),
          true),
      PeerLinkStatus.error => (
          Icons.error_outline_rounded,
        t.customerStatusErrorTitle,
        state.lastError ?? t.customerStatusErrorDescription,
          const Color(0xFFFFA94D),
          false),
      PeerLinkStatus.idle => (
          Icons.link_off_rounded,
        t.peerStatusIdle,
        t.customerStatusIdleDescription,
          Colors.white70,
          false),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showSpinner) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}