sealed class PaymentFlowEffect {
  const PaymentFlowEffect();
}

class PaymentFlowToastEffect extends PaymentFlowEffect {
  const PaymentFlowToastEffect({
    this.message,
    this.messageKey,
    this.messageArgs,
    this.isError = false,
  });

  final String? message;
  final String? messageKey;
  final Map<String, dynamic>? messageArgs;
  final bool isError;
}

class PaymentFlowRequestCancelConfirmEffect extends PaymentFlowEffect {
  const PaymentFlowRequestCancelConfirmEffect({
    this.title,
    this.message,
    this.destructive = true,
  });

  final String? title;
  final String? message;
  final bool destructive;
}

class PaymentFlowDrawerCloseReminderEffect extends PaymentFlowEffect {
  const PaymentFlowDrawerCloseReminderEffect();
}
