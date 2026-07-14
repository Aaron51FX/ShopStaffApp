import 'payment_models.dart';

enum PaymentTimeoutOutcome { failure, cancelled, indeterminate }

class PaymentStagePolicy {
  const PaymentStagePolicy({
    required this.canCancel,
    required this.timeoutOutcome,
  });

  final bool canCancel;
  final PaymentTimeoutOutcome timeoutOutcome;
}

extension PaymentPhasePolicy on PaymentPhase {
  PaymentStagePolicy get policy {
    return switch (this) {
      PaymentPhase.initializing => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.failure,
      ),
      PaymentPhase.connecting => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.failure,
      ),
      PaymentPhase.requesting => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.failure,
      ),
      PaymentPhase.sending => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.indeterminate,
      ),
      PaymentPhase.waitingUser => const PaymentStagePolicy(
        canCancel: true,
        timeoutOutcome: PaymentTimeoutOutcome.cancelled,
      ),
      PaymentPhase.waitingTerminalResult => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.indeterminate,
      ),
      PaymentPhase.reconciling => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.indeterminate,
      ),
      PaymentPhase.confirming => const PaymentStagePolicy(
        canCancel: false,
        timeoutOutcome: PaymentTimeoutOutcome.indeterminate,
      ),
    };
  }
}
