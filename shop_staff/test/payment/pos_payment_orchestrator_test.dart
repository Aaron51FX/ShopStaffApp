import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/pos_payment_orchestrator.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

void main() {
  test(
    'unexpected pre-dispatch closure is a known retryable failure',
    () async {
      final flow = _ControllablePaymentFlow();
      final orchestrator = PosPaymentOrchestrator(
        flows: {PaymentChannels.card: flow},
      );
      final session = orchestrator.start(_context);

      await flow.statuses.close();
      final result = await session.result;

      expect(result.status, PaymentStatusType.failure);
      expect(result.failure?.certainty, PaymentOutcomeCertainty.known);
      expect(result.retryable, isTrue);
    },
  );

  test('unexpected post-dispatch result error stays indeterminate', () async {
    final flow = _ControllablePaymentFlow();
    final orchestrator = PosPaymentOrchestrator(
      flows: {PaymentChannels.card: flow},
    );
    final session = orchestrator.start(_context);
    flow.statuses.add(
      const PaymentStatus(
        type: PaymentStatusType.processing,
        phase: PaymentPhase.sending,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    flow.result.completeError(StateError('transport lost'));
    final result = await session.result;

    expect(result.status, PaymentStatusType.indeterminate);
    expect(result.failure?.certainty, PaymentOutcomeCertainty.indeterminate);
    expect(result.retryable, isFalse);
  });

  test(
    'bookkeeping cash uses bookkeeping flow without cash hardware',
    () async {
      final cashFlow = _RecordingPaymentFlow();
      final bookkeepingFlow = _RecordingPaymentFlow();
      final orchestrator = PosPaymentOrchestrator(
        flows: {
          PaymentChannels.cash: cashFlow,
          PaymentChannels.bookkeeping: bookkeepingFlow,
        },
      );

      final session = orchestrator.start(
        const PaymentContext(
          order: OrderSubmissionResult(
            orderId: 'order-bookkeeping-cash',
            tax1: 0,
            baseTax1: 100,
            tax2: 0,
            baseTax2: 0,
            total: 100,
          ),
          channel: PaymentChannel(group: PaymentChannels.cash, code: 'cash'),
          mode: PaymentFlowMode.bookkeeping,
        ),
      );
      final result = await session.result;

      expect(result.status, PaymentStatusType.success);
      expect(bookkeepingFlow.contexts, hasLength(1));
      expect(cashFlow.contexts, isEmpty);
    },
  );
}

const _context = PaymentContext(
  order: OrderSubmissionResult(
    orderId: 'order-1',
    tax1: 0,
    baseTax1: 100,
    tax2: 0,
    baseTax2: 0,
    total: 100,
  ),
  channel: PaymentChannel(group: PaymentChannels.card, code: 'card'),
  mode: PaymentFlowMode.real,
);

class _ControllablePaymentFlow implements PaymentFlow {
  final StreamController<PaymentStatus> statuses =
      StreamController<PaymentStatus>();
  final Completer<PaymentResult> result = Completer<PaymentResult>();

  @override
  PaymentFlowRun start(PaymentContext context) {
    return PaymentFlowRun(
      statuses: statuses.stream,
      result: result.future,
      cancel: () async {},
    );
  }
}

class _RecordingPaymentFlow implements PaymentFlow {
  final List<PaymentContext> contexts = <PaymentContext>[];

  @override
  PaymentFlowRun start(PaymentContext context) {
    contexts.add(context);
    return PaymentFlowRun(
      statuses: Stream<PaymentStatus>.value(
        const PaymentStatus(
          type: PaymentStatusType.success,
          phase: PaymentPhase.confirming,
        ),
      ),
      result: Future<PaymentResult>.value(
        PaymentResult.success(messageKey: PaymentMessageKeys.statusSuccess),
      ),
      cancel: () async {},
    );
  }
}
