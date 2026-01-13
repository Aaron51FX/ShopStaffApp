import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/payments/udf/payment_reducer.dart';
import 'package:shop_staff/application/payments/udf/payment_udf_models.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

void main() {
  group('PaymentReducer', () {
    test('cancel action emits confirm effect', () {
      const reducer = PaymentReducer();
      const state = PaymentUdfState(sessionId: 's1');

      final out = reducer.reduce(state, action: const PaymentActionCancelTapped());

      expect(out.state.sessionId, 's1');
      expect(out.effects.length, 1);
      expect(out.effects.single, isA<PaymentEffectRequestCancelConfirm>());
    });

    test('completed success emits toast and print effects', () {
      const reducer = PaymentReducer();
      final started = reducer.reduce(
        const PaymentUdfState(),
        event: const PaymentEventStarted(
          sessionId: 's1',
          initialStatus: PaymentStatus(type: PaymentStatusType.pending, message: 'start'),
        ),
      );

      final completed = reducer.reduce(
        started.state,
        event: PaymentEventCompleted(PaymentResult.success(message: 'ok')),
      );

      expect(completed.state.result?.status, PaymentStatusType.success);
      expect(completed.effects.whereType<PaymentEffectToast>().length, 1);
      expect(completed.effects.whereType<PaymentEffectStartPrint>().length, 1);
    });

    test('failed event emits error toast and records error', () {
      const reducer = PaymentReducer();
      final out = reducer.reduce(
        const PaymentUdfState(),
        event: const PaymentEventFailed('boom'),
      );

      expect(out.state.error, 'boom');
      final toast = out.effects.single as PaymentEffectToast;
      expect(toast.isError, true);
      expect(toast.message, 'boom');
    });
  });
}
