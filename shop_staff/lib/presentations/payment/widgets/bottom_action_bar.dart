
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, 
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
    final t = AppLocalizations.of(context);
    final canCancel = _canCancel(state, args);
    if (state.canExit) {
      final isSuccess = state.result?.status == PaymentStatusType.success;
      final label = isSuccess ? t.paymentActionDoneReturn : t.paymentActionReturnPos;
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
      final label = formattedAmount != null
          ? t.paymentActionConfirmAmount(formattedAmount)
          : t.paymentActionConfirm;
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
        child: ElevatedButton.icon(
          onPressed: state.isConfirming ? null : confirm,
          icon: state.isConfirming
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_outline),
          label: Text(state.isConfirming ? t.paymentActionConfirming : label),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
      child: ElevatedButton.icon(
        onPressed: (state.isCancelling || !canCancel) ? null : cancel,
        icon: state.isCancelling
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.stop_circle_outlined),
        label: Text(state.isCancelling ? t.paymentActionCancelling : t.paymentActionCancel),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      ),
    );
  }

  static bool _canCancel(PaymentFlowState state, PaymentFlowPageArgs args) {
    if (state.isCancelling) return false;
    if (args.channelGroup != PaymentChannels.card &&
        args.channelGroup != PaymentChannels.qr &&
        args.channelGroup != PaymentChannels.cash) {
      return true;
    }
    if (!state.hasStarted) return true;
    if (state.error != null) return true;
    final result = state.result?.status;
    if (result == PaymentStatusType.failure || result == PaymentStatusType.cancelled) {
      return true;
    }
    final current = state.currentStatus?.type;
    if (current == PaymentStatusType.failure || current == PaymentStatusType.cancelled) {
      return true;
    }
    if (current == PaymentStatusType.initialized) return true;

    final phase = state.currentStatus?.phase;
    if (phase != null) {
      switch (phase) {
        case PaymentPhase.initializing:
          return true;
        case PaymentPhase.connecting:
        case PaymentPhase.requesting:
        case PaymentPhase.sending:
          return false;
        case PaymentPhase.waitingUser:
          return true;
        case PaymentPhase.confirming:
          return false;
      }
    }

    if (args.channelGroup == PaymentChannels.cash) {
      return current == PaymentStatusType.waitingForUser;
    }

    // Fallback for POS: allow cancel only when waiting for user action.
    return current == PaymentStatusType.waitingForUser;
  }
}
