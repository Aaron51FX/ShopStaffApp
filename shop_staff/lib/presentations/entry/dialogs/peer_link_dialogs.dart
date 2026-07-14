import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/peer_link/peer_link.dart';

Future<void> showEntryPeerDisconnectDialog({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onReconnect,
}) async {
  final t = AppLocalizations.of(context);
  final controller = ref.read(peerLinkControllerProvider.notifier);
  final reconnect = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(t.entryPeerDisconnectedTitle),
        content: Text(t.entryPeerDisconnectedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.entryPeerReconnect),
          ),
        ],
      );
    },
  );
  if (reconnect == true) {
    await controller.restart();
    onReconnect();
  } else {
    await controller.stop();
  }
}

Future<void> showEntryPeerSearchDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final controller = ref.read(peerLinkControllerProvider.notifier);
  await controller.start();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final t = AppLocalizations.of(context);
          final state = ref.watch(peerLinkControllerProvider);
          final statusLabel = switch (state.status) {
            PeerLinkStatus.connected =>
              '${t.peerStatusConnectedPrefix} ${state.peerName ?? t.peerLabelCustomer}',
            PeerLinkStatus.searching => t.entryPeerSearchingCustomer,
            PeerLinkStatus.error =>
              '${t.peerStatusErrorPrefix} ${state.lastError ?? t.commonUnknownError}',
            PeerLinkStatus.idle => t.peerStatusIdle,
          };
          final showSpinner =
              state.status == PeerLinkStatus.searching ||
              state.status == PeerLinkStatus.idle;
          return AlertDialog(
            title: Text(t.entryPeerConnectDialogTitle),
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
                onPressed: () => controller.restart(),
                child: Text(t.peerSearchRestart),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
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
