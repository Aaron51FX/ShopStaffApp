import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';

void main() {
  group('PaymentPhasePolicy', () {
    test('only operator-waiting phases allow cancellation', () {
      expect(PaymentPhase.initializing.policy.canCancel, isTrue);
      expect(PaymentPhase.waitingUser.policy.canCancel, isTrue);
      expect(PaymentPhase.connecting.policy.canCancel, isFalse);
      expect(PaymentPhase.requesting.policy.canCancel, isFalse);
      expect(PaymentPhase.sending.policy.canCancel, isFalse);
      expect(PaymentPhase.waitingTerminalResult.policy.canCancel, isFalse);
      expect(PaymentPhase.confirming.policy.canCancel, isFalse);
    });

    test('post-dispatch timeouts are indeterminate', () {
      expect(
        PaymentPhase.sending.policy.timeoutOutcome,
        PaymentTimeoutOutcome.indeterminate,
      );
      expect(
        PaymentPhase.waitingTerminalResult.policy.timeoutOutcome,
        PaymentTimeoutOutcome.indeterminate,
      );
      expect(
        PaymentPhase.confirming.policy.timeoutOutcome,
        PaymentTimeoutOutcome.indeterminate,
      );
    });
  });

  test('failure result carries typed certainty and recovery', () {
    final result = PaymentResult.failure(
      errorCode: 'TERMINAL_RESULT_UNKNOWN',
      errorType: PaymentErrorType.device,
      certainty: PaymentOutcomeCertainty.indeterminate,
    );

    expect(result.failure, isNotNull);
    expect(result.failure!.certainty, PaymentOutcomeCertainty.indeterminate);
    expect(result.failure!.recovery, PaymentRecovery.reconcileResult);
  });
}
