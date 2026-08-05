import 'package:flutter/material.dart';

import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

const managedOrderPaymentChannels = <String>[
  'Cash',
  'PayPay',
  'Wechat',
  'Alipay',
  'CreditCard',
  'au_Pay',
  'm_Pay',
  'd_Pay',
  'R_Pay',
];

Future<String?> showManagedOrderPaymentDialog(BuildContext context) {
  final t = AppLocalizations.of(context);
  var selected = managedOrderPaymentChannels.first;
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(t.orderHistoryPaymentMethodTitle),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: InputDecoration(
            labelText: t.orderHistoryDetailPayMethodLabel,
            border: const OutlineInputBorder(),
          ),
          items: managedOrderPaymentChannels
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => selected = value ?? selected),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(t.orderHistoryConfirm),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showManagedOrderCancelDialog(
  BuildContext context,
  ManagedOrder order,
) async {
  final t = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.orderHistoryCancelTitle),
      content: Text(
        order.requiresExternalRefund
            ? t.orderHistoryCancelExternalRefundMessage
            : t.orderHistoryCancelMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.orderHistoryConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
