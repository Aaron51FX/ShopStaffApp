import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/data/services/payment_channel_support.dart';

import '../viewmodels/payment_flow_viewmodel.dart';

class PaymentFlowPage extends ConsumerStatefulWidget {
  const PaymentFlowPage({super.key, required this.args});

  final PaymentFlowPageArgs args;

  @override
  ConsumerState<PaymentFlowPage> createState() => _PaymentFlowPageState();
}

class _PaymentFlowPageState extends ConsumerState<PaymentFlowPage> {
  late final provider = paymentFlowViewModelProvider(widget.args);
  ProviderSubscription<PaymentFlowState>? _stateSubscription;
  ProviderSubscription<CancelDialogState>? _cancelSubscription;
  ValueNotifier<CancelDialogState>? _cancelDialogNotifier;
  bool _isCancelDialogVisible = false;
  ProviderSubscription<QrScanUiState>? _qrScanSubscription;
  ValueNotifier<QrScanUiState>? _qrDialogNotifier;
  bool _isQrDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = ref.listenManual<PaymentFlowState>(provider, (previous, next) {
      if (previous?.result != next.result && next.result != null) {
        final result = next.result!;
        switch (result.status) {
          case PaymentStatusType.success:
            SimpleToast.successGlobal(result.message ?? '支付成功');
            break;
          case PaymentStatusType.cancelled:
            //SimpleToast.successGlobal(result.message ?? '支付已取消');
            break;
          case PaymentStatusType.failure:
          default:
            SimpleToast.errorGlobal(result.message ?? '支付失败');
            break;
        }
      }
    });
    _cancelSubscription = ref.listenManual<CancelDialogState>(
      provider.select((state) => state.cancelDialog),
      (previous, next) {
        if (!mounted) return;
        if (previous?.status == next.status && previous?.message == next.message) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleCancelDialogChange(next);
        });
      },
    );

    _qrScanSubscription = ref.listenManual<QrScanUiState>(
      qrScanUiStateProvider,
      (previous, next) {
        if (!mounted) return;
        if (widget.args.channelGroup != PaymentChannels.qr) return;
        if (previous == next) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleQrDialogChange(next);
        });
      },
    );

    if (widget.args.channelGroup == PaymentChannels.qr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final current = ref.read(qrScanUiStateProvider);
        _handleQrDialogChange(current);
      });
    }
  }

  @override
  void dispose() {
    _stateSubscription?.close();
    _cancelSubscription?.close();
    _cancelDialogNotifier?.dispose();
    _qrScanSubscription?.close();
    _qrDialogNotifier?.dispose();
    super.dispose();
  }

  void _handleCancelDialogChange(CancelDialogState dialogState) {
    if (!mounted) return;
    if (dialogState.status == CancelDialogStatus.hidden) {
      if (_isCancelDialogVisible) {
        _isCancelDialogVisible = false;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      return;
    }

    if (_isCancelDialogVisible) {
      _cancelDialogNotifier?.value = dialogState;
      return;
    }

    _cancelDialogNotifier = ValueNotifier<CancelDialogState>(dialogState);
    _isCancelDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<CancelDialogState>(
          valueListenable: _cancelDialogNotifier!,
          builder: (context, state, _) {
            return _CancelDialog(
              state: state,
              onClose: () {
                ref.read(provider.notifier).goEntryPage();
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _isCancelDialogVisible = false;
      _cancelDialogNotifier?.dispose();
      _cancelDialogNotifier = null;
      if (mounted) {
        ref.read(provider.notifier).dismissCancelDialog();
      }
    });
  }

  void _handleQrDialogChange(QrScanUiState dialogState) {
    if (!mounted) return;
    if (widget.args.channelGroup != PaymentChannels.qr) return;
    if (dialogState.status == QrScanDialogStatus.hidden) {
      if (_isQrDialogVisible) {
        _isQrDialogVisible = false;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      return;
    }

    if (_isQrDialogVisible) {
      _qrDialogNotifier?.value = dialogState;
      return;
    }

    _qrDialogNotifier = ValueNotifier<QrScanUiState>(dialogState);
    _isQrDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<QrScanUiState>(
          valueListenable: _qrDialogNotifier!,
          builder: (context, state, _) {
            return _QrScanDialog(
              state: state,
              onSubmitted: (value) => ref.read(dialogDrivenQrScannerProvider).submitCode(value),
              onCancel: () => ref.read(dialogDrivenQrScannerProvider).cancelScan(),
            );
          },
        );
      },
    ).whenComplete(() {
      _isQrDialogVisible = false;
      _qrDialogNotifier?.dispose();
      _qrDialogNotifier = null;
    });
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
              _StatusHero(
                state: state,
                args: args,
                onRetry: () => ref.read(provider.notifier).retryPayment(),
              ),
              const SizedBox(height: 24),
              Expanded(child: _StatusTimeline(state: state)),
            ],
          ),
        ),
        bottomNavigationBar: _BottomActionBar(
          state: state,
          args: args,
          cancel: () => ref.read(provider.notifier).cancelPayment(),
          confirm: () => ref.read(provider.notifier).confirmManualPayment(),
        ),
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
  const _StatusHero({required this.state, required this.args, this.onRetry});

  final PaymentFlowState state;
  final PaymentFlowPageArgs args;
  final VoidCallback? onRetry;

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
    final showRetry = _shouldShowRetry(state) && onRetry != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          ),
          if (showRetry) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 50),
              label: const Text('重试', style: TextStyle(fontSize: 16)),
            ),
          ],
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

  static bool _shouldShowRetry(PaymentFlowState state) {
    if (state.isCancelling) return false;
    if (state.error != null) return true;
    final result = state.result?.status;
    if (result == PaymentStatusType.failure || result == PaymentStatusType.cancelled) {
      return true;
    }
    final currentType = state.currentStatus?.type;
    return currentType == PaymentStatusType.failure || currentType == PaymentStatusType.cancelled;
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
  const _BottomActionBar({
    required this.state,
    required this.args,
    required this.cancel,
    required this.confirm,
  });

  final PaymentFlowState state;
  final PaymentFlowPageArgs args;
  final VoidCallback cancel;
  final VoidCallback confirm;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final isCash = args.channelGroup == PaymentChannels.cash;
    if (state.canExit) {
      final isSuccess = state.result?.status == PaymentStatusType.success;
      final label = isSuccess ? '完成并返回' : '返回POS';
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
        child: ElevatedButton.icon(
          onPressed: () => context.go('/entry'),
          icon: Icon(isSuccess ? Icons.check_circle_outline : Icons.arrow_back),
          label: Text(label),
        ),
      );
    }

    if (isCash && state.requiresManualCompletion && state.confirmationReady && !state.isFinished) {
      final receipt = state.pendingReceipt;
      final amount = receipt?['acceptedAmount'];
      final formattedAmount = amount is num ? amount.toInt() : null;
      final label = formattedAmount != null ? '确认支付 ¥$formattedAmount' : '确认支付';
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
        child: ElevatedButton.icon(
          onPressed: state.isConfirming ? null : confirm,
          icon: state.isConfirming
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_outline),
          label: Text(state.isConfirming ? '正在确认…' : label),
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

class _CancelDialog extends StatelessWidget {
  const _CancelDialog({required this.state, required this.onClose});

  final CancelDialogState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CancelDialogStatus.loading:
        return AlertDialog(
          title: const Text('正在取消'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 16),
              Expanded(child: Text(state.message ?? '正在向终端发送取消指令…')),
            ],
          ),
        );
      case CancelDialogStatus.success:
      case CancelDialogStatus.failure:
        final isSuccess = state.status == CancelDialogStatus.success;
        final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_outline;
        final color = isSuccess ? Colors.green : Colors.redAccent;
        final title = isSuccess ? '取消成功' : '取消失败';
        final message = state.message ?? (isSuccess ? '支付已取消' : '取消失败，请稍后重试');
        return AlertDialog(
          title: Text(title),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: onClose,
              child: Text(isSuccess ? '完成' : '确定'),
            ),
          ],
        );
      case CancelDialogStatus.hidden:
        return const SizedBox.shrink();
    }
  }
}

class _QrScanDialog extends StatefulWidget {
  const _QrScanDialog({required this.state, required this.onSubmitted, required this.onCancel});

  final QrScanUiState state;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  State<_QrScanDialog> createState() => _QrScanDialogState();
}

class _QrScanDialogState extends State<_QrScanDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = _ScanHardwareFocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _QrScanDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.status == QrScanDialogStatus.waiting && oldWidget.state.status != QrScanDialogStatus.waiting) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _handleSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {});
      return;
    }
    widget.onSubmitted(trimmed);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.state.status == QrScanDialogStatus.error;
    final message = widget.state.message ?? (isError ? '扫码失败，请重试' : '请使用扫码枪对准提示区域');
    return AlertDialog(
      title: const Text('扫码支付'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: isError ? Colors.redAccent : Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            showCursor: false,
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: '请扫码',
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 24),
            obscureText: false,
            onSubmitted: _handleSubmit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _ScanHardwareFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    // Prevent the soft keyboard while keeping hardware scanner input active.
    return false;
  }
}
