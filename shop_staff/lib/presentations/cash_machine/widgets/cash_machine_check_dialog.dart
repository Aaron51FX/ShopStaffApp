import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

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
    final t = AppLocalizations.of(context);
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
            ? t.cashMachineCheckingMessage
            : isSuccess
                ? t.cashMachineSuccessMessage
                : t.cashMachineFailureMessage);

    return AlertDialog(
      title: Text(t.cashMachineTitle),
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
              Text(t.cashMachineStepsChecking,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  )),
            ] else ...[
              Text(
                t.cashMachineStepsFailure,
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
          TextButton(onPressed: onSkip, child: Text(t.cashMachineSkip)),
        if (isFailure) ...[
          TextButton(onPressed: onSkip, child: Text(t.cashMachineSkip)),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.cashMachineRetry),
          ),
        ] else if (isSuccess) ...[
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(t.cashMachineDone),
          ),
        ] else if (!isChecking)
          TextButton(onPressed: onClose, child: Text(t.cashMachineClose)),
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
