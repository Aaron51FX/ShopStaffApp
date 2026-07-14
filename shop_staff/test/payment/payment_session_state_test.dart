import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

void main() {
  group('PaymentSessionState capabilities', () {
    test('derives cancellation from the current payment phase', () {
      final connecting = PaymentSessionState(
        channelGroup: PaymentChannels.card,
        sessionId: 'session-1',
        hasStarted: true,
        currentStatus: const PaymentStatus(
          type: PaymentStatusType.pending,
          phase: PaymentPhase.connecting,
        ),
      );
      final waitingUser = connecting.copyWith(
        currentStatus: const PaymentStatus(
          type: PaymentStatusType.waitingForUser,
          phase: PaymentPhase.waitingUser,
        ),
      );

      expect(connecting.canCancel, isFalse);
      expect(waitingUser.canCancel, isTrue);
    });

    test('blocks retry and enables reconcile for an active unknown result', () {
      const state = PaymentSessionState(
        channelGroup: PaymentChannels.card,
        sessionId: 'session-1',
        hasStarted: true,
        currentStatus: PaymentStatus(
          type: PaymentStatusType.indeterminate,
          certainty: PaymentOutcomeCertainty.indeterminate,
          recovery: PaymentRecovery.reconcileResult,
        ),
      );

      expect(state.canCancel, isFalse);
      expect(state.canRetry, isFalse);
      expect(state.canReconcile, isTrue);
      expect(state.canExit, isFalse);
    });

    test('allows retry only for a known retryable failure', () {
      final knownFailure = PaymentSessionState(
        channelGroup: PaymentChannels.card,
        sessionId: 'session-1',
        hasStarted: true,
        result: PaymentResult.failure(retryable: true),
      );
      final unknownResult = PaymentSessionState(
        channelGroup: PaymentChannels.card,
        sessionId: 'session-1',
        hasStarted: true,
        result: PaymentResult.indeterminate(),
      );

      expect(knownFailure.canRetry, isTrue);
      expect(unknownResult.canRetry, isFalse);
      expect(unknownResult.canExit, isTrue);
    });

    test('exposes configuration and network recovery actions', () {
      const config = PaymentSessionState(
        currentStatus: PaymentStatus(
          type: PaymentStatusType.failure,
          errorType: PaymentErrorType.config,
        ),
      );
      const network = PaymentSessionState(
        currentStatus: PaymentStatus(
          type: PaymentStatusType.failure,
          recovery: PaymentRecovery.checkNetwork,
        ),
      );

      expect(config.canOpenSettings, isTrue);
      expect(config.canCheckNetwork, isFalse);
      expect(network.canCheckNetwork, isTrue);
    });
  });
}
