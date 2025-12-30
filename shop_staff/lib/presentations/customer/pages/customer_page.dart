import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/customer/widgets/pill_view.dart';
import 'package:shop_staff/presentations/customer/widgets/product_content_view.dart';
import 'package:shop_staff/presentations/customer/widgets/status_card.dart';

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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 880),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'いらっしゃいませ',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '店員端でペアリングを完了してから、メニューの閲覧と注文を開始してください。',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Spacer(),
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
    return Align(
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, animation) {
          if (child is! _TypedOverlay) return child;
          final type = child.type;
          final isEntering = child.key == currentKey;
          debugPrint('Overlay transition: type=$type, entering=$isEntering');

          Offset enterOffset;
          Offset exitOffset;

          if (type == 'category_grid') {
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
          child: _OverlayCard(message: message!),
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
        content = _CategoryGridContent(payload: message.payload);
        break;
      case 'product_preview':
        content = ProductPreviewContent(payload: message.payload);
        break;
      default:
        content = _UnknownContent(type: message.type);
    }

    return FractionallySizedBox(
      widthFactor: 0.9,
      heightFactor: 0.9,
      child: Material(
        color: Colors.white.withValues(alpha: 0.0),
        child: GestureDetector(
          onLongPress: () {
          
            
          },
          child: Center(
            child: content,
          ),
        ),
      ),
    );
  }
}

class _CategoryGridContent extends StatelessWidget {
  const _CategoryGridContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final items = (payload['categories'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 18)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: items.length.clamp(0, 12).toInt(),
        itemBuilder: (context, index) {
          final item = items[index];
          final name = (item['name'] ?? '') as String? ?? '';
          final image = (item['image'] ?? '') as String? ?? '';
          return _CategoryCard(name: name, image: image);
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.name, required this.image});

  final String name;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _networkImage(image),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImage(String url) {
    if (url.isEmpty) {
      return _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(icon: Icons.broken_image_outlined),
      ),
    );
  }

  Widget _placeholder({IconData icon = Icons.image_outlined}) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 32, color: Colors.grey.shade400),
      );
}


class _UnknownContent extends StatelessWidget {
  const _UnknownContent({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Text('收到未知消息: $type'),
    );
  }
}


