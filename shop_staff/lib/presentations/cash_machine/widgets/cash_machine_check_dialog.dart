import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entry/viewmodels/entry_viewmodels.dart';

class CashMachineCheckDialog extends StatelessWidget {
  const CashMachineCheckDialog({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onSkip,
    required this.onClose,
  });

  final CashMachineDialogState state;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = state.status;
    final isChecking = status == CashMachineDialogStatus.checking;
    final isFailure = status == CashMachineDialogStatus.failure;
    final isSuccess = status == CashMachineDialogStatus.success;

    final icon = isSuccess
        ? Icons.check_circle_rounded
        : isFailure
            ? Icons.error_outline
            : Icons.memory_rounded;
    final color = isSuccess
        ? Colors.green
        : isFailure
            ? theme.colorScheme.error
            : theme.colorScheme.primary;
    final message = state.message ??
        (isChecking
            ? '正在检测现金机，请稍候…'
            : isSuccess
                ? '现金机工作正常，可以进行现金支付。'
                : '检测失败，请检查设备连接。');

    return AlertDialog(
      title: const Text('现金机检测'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isChecking) ...[
              const LinearProgressIndicator(minHeight: 4),
              const SizedBox(height: 12),
              Text('步骤: 检查状态 → 打开 → 开始接收 → 读取金额 → 结束',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  )),
            ] else ...[
              Text(
                '流程: 检查状态 → 打开现金机 → Start Deposit → Deposit Amount → End Deposit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isChecking)
          TextButton(onPressed: onSkip, child: const Text('跳过')),
        if (isFailure) ...[
          TextButton(onPressed: onSkip, child: const Text('跳过')),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ] else if (isSuccess) ...[
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('完成'),
          ),
        ] else if (!isChecking)
          TextButton(onPressed: onClose, child: const Text('关闭')),
      ],
    );
  }
}

class CashMachineDialogPortal extends ConsumerStatefulWidget {
  const CashMachineDialogPortal({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CashMachineDialogPortal> createState() => _CashMachineDialogPortalState();
}

class _CashMachineDialogPortalState extends ConsumerState<CashMachineDialogPortal> {
  ProviderSubscription<CashMachineDialogState>? _subscription;
  ValueNotifier<CashMachineDialogState>? _notifier;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<CashMachineDialogState>(
      cashMachineCheckControllerProvider.select((state) => state.dialog),
      (previous, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleDialogChange(next);
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _handleDialogChange(CashMachineDialogState dialogState) {
    if (dialogState.status == CashMachineDialogStatus.hidden) {
      if (_visible) {
        _visible = false;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      return;
    }

    if (_visible) {
      _notifier?.value = dialogState;
      return;
    }

    _notifier = ValueNotifier<CashMachineDialogState>(dialogState);
    _visible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<CashMachineDialogState>(
          valueListenable: _notifier!,
          builder: (_, state, __) {
            return CashMachineCheckDialog(
              state: state,
              onRetry: () =>
                  ref.read(cashMachineCheckControllerProvider.notifier).start(auto: false),
              onSkip: () => ref.read(cashMachineCheckControllerProvider.notifier).skip(),
              onClose: () =>
                  ref.read(cashMachineCheckControllerProvider.notifier).dismissDialog(),
            );
          },
        );
      },
    ).whenComplete(() {
      _visible = false;
      _notifier?.dispose();
      _notifier = null;
      if (mounted) {
        ref.read(cashMachineCheckControllerProvider.notifier).dismissDialog();
      }
    });
  }
}
