import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.state,
    required this.args,
    required this.cancel,
    required this.confirm,
  });

  final PaymentSessionState state;
  final PaymentFlowPageArgs args;
  final VoidCallback cancel;
  final VoidCallback confirm;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final isCash = args.channelGroup == PaymentChannels.cash;
    final t = AppLocalizations.of(context);
    if (state.canExit) {
      final isSuccess = state.result?.status == PaymentStatusType.success;
      final label = isSuccess
          ? t.paymentActionDoneReturn
          : t.paymentActionReturnPos;
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
        child: ElevatedButton.icon(
          onPressed: () => context.go('/entry'),
          icon: Icon(isSuccess ? Icons.check_circle_outline : Icons.arrow_back),
          label: Text(label),
        ),
      );
    }

    if (isCash && state.canConfirmManual) {
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(state.isConfirming ? t.paymentActionConfirming : label),
        ),
      );
    }

    if (!state.canCancel) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + padding.bottom),
      child: ElevatedButton.icon(
        onPressed: cancel,
        icon: state.isCancelling
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.stop_circle_outlined),
        label: Text(
          state.isCancelling
              ? t.paymentActionCancelling
              : t.paymentActionCancel,
        ),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      ),
    );
  }
}
