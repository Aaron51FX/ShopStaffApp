import 'package:flutter/material.dart';
import 'package:shop_staff/core/app_role.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/peer_link/peer_link.dart';

class CustomerStatusChip extends StatelessWidget {
  const CustomerStatusChip({
    super.key,
    required this.role,
    required this.linkState,
    required this.onTap,
  });

  final AppRole role;
  final PeerLinkState linkState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final connected = linkState.isConnected;
    final color = connected ? const Color(0xFF22D3EE) : const Color(0xFFEF4444);
    final icon = connected ? Icons.sensors_rounded : Icons.sensors_off_rounded;
    final peerLabel = role == AppRole.staff
        ? t.peerLabelCustomer
        : t.peerLabelStaff;
    final peerName = linkState.peerName?.trim() ?? '';
    final peerDisplay = peerName.isEmpty ? peerLabel : '$peerLabel $peerName';
    final label = connected
        ? '${t.peerStatusConnectedPrefix} $peerDisplay'
        : '${t.peerStatusDisconnectedPrefix} $peerLabel';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
