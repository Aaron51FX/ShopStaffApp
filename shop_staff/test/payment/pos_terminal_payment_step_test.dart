import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/data/services/payment_flows/pos_payment_status_adapter.dart';
import 'package:shop_staff/data/services/payment_flows/pos_terminal_payment_step.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
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

  test(
    'timeout after dispatch becomes reconcilable without cancelling POS',
    () async {
      final service = _FakePosPaymentService();
      final statuses = <PaymentStatus>[];
      final result = Completer<PaymentResult>();
      final step = PosTerminalPaymentStep(
        service: service,
        adapter: adapter,
        config: const PosTerminalPaymentStepConfig(
          startStatus: PaymentStatus(
            type: PaymentStatusType.pending,
            phase: PaymentPhase.connecting,
          ),
          startFailureMessageKey: PaymentMessageKeys.cardInitFailed,
          startStage: 'start',
          waitingStage: 'waiting',
          inactivityTimeout: Duration(milliseconds: 20),
        ),
        emitStatus: statuses.add,
        complete: (value) async {
          if (!result.isCompleted) result.complete(value);
        },
      );

      await step.start(_request());
      await Future<void>.delayed(const Duration(milliseconds: 35));

      expect(statuses.last.type, PaymentStatusType.indeterminate);
      expect(result.isCompleted, isFalse);
      expect(service.cancelCalls, 0);

      await step.reconcile();
      expect(statuses.last.type, PaymentStatusType.reconciling);

      service.emit(const PosPaymentStatus(type: PosPaymentStatusType.success));
      expect((await result.future).status, PaymentStatusType.success);
      await step.dispose();
      await service.dispose();
    },
  );

  test('timeout before a POS session exists is a known failure', () async {
    final service = _FakePosPaymentService(blockStart: true);
    final statuses = <PaymentStatus>[];
    final result = Completer<PaymentResult>();
    final step = PosTerminalPaymentStep(
      service: service,
      adapter: adapter,
      config: const PosTerminalPaymentStepConfig(
        startStatus: PaymentStatus(
          type: PaymentStatusType.pending,
          phase: PaymentPhase.connecting,
        ),
        startFailureMessageKey: PaymentMessageKeys.cardInitFailed,
        startStage: 'start',
        waitingStage: 'waiting',
        startTimeout: Duration(milliseconds: 20),
      ),
      emitStatus: statuses.add,
      complete: (value) async {
        if (!result.isCompleted) result.complete(value);
      },
    );

    unawaited(step.start(_request()));
    final completed = await result.future;

    expect(completed.status, PaymentStatusType.failure);
    expect(completed.failure?.certainty, PaymentOutcomeCertainty.known);
    expect(statuses.last.type, PaymentStatusType.failure);
    await step.dispose();
    await service.dispose();
  });
}

PosPaymentRequest _request() {
  return PosPaymentRequest(
    order: const OrderSubmissionResult(
      orderId: 'order-1',
      tax1: 0,
      baseTax1: 1000,
      tax2: 0,
      baseTax2: 0,
      total: 1000,
    ),
    channelGroup: PaymentChannels.card,
    channelCode: 'card',
  );
}

class _FakePosPaymentService implements PosPaymentService {
  _FakePosPaymentService({this.blockStart = false});

  final bool blockStart;
  final StreamController<PosPaymentStatus> _statuses =
      StreamController<PosPaymentStatus>.broadcast();
  final Completer<PosPaymentSession> _blockedStart = Completer();
  int cancelCalls = 0;

  void emit(PosPaymentStatus status) => _statuses.add(status);

  Future<void> dispose() => _statuses.close();

  @override
  Future<PosPaymentSession> startPayment(PosPaymentRequest request) {
    if (blockStart) return _blockedStart.future;
    return Future.value(
      const PosPaymentSession(
        sessionId: 'pos-session-1',
        initialStatus: PosPaymentStatus(type: PosPaymentStatusType.pending),
      ),
    );
  }

  @override
  Stream<PosPaymentStatus> watchStatus(String sessionId) => _statuses.stream;

  @override
  Future<void> cancel(String sessionId) async {
    cancelCalls += 1;
  }
}
