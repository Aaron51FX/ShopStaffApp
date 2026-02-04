
import 'package:flutter/material.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import 'package:shop_staff/presentations/payment/widgets/status_hero.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.state});

  final PaymentFlowState state;

  @override
  Widget build(BuildContext context) {
    final history = state.timeline;
    final t = AppLocalizations.of(context);
    if (history.isEmpty) {
      if (state.error != null) {
        return Center(
          child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
        );
      }
      return Center(child: Text(t.paymentStatusNoUpdates));
    }
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final status = history[index];
        return ListTile(
          leading: Icon(StatusHero.iconForStatus(status.type, null)),
          title: Text(StatusHero.resolveMessage(
            t,
            key: status.messageKey,
            args: status.messageArgs,
            fallback: status.message ?? _label(t, status.type),
          )),
        );
      },
    );
  }

  static String _label(AppLocalizations t, PaymentStatusType type) {
    switch (type) {
      case PaymentStatusType.initialized:
        return t.paymentStatusInitialized;
      case PaymentStatusType.pending:
        return t.paymentStatusPending;
      case PaymentStatusType.waitingForUser:
        return t.paymentStatusWaitingUser;
      case PaymentStatusType.processing:
        return t.paymentStatusProcessing;
      case PaymentStatusType.success:
        return t.paymentStatusSuccess;
      case PaymentStatusType.failure:
        return t.paymentStatusFailure;
      case PaymentStatusType.cancelled:
        return t.paymentStatusCancelled;
    }
  }
}
