import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

import '../viewmodels/payment_flow_viewmodel.dart';

class PaymentFlowPage extends ConsumerStatefulWidget {
  const PaymentFlowPage({super.key, required this.args});

  final PaymentFlowPageArgs args;

  @override
  ConsumerState<PaymentFlowPage> createState() => _PaymentFlowPageState();
}

class _PaymentFlowPageState extends ConsumerState<PaymentFlowPage> {
  late final provider = paymentFlowViewModelProvider(widget.args);
  ProviderSubscription<PaymentFlowState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<PaymentFlowState>(provider, (previous, next) {
      if (previous?.result != next.result && next.result != null) {
        final result = next.result!;
        switch (result.status) {
          case PaymentStatusType.success:
            SimpleToast.successGlobal(result.message ?? '支付成功');
            break;
          case PaymentStatusType.cancelled:
            SimpleToast.errorGlobal(result.message ?? '支付已取消');
            break;
          case PaymentStatusType.failure:
          default:
            SimpleToast.errorGlobal(result.message ?? '支付失败');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    final args = widget.args;

    return WillPopScope(
      onWillPop: () async => state.canExit,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_titleForGroup(args)),
          actions: [
            if (state.canExit)
              TextButton(
                onPressed: () => context.go('/pos'),
                child: const Text('返回 POS', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderSummary(args: args),
              const SizedBox(height: 16),
              _StatusHero(state: state, args: args),
              const SizedBox(height: 24),
              Expanded(child: _StatusTimeline(state: state)),
            ],
          ),
        ),
        bottomNavigationBar: _BottomActionBar(state: state, cancel: () => ref.read(provider.notifier).cancelPayment()),
      ),
    );
  }

  String _titleForGroup(PaymentFlowPageArgs args) {
    final name = args.channelDisplayName;
    switch (args.channelGroup) {
      case PaymentChannels.card:
        return '信用卡支付${name != null ? ' - $name' : ''}';
      case PaymentChannels.cash:
        return '现金支付';
      case PaymentChannels.qr:
        return '扫码支付${name != null ? ' - $name' : ''}';
      default:
        return '支付流程';
    }
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.args});

  final PaymentFlowPageArgs args;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('订单号 ${args.order.orderId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('选择方式: ${args.channelDisplayName ?? args.channelCode}', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Text(formatter.format(args.order.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.state, required this.args});

  final PaymentFlowState state;
  final PaymentFlowPageArgs args;

  @override
  Widget build(BuildContext context) {
    final current = state.currentStatus;
    final theme = Theme.of(context);
    final effectiveResult = state.result?.status;
    final hasError = state.error != null;
    final message = hasError
        ? state.error!
        : current?.message ?? _defaultMessage(args.channelGroup, current?.type);
    final icon = hasError ? Icons.error_rounded : _iconForStatus(current?.type, effectiveResult);
    final color = hasError ? Colors.redAccent : _colorForStatus(theme, current?.type, effectiveResult);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasError)
            Text(_instructionFor(args.channelGroup), style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  static IconData _iconForStatus(PaymentStatusType? type, PaymentStatusType? resultType) {
    final effective = resultType ?? type;
    switch (effective) {
      case PaymentStatusType.success:
        return Icons.check_circle_rounded;
      case PaymentStatusType.failure:
        return Icons.error_rounded;
      case PaymentStatusType.cancelled:
        return Icons.cancel_rounded;
      case PaymentStatusType.waitingForUser:
        return Icons.hourglass_bottom_rounded;
      case PaymentStatusType.processing:
        return Icons.sync_rounded;
      case PaymentStatusType.pending:
      case PaymentStatusType.initialized:
      default:
        return Icons.payment_rounded;
    }
  }

  static Color _colorForStatus(ThemeData theme, PaymentStatusType? type, PaymentStatusType? resultType) {
    final effective = resultType ?? type;
    switch (effective) {
      case PaymentStatusType.success:
        return Colors.green;
      case PaymentStatusType.failure:
        return Colors.redAccent;
      case PaymentStatusType.cancelled:
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  static String _defaultMessage(String group, PaymentStatusType? type) {
    switch (group) {
      case PaymentChannels.card:
        if (type == PaymentStatusType.pending) return '正在连接终端…';
        if (type == PaymentStatusType.processing) return '请按照POS终端提示操作';
        return '信用卡支付处理中';
      case PaymentChannels.cash:
        if (type == PaymentStatusType.pending) return '请准备现金';
        if (type == PaymentStatusType.waitingForUser) return '等待顾客投入现金';
        return '现金支付处理中';
      case PaymentChannels.qr:
        if (type == PaymentStatusType.waitingForUser) return '请将二维码对准扫描区';
        return '二维码支付处理中';
      default:
        return '支付处理中';
    }
  }

  static String _instructionFor(String group) {
    switch (group) {
      case PaymentChannels.card:
        return '请按照终端提示插卡、刷卡或挥卡，完成支付后不要立即拔卡。';
      case PaymentChannels.cash:
        return '现金投入完成后，请等待机器找零并领取收据。';
      case PaymentChannels.qr:
        return '请使用顾客手机的二维码对准扫描器，等待确认提示。';
      default:
        return '请按照屏幕或终端提示完成支付。';
    }
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.state});

  final PaymentFlowState state;

  @override
  Widget build(BuildContext context) {
    final history = state.timeline;
    if (history.isEmpty) {
      if (state.error != null) {
        return Center(
          child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
        );
      }
      return const Center(child: Text('暂无状态更新'));
    }
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final status = history[index];
        return ListTile(
          leading: Icon(_StatusHero._iconForStatus(status.type, null)),
          title: Text(status.message ?? _label(status.type)),
        );
      },
    );
  }

  static String _label(PaymentStatusType type) {
    switch (type) {
      case PaymentStatusType.initialized:
        return '初始化';
      case PaymentStatusType.pending:
        return '待处理';
      case PaymentStatusType.waitingForUser:
        return '等待顾客操作';
      case PaymentStatusType.processing:
        return '处理中';
      case PaymentStatusType.success:
        return '支付成功';
      case PaymentStatusType.failure:
        return '支付失败';
      case PaymentStatusType.cancelled:
        return '支付已取消';
    }
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.state, required this.cancel});

  final PaymentFlowState state;
  final VoidCallback cancel;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    if (state.canExit) {
      final isSuccess = state.result?.status == PaymentStatusType.success;
      final label = isSuccess ? '完成并返回' : '返回POS';
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
        child: ElevatedButton.icon(
          onPressed: () => context.go('/pos'),
          icon: Icon(isSuccess ? Icons.check_circle_outline : Icons.arrow_back),
          label: Text(label),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
      child: ElevatedButton.icon(
        onPressed: state.isCancelling ? null : cancel,
        icon: state.isCancelling
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.stop_circle_outlined),
        label: Text(state.isCancelling ? '正在取消…' : '取消支付'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      ),
    );
  }
}
