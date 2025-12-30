import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

import '../../../core/app_role.dart';
import '../../../data/providers.dart';
import '../../entry/viewmodels/peer_link_controller.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(customerPeerLinkControllerProvider.notifier).start();
      ref.listen<PeerLinkState>(
        customerPeerLinkControllerProvider,
        (prev, next) {
          final wasConnected = prev?.isConnected ?? false;
          final nowConnected = next.isConnected;
          if (wasConnected && !nowConnected) {
            _showDisconnectedDialog();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    ref.read(customerPeerLinkControllerProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _showDisconnectedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('连接已断开'),
          content: const Text('与店员端的连接已断开，请重新连接。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showSearchDialog();
              },
              child: const Text('重新连接'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('稍后'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSearchDialog() async {
    final controller = ref.read(customerPeerLinkControllerProvider.notifier);
    await controller.start();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer(builder: (context, ref, _) {
          final state = ref.watch(customerPeerLinkControllerProvider);
          final statusLabel = switch (state.status) {
            PeerLinkStatus.connected => '已连接店员端: ${state.peerName ?? '店员端'}',
            PeerLinkStatus.searching => '正在搜索店员端…',
            PeerLinkStatus.error => '连接异常: ${state.lastError ?? '未知错误'}',
            PeerLinkStatus.idle => '未开始连接',
          };
          final showSpinner =
              state.status == PeerLinkStatus.searching || state.status == PeerLinkStatus.idle;
          return AlertDialog(
            title: const Text('连接店员端'),
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
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(appRoleProvider);
    final router = ref.read(appRouterProvider);
    final t = AppLocalizations.of(context);
    final linkState = ref.watch(customerPeerLinkControllerProvider);
    final isConnected = linkState.isConnected;
    final color = isConnected ? const Color(0xFF22D3EE) : const Color(0xFFEF4444);
    final icon = isConnected ? Icons.sensors_rounded : Icons.sensors_off_rounded;
    final label = isConnected
        ? '已连接: ${"${role.oppositeLabel} ${linkState.peerName ?? ''}"}'
        : '未连接: ${role.oppositeLabel}';

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
                    _Pill(label: '顾客端', icon: Icons.tv_rounded),
                    const Spacer(),
                    // _RoleBadge(role: role),
                    // const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _showSearchDialog,
                      icon: Icon(icon, color: color),
                      label: Text(label),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
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
                ),
                const SizedBox(height: 28),
                _StatusCard(state: linkState),
                const SizedBox(height: 28),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '欢迎使用自助点餐屏',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '请在店员端完成配对后开始浏览菜单和下单。',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 18,
                            runSpacing: 18,
                            alignment: WrapAlignment.center,
                            children: [
                              _HighlightCard(
                                icon: Icons.wifi_tethering_rounded,
                                title: '等待连接',
                                description: isConnected
                                    ? '已连接店员端，可开始浏览菜单。'
                                    : '请保持设备靠近店员端，等待连接成功提示。',
                              ),
                              const _HighlightCard(
                                icon: Icons.touch_app_rounded,
                                title: '轻触选品',
                                description: '点击商品卡片查看详情，确认后加入订单。',
                              ),
                              _HighlightCard(
                                icon: isConnected
                                    ? Icons.cloud_done_rounded
                                    : Icons.receipt_long_rounded,
                                title: isConnected ? '实时同步中' : '实时同步',
                                description: isConnected
                                    ? '订单、优惠与支付进度正在同步至店员端。'
                                    : '订单、优惠与支付进度将实时同步至店员端。',
                              ),
                            ],
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final isCustomer = role == AppRole.customer;
    final color = isCustomer ? const Color(0xFF22D3EE) : const Color(0xFFFCD34D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '当前模式: ${role.label}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final PeerLinkState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, title, description, accent, showSpinner) = switch (state.status) {
      PeerLinkStatus.connected => (
          Icons.cloud_done_rounded,
          '已连接店员端',
          '同步中: ${state.peerName ?? '店员端'}',
          const Color(0xFF22D3EE),
          false),
      PeerLinkStatus.searching => (
          Icons.wifi_tethering_rounded,
          '正在搜索店员端…',
          '请确保店员端已打开连接且设备靠近。',
          const Color(0xFFFCD34D),
          true),
      PeerLinkStatus.error => (
          Icons.error_outline_rounded,
          '连接异常',
          state.lastError ?? '请重试或检查网络。',
          const Color(0xFFFFA94D),
          false),
      PeerLinkStatus.idle => (
          Icons.link_off_rounded,
          '未开始连接',
          '点击上方“连接店员端”开始配对。',
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

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
