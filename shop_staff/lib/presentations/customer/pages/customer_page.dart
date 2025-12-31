import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/customer/widgets/cart_content.dart';
import 'package:shop_staff/presentations/customer/widgets/category_content.dart';
import 'package:shop_staff/presentations/customer/widgets/option_group_content.dart';
import 'package:shop_staff/presentations/customer/widgets/options_content.dart';
import 'package:shop_staff/presentations/customer/widgets/payment_selection.dart';
import 'package:shop_staff/presentations/customer/widgets/pill_view.dart';
import 'package:shop_staff/presentations/customer/widgets/product_content_view.dart';
import 'package:shop_staff/presentations/customer/widgets/unknown_content.dart';

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
    final message = linkState.lastMessage;

    return Stack(
      children: [
        Scaffold(
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
                        Pill(label: '顾客端', icon: Icons.tv_rounded),
                        const Spacer(),
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
                    //StatusCard(state: linkState),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'いらっしゃいませ',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 200),
                          
                            ],
                          ),
                        
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        //高斯模糊层 有消息显示
        if (message != null)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.12),
          ),
        ),
        _MessageOverlay(message: message, sequence: linkState.messageSeq),
      ],
    );
  }
}


class _MessageOverlay extends StatelessWidget {
  const _MessageOverlay({required this.message, required this.sequence});

  final PeerMessage? message;
  final int sequence;

  @override
  Widget build(BuildContext context) {
    if (message == null || message?.payload == null) return const SizedBox.shrink();
    final currentKey = ValueKey(sequence);
    //final isOptions = message?.type == 'product_options' || message?.type == 'option_group';
    return Align(
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),//isOptions ? Duration.zero : 
        transitionBuilder: (child, animation) {
          //if (isOptions) return child; // options更新不做动画
          if (child is! _TypedOverlay) return child;
          final type = child.type;
          final isEntering = child.key == currentKey;

          Offset enterOffset;
          Offset exitOffset;

          if (type == 'category_grid' || type == 'cart_snapshot') {
            enterOffset = const Offset(0, 1); // bottom in
            exitOffset = const Offset(0, -1); // keep moving up on exit
          } else if (type == 'product_preview') {
            enterOffset = const Offset(1, 0); // right in
            exitOffset = const Offset(-1, 0); // keep moving left on exit
          } else {
            enterOffset = Offset.zero;
            exitOffset = Offset.zero;
          }

          final tween = isEntering
              ? Tween<Offset>(begin: enterOffset, end: Offset.zero)
              : Tween<Offset>(begin: exitOffset, end: Offset.zero);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: tween.animate(animation),
              child: child,
            ),
          );
        },
        child: _TypedOverlay(
          key: currentKey,
          type: message!.type,
              child: GestureDetector(
                onLongPress: () => ProviderScope.containerOf(context, listen: false)
                    .read(customerPeerLinkControllerProvider.notifier)
                    .clearLocalMessage(),
                child: _OverlayCard(message: message!),
              ),
        ),
      ),
    );
  }
}

class _TypedOverlay extends StatelessWidget {
  const _TypedOverlay({super.key, required this.type, required this.child});

  final String type;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({super.key, required this.message});

  final PeerMessage message;

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (message.type) {
      case 'category_grid':
        content = CategoryGridContent(payload: message.payload);
        break;
      case 'product_preview':
        content = ProductPreviewContent(payload: message.payload);
        break;
      case 'product_options':
        content = OptionsContent(payload: message.payload);
        break;
      case 'option_group':
        content = OptionGroupContent(payload: message.payload);
        break;
      case 'cart_snapshot':
        content = CartContent(payload: message.payload);
        break;
      case 'payment_selection':
        content = PaymentSelectionContent(payload: message.payload);
        break;
      default:
        content = UnknownContent(type: message.type);
    }

    return FractionallySizedBox(
      widthFactor: 0.9,
      heightFactor: 0.9,
      child: Material(
        color: Colors.white.withValues(alpha: 0.0),
        child: Center(
            child: content,
          ),
      ),
    );
  }
}


