import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

import '../../../core/router/app_router.dart';
import '../../../core/app_role.dart';
import '../../../data/providers.dart';
import '../../../domain/settings/app_settings_models.dart';
import '../../pos/viewmodels/pos_viewmodel.dart';
import '../viewmodels/entry_viewmodels.dart';
import '../viewmodels/peer_link_controller.dart';
import '../../cash_machine/widgets/cash_machine_check_dialog.dart';

final _clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

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

  Future<void> _showDisconnectDialog() async {
    final t = AppLocalizations.of(context);
    final controller = ref.read(peerLinkControllerProvider.notifier);
    final reconnect = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('顾客端已断开'),
          content: const Text('是否重新搜索并尝试连接顾客端？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('重新连接'),
            ),
          ],
        );
      },
    );
    if (reconnect == true) {
      await controller.restart();
      if (mounted) _showSearchDialog();
    } else {
      await controller.stop();
    }
  }

  Future<void> _showSearchDialog() async {
    final controller = ref.read(peerLinkControllerProvider.notifier);
    await controller.start();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(peerLinkControllerProvider);
            final statusLabel = switch (state.status) {
              PeerLinkStatus.connected => '已连接: ${state.peerName ?? '顾客端'}',
              PeerLinkStatus.searching => '正在搜索附近的顾客端…',
              PeerLinkStatus.error => '连接异常: ${state.lastError ?? '未知错误'}',
              PeerLinkStatus.idle => '未开始连接',
            };
            final showSpinner =
                state.status == PeerLinkStatus.searching ||
                state.status == PeerLinkStatus.idle;
            return AlertDialog(
              title: const Text('连接顾客端'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSpinner)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          SizedBox(width: 12),
                          Text('搜索中…'),
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
                  child: const Text('重启搜索'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(state.isConnected ? '完成' : '关闭'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettingsSnapshot?>(appSettingsSnapshotProvider, (prev, next) {
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
        .watch(_clockProvider)
        .maybeWhen(data: (value) => value, orElse: DateTime.now);
    final linkState = ref.watch(peerLinkControllerProvider);
    final timeText = _formatTime(now);
    final dateText = _formatDate(now);

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
                  _buildTopBar(context, ref, timeText, dateText, linkState, _peerLinkEnabled()),
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 720;
                                final options = [
                                  _EntryOptionButton(
                                    title: t.entryDineInTitle,
                                    subtitle: t.entryDineInSubtitle,
                                    icon: Icons.restaurant_menu_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF22D3EE),
                                        Color(0xFF6366F1),
                                      ],
                                    ),
                                    onTap: () => _startOrder(ref, 'dine_in'),
                                  ),
                                  _EntryOptionButton(
                                    title: t.entryTakeoutTitle,
                                    subtitle: t.entryTakeoutSubtitle,
                                    icon: Icons.shopping_bag_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF97316),
                                        Color(0xFFF43F5E),
                                      ],
                                    ),
                                    onTap: () => _startOrder(ref, 'take_out'),
                                  ),
                                ];
                                if (isNarrow) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      options[0],
                                      const SizedBox(height: 20),
                                      options[1],
                                    ],
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

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    String timeText,
    String dateText,
    PeerLinkState linkState,
    bool peerLinkEnabled,
  ) {
    final router = ref.read(appRouterProvider);
    final t = AppLocalizations.of(context);
    final role = ref.watch(appRoleProvider);
    return Row(
      children: [
        FilledButton.icon(
          onPressed: () => router.push('/pos/suspended'),
          icon: const Icon(Icons.assignment_returned_outlined),
          label: Text(t.entryPickup),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
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
        _CustomerStatusChip(role: role, linkState: linkState, toTouch: _showSearchDialog),
        const SizedBox(width: 12),
        // FilledButton.tonalIcon(
        //   onPressed: _showSearchDialog,
        //   icon: const Icon(Icons.wifi_tethering_rounded),
        //   label: const Text('搜索连接'),
        //   style: FilledButton.styleFrom(
        //     backgroundColor: Colors.white.withValues(alpha: 0.12),
        //     foregroundColor: Colors.white,
        //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        //   ),
        // ),
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

class _EntryOptionButton extends StatelessWidget {
  const _EntryOptionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 26),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              // Text(
              //   subtitle,
              //   style: theme.textTheme.bodyMedium?.copyWith(
              //     color: Colors.white.withValues(alpha: 0.82),
              //   ),
              // ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).entryStartOrder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerStatusChip extends StatelessWidget {
  const _CustomerStatusChip({
    required this.role,
    required this.linkState,
    required this.toTouch,
  });

  final AppRole role;
  final PeerLinkState linkState;
  final VoidCallback toTouch;

  @override
  Widget build(BuildContext context) {
    final connected = linkState.isConnected;
    final color = connected ? const Color(0xFF22D3EE) : const Color(0xFFEF4444);
    final icon = connected ? Icons.sensors_rounded : Icons.sensors_off_rounded;
    final label = connected
        ? '已连接: ${"${role.oppositeLabel} ${linkState.peerName ?? ''}"}'
        : '未连接: ${role.oppositeLabel}';
    return GestureDetector(
      onTap: toTouch,
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

String _formatDate(DateTime now) {
  final weekday = _weekdayLabel(now.weekday);
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}年$month月$day日 · $weekday';
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '星期一';
    case DateTime.tuesday:
      return '星期二';
    case DateTime.wednesday:
      return '星期三';
    case DateTime.thursday:
      return '星期四';
    case DateTime.friday:
      return '星期五';
    case DateTime.saturday:
      return '星期六';
    case DateTime.sunday:
    default:
      return '星期日';
  }
}
