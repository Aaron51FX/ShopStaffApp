
import 'package:flutter/material.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class CancelDialog extends StatelessWidget {
  const CancelDialog({
    super.key,
    required this.state,
    required this.onClose,
    this.onRetryCancel,
    this.onForceExit,
  });

  final CancelDialogState state;
  final VoidCallback onClose;
  final VoidCallback? onRetryCancel;
  final VoidCallback? onForceExit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (state.status) {
      case CancelDialogStatus.loading:
        return AlertDialog(
          title: Text(t.cancelDialogLoadingTitle),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 16),
              Expanded(child: Text(state.message ?? t.cancelDialogLoadingMessage)),
            ],
          ),
        );
      case CancelDialogStatus.success:
      case CancelDialogStatus.failure:
        final isSuccess = state.status == CancelDialogStatus.success;
        final showRecoveryActions =
            !isSuccess && state.requiresRecovery && onRetryCancel != null && onForceExit != null;
        final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_outline;
        final color = isSuccess ? Colors.green : Colors.redAccent;
        final title = isSuccess ? t.cancelDialogSuccessTitle : t.cancelDialogFailureTitle;
        final message = state.message ??
            (isSuccess ? t.cancelDialogSuccessMessage : t.cancelDialogFailureMessage);
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
            if (showRecoveryActions) ...[
              TextButton(
                onPressed: onRetryCancel,
                child: Text(t.paymentCancelRetryAction),
              ),
              FilledButton(
                onPressed: onForceExit,
                child: Text(t.paymentCancelForceExitAction),
              ),
            ] else
              TextButton(
                onPressed: onClose,
                child: Text(isSuccess ? t.cancelDialogDone : t.cancelDialogConfirm),
              ),
          ],
        );
      case CancelDialogStatus.hidden:
        return const SizedBox.shrink();
    }
  }
}