import 'package:flutter/material.dart';

import '../../../../core/app_role.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../peer_link/peer_link.dart';
import 'widgets/customer_role_pill.dart';

class CustomerHomeSection extends StatelessWidget {
  const CustomerHomeSection({
    required this.role,
    required this.linkState,
    required this.onConnectionPressed,
    required this.onSettingsPressed,
    super.key,
  });

  final AppRole role;
  final PeerLinkState linkState;
  final VoidCallback onConnectionPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isConnected = linkState.isConnected;
    final statusColor = isConnected
        ? const Color(0xFF22D3EE)
        : const Color(0xFFEF4444);
    final statusIcon = isConnected
        ? Icons.sensors_rounded
        : Icons.sensors_off_rounded;
    final peerLabel = role == AppRole.staff
        ? t.peerLabelCustomer
        : t.peerLabelStaff;
    final peerName = linkState.peerName?.trim() ?? '';
    final peerDisplay = peerName.isEmpty ? peerLabel : '$peerLabel $peerName';
    final statusLabel = isConnected
        ? '${t.peerStatusConnectedPrefix} $peerDisplay'
        : '${t.peerStatusDisconnectedPrefix} $peerLabel';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF312E81)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    CustomerRolePill(
                      label: t.customerLabel,
                      icon: Icons.tv_rounded,
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: onConnectionPressed,
                      icon: Icon(statusIcon, color: statusColor),
                      label: Text(statusLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: onSettingsPressed,
                      icon: const Icon(Icons.settings_rounded),
                      tooltip: t.entrySettingsTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.customerGreeting,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
