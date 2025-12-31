import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/customer/widgets/pill_view.dart';
import 'package:shop_staff/presentations/customer/widgets/product_content_view.dart';

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
          debugPrint('Overlay transition: type=$type, entering=$isEntering');

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
        content = _CategoryGridContent(payload: message.payload);
        break;
      case 'product_preview':
        content = ProductPreviewContent(payload: message.payload);
        break;
      case 'product_options':
        content = _OptionsContent(payload: message.payload);
        break;
      case 'option_group':
        content = _OptionGroupContent(payload: message.payload);
        break;
      case 'cart_snapshot':
        content = _CartContent(payload: message.payload);
        break;
      case 'payment_selection':
        content = _PaymentSelectionContent(payload: message.payload);
        break;
      default:
        content = _UnknownContent(type: message.type);
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

class _OptionsContent extends StatelessWidget {
  const _OptionsContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final name = (payload['name'] ?? '') as String? ?? '';
    final image = (payload['image'] ?? '') as String? ?? '';
    final basePrice = (payload['basePrice'] as num?)?.toDouble() ?? 0;
    final totalPrice = (payload['totalPrice'] as num?)?.toDouble() ?? basePrice;
    final options = (payload['options'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: image.isEmpty
                        ? _OptionsImagePlaceholder()
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _OptionsImagePlaceholder(),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '基础价 ¥${basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '已选配料',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: options.isEmpty
                        ? const Center(child: Text('暂无选项'))
                        : ListView.separated(
                            itemCount: options.length,
                            separatorBuilder: (_, __) => const Divider(height: 14),
                            itemBuilder: (context, index) {
                              final opt = options[index];
                              final groupName = (opt['groupName'] ?? '') as String? ?? '';
                              final optName = (opt['optionName'] ?? '') as String? ?? '';
                              final qty = (opt['quantity'] as num?)?.toInt() ?? 1;
                              final extra = (opt['extraPrice'] as num?)?.toDouble() ?? 0;
                              final line = extra * qty;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    groupName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          optName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                      ),
                                      Text('x$qty', style: const TextStyle(color: Colors.grey)),
                                      const SizedBox(width: 8),
                                      Text('+¥${line.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0EA5E9))),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('当前总价', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Text(
                      '¥${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionGroupContent extends StatelessWidget {
  const _OptionGroupContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final productName = (payload['productName'] ?? '') as String? ?? '';
    final groupName = (payload['groupName'] ?? '') as String? ?? '';
    final multiple = payload['multiple'] as bool? ?? false;
    final minSelect = (payload['minSelect'] as num?)?.toInt();
    final maxSelect = (payload['maxSelect'] as num?)?.toInt();
    final options = (payload['options'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    final subtitleParts = <String>[];
    if (minSelect != null && minSelect > 0) subtitleParts.add('最少$minSelect');
    if (maxSelect != null) subtitleParts.add('最多$maxSelect');
    subtitleParts.add(multiple ? '可多选' : '单选');
    final subtitle = subtitleParts.join(' · ');

    const accent = Color(0xFF0EA5E9);
    const cardShadow = BoxShadow(
      color: Color(0x22000000),
      blurRadius: 18,
      offset: Offset(0, 12),
    );

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (productName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.2)),
                  ),
                  child: Text(
                    productName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (productName.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: options.isEmpty
                ? const Center(child: Text('暂无选项'))
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: options.map((opt) {
                        final name = (opt['optionName'] ?? '') as String? ?? '';
                        final selected = opt['selected'] as bool? ?? false;
                        final qty = (opt['quantity'] as num?)?.toInt() ?? 0;
                        final extra = (opt['extraPrice'] as num?)?.toDouble() ?? 0;
                        final hasQty = qty > 0;

                        final gradient = selected
                            ? const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF312E81)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.white.withOpacity(0.82), Colors.white.withOpacity(0.66)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              );

                        final borderColor = selected
                            ? Colors.white.withOpacity(0.42)
                            : Colors.black.withOpacity(0.06);

                        return ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: const [cardShadow],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      color: selected ? Colors.white : accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: selected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: selected ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        selected ? '已选' : '未选',
                                        style: TextStyle(
                                          color: selected ? Colors.white : Colors.black54,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (hasQty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: selected ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'x$qty',
                                          style: TextStyle(
                                            color: selected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (extra != 0) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        '+¥${extra.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: selected ? Colors.white : accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final orderNumber = (payload['orderNumber'] as num?)?.toInt() ?? 0;
    final orderMode = (payload['orderMode'] ?? '') as String? ?? '';
    final subtotal = (payload['subtotal'] as num?)?.toDouble() ?? 0;
    final discount = (payload['discount'] as num?)?.toDouble() ?? 0;
    final total = (payload['total'] as num?)?.toDouble() ?? 0;
    final items = (payload['items'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('订单 #$orderNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: orderMode == 'take_out' ? const Color(0xFFFFEDD5) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  orderMode == 'take_out' ? '外带' : '堂食',
                  style: TextStyle(
                    color: orderMode == 'take_out' ? const Color(0xFFF97316) : const Color(0xFF0284C7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('暂无购物车商品'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = (item['name'] ?? '') as String? ?? '';
                      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
                      final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? 0;
                      final opts = (item['options'] as List?)
                              ?.whereType<Map>()
                              .map((e) => e.cast<String, dynamic>())
                              .toList() ??
                          const [];
                      final optionText = opts.isEmpty
                          ? ''
                          : opts
                              .map((o) {
                                final g = (o['groupName'] ?? '') as String? ?? '';
                                final n = (o['optionName'] ?? '') as String? ?? '';
                                final q = (o['quantity'] as num?)?.toInt() ?? 0;
                                final extra = (o['extraPrice'] as num?)?.toDouble() ?? 0;
                                final extraLabel = extra == 0 ? '' : '+¥${extra.toStringAsFixed(0)}';
                                final qtyLabel = q > 1 ? ' x$q' : '';
                                return '$g: $n$qtyLabel $extraLabel'.trim();
                              })
                              .join(' · ');

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                if (optionText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(optionText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('单价 ¥${unitPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('x$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                '¥${lineTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 20),
          _SummaryLine(label: '小计', value: subtotal),
          _SummaryLine(label: '折扣', value: -discount, muted: true),
          const SizedBox(height: 6),
          _SummaryLine(label: '应付总额', value: total, emphasized: true),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;
  final bool muted;
  const _SummaryLine({required this.label, required this.value, this.emphasized = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 18 : 14,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
      color: muted ? Colors.grey : null,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(
          '¥${value.toStringAsFixed(2)}',
          style: style.copyWith(color: emphasized ? const Color(0xFFEF4444) : style.color),
        ),
      ],
    );
  }
}

class _PaymentSelectionContent extends StatelessWidget {
  const _PaymentSelectionContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final orderNumber = (payload['orderNumber'] as num?)?.toInt() ?? 0;
    final total = (payload['total'] as num?)?.toDouble() ?? 0;
    final options = (payload['options'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const [];

    final controller = ProviderScope.containerOf(context, listen: false)
        .read(customerPeerLinkControllerProvider.notifier);

    void sendChoice(Map<String, dynamic> opt) {
      controller.clearLocalMessage();
      controller.sendMessage(
        PeerMessage(
          type: 'payment_choice',
          payload: {
            'group': opt['group'],
            'code': opt['code'],
            'label': opt['label'],
          },
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('订单 #$orderNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('应付 ¥${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final label = (opt['label'] ?? '') as String? ?? '';
                final enabled = opt['enabled'] as bool? ?? true;
                IconData icon;
                if (opt['group'] == 'cash') {
                  icon = Icons.attach_money_rounded;
                } else if (opt['group'] == 'qr') {
                  icon = Icons.qr_code_2_rounded;
                } else {
                  icon = Icons.credit_card_rounded;
                }
                return Opacity(
                  opacity: enabled ? 1 : 0.35,
                  child: InkWell(
                    onTap: enabled ? () => sendChoice(opt) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 8)),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 36, color: enabled ? const Color(0xFF0EA5E9) : Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: enabled ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            enabled ? '点击选择' : '暂不可用',
                            style: TextStyle(fontSize: 12, color: enabled ? Colors.grey.shade600 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood_rounded, size: 48, color: Colors.grey.shade400),
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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


