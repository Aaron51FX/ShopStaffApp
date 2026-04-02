import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/payment_flows/pos_payment_status_adapter.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

void main() {
  const adapter = PosPaymentStatusAdapter(
    PosPaymentStatusAdapterConfig(
      successMessageKey: PaymentMessageKeys.cardSuccess,
      failureMessageKey: PaymentMessageKeys.cardFailure,
      cancelledMessageKey: PaymentMessageKeys.cardCancelled,
    ),
  );

  group('PosPaymentStatusAdapter', () {
    test(
      'maps explicit phase and error metadata through to payment status',
      () {
        const status = PosPaymentStatus(
          type: PosPaymentStatusType.failure,
          messageKey: PaymentMessageKeys.posTimeout,
          errorCode: 'L11',
          errorType: PaymentErrorType.device,
          retryable: false,
          phase: PaymentPhase.confirming,
          details: {'source': 'terminal'},
        );

        final mapped = adapter.map(status);

        expect(mapped.type, PaymentStatusType.failure);
        expect(mapped.messageKey, PaymentMessageKeys.posTimeout);
        expect(mapped.phase, PaymentPhase.confirming);
        expect(mapped.errorType, PaymentErrorType.device);
        expect(mapped.retryable, isFalse);
        expect(mapped.details, {'source': 'terminal', 'errorCode': 'L11'});
      },
    );

    test('uses fallback keys and phases when POS status omits them', () {
      const status = PosPaymentStatus(type: PosPaymentStatusType.pending);

      final mapped = adapter.map(status);

      expect(mapped.messageKey, PaymentMessageKeys.posWaitingResponse);
      expect(mapped.phase, PaymentPhase.sending);
      expect(mapped.errorType, isNull);
    });

    test(
      'builds terminal result with error code payload for cancelled status',
      () {
        const status = PosPaymentStatus(
          type: PosPaymentStatusType.cancelled,
          messageKey: PaymentMessageKeys.posTerminalCancelled,
          messageArgs: {'code': 'M10'},
          errorCode: 'M10',
          details: {'mpfs': '321'},
          phase: PaymentPhase.waitingUser,
        );

        final result = adapter.toTerminalResult(status);

        expect(result, isNotNull);
        expect(result!.status, PaymentStatusType.cancelled);
        expect(result.errorCode, 'M10');
        expect(result.payload, {'mpfs': '321', 'errorCode': 'M10'});
      },
    );

    test('keeps cancel-wait-result status as non-terminal processing', () {
      const status = PosPaymentStatus(
        type: PosPaymentStatusType.processing,
        messageKey: PaymentMessageKeys.posCancelWaitResult,
        messageArgs: {'code': 'L06'},
        errorCode: 'L06',
        details: {'mpfs': '321'},
        phase: PaymentPhase.waitingTerminalResult,
      );

      final mapped = adapter.map(status);
      final result = adapter.toTerminalResult(status);

      expect(mapped.type, PaymentStatusType.processing);
      expect(mapped.phase, PaymentPhase.waitingTerminalResult);
      expect(mapped.messageKey, PaymentMessageKeys.posCancelWaitResult);
      expect(result, isNull);
    });
  });
}
