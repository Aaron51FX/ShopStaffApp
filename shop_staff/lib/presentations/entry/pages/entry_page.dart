import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shop_staff/l10n/app_localizations.dart';

import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../cash_machine/cash_machine_check.dart';
import '../../cash_machine/widgets/cash_machine_check_dialog.dart';
import '../../peer_link/peer_link.dart';
import '../../pos/viewmodels/pos_viewmodel.dart';
import '../dialogs/peer_link_dialogs.dart';
import '../providers/entry_providers.dart';
import '../widgets/entry_option_grid.dart';
import '../widgets/entry_top_bar.dart';

class EntryPage extends ConsumerStatefulWidget {
  const EntryPage({super.key});

  @override
  ConsumerState<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends ConsumerState<EntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(cashMachineCheckControllerProvider.notifier)
          .maybePromptOnEntry();
      if (_peerLinkEnabled()) {
        ref.read(peerLinkControllerProvider.notifier).start();
      }
    });
  }

  bool _peerLinkEnabled() {
    final snapshot = ref.read(appSettingsSnapshotProvider);
    return snapshot?.basic.peerLinkEnabled ?? true;
  }

  Future<void> _showDisconnectDialog() {
    return showEntryPeerDisconnectDialog(
      context: context,
      ref: ref,
      onReconnect: _showSearchDialog,
    );
  }

  Future<void> _showSearchDialog() {
    return showEntryPeerSearchDialog(context: context, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettingsSnapshotProvider, (prev, next) {
      final wasEnabled = prev?.basic.peerLinkEnabled ?? true;
      final isEnabled = next?.basic.peerLinkEnabled ?? true;
      if (wasEnabled == isEnabled) return;
      final controller = ref.read(peerLinkControllerProvider.notifier);
      if (isEnabled) {
        controller.start();
      } else {
        controller.stop();
      }
    });

    ref.listen<PeerLinkState>(peerLinkControllerProvider, (prev, next) {
      if (!_peerLinkEnabled()) return;
      final wasConnected = prev?.isConnected ?? false;
      if (wasConnected && !next.isConnected) {
        _showDisconnectDialog();
      }
    });

    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final now = ref
        .watch(entryClockProvider)
        .maybeWhen(data: (value) => value, orElse: DateTime.now);
    final linkState = ref.watch(peerLinkControllerProvider);
    final timeText = _formatTime(now);
    final dateText = _formatDate(now, t);

    return CashMachineDialogPortal(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  EntryTopBar(
                    timeText: timeText,
                    dateText: dateText,
                    linkState: linkState,
                    peerLinkEnabled: _peerLinkEnabled(),
                    onSearchPeer: _showSearchDialog,
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.entryTitle,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.entrySubtitle,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 36),
                            EntryOptionGrid(
                              onDineIn: () => _startOrder(ref, 'dine_in'),
                              onTakeout: () => _startOrder(ref, 'take_out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _startOrder(WidgetRef ref, String mode) {
  ref.read(orderModeSelectionProvider.notifier).state = mode;
  ref.invalidate(posViewModelProvider);
  ref.read(appRouterProvider).push('/pos');
}

String _formatTime(DateTime now) {
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatDate(DateTime now, AppLocalizations t) {
  final formatter = intl.DateFormat(t.entryDatePattern, t.localeName);
  return formatter.format(now);
}
