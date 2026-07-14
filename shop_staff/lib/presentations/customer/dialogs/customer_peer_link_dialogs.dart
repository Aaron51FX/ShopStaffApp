import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../peer_link/peer_link.dart';

Future<bool> showCustomerPeerDisconnectedDialog({
  required BuildContext context,
}) async {
  final t = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(t.customerDisconnectTitle),
            content: Text(t.customerDisconnectMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(t.customerReconnect),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(t.customerLater),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<void> showCustomerPeerSearchDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final controller = ref.read(customerPeerLinkControllerProvider.notifier);
  await controller.start();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final t = AppLocalizations.of(context);
          final state = ref.watch(customerPeerLinkControllerProvider);
          final statusLabel = switch (state.status) {
            PeerLinkStatus.connected =>
              '${t.peerStatusConnectedPrefix} ${state.peerName ?? t.peerLabelStaff}',
            PeerLinkStatus.searching => t.customerPeerSearchingStaff,
            PeerLinkStatus.error =>
              '${t.peerStatusErrorPrefix} ${state.lastError ?? t.commonUnknownError}',
            PeerLinkStatus.idle => t.peerStatusIdle,
          };
          final showSpinner =
              state.status == PeerLinkStatus.searching ||
              state.status == PeerLinkStatus.idle;

          return AlertDialog(
            title: Text(t.customerConnectDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSpinner)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                        const SizedBox(width: 12),
                        Text(t.peerSearchInProgress),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 8),
                Text(statusLabel),
                if (state.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.lastError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: controller.restart,
                child: Text(t.peerSearchRestart),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  state.isConnected ? t.peerActionDone : t.peerActionClose,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
