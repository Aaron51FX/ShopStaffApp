
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
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