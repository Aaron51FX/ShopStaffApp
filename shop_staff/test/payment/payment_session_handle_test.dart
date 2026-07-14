import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/payment_backend_gateway.dart';
import 'package:shop_staff/data/services/payment_flows/bookkeeping_payment_flow.dart';
import 'package:shop_staff/data/services/pos_payment_orchestrator.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

void main() {
  test(
    'session handle buffers initial flow statuses until UI listens',
    () async {
      final backend = _CompletingBackendGateway();
      final orchestrator = PosPaymentOrchestrator(
        flows: {
          PaymentChannels.bookkeeping: BookkeepingPaymentFlow(
            backendGateway: backend,
          ),
        },
      );

      final handle = orchestrator.start(_context());
      final initialStatuses = await handle.statuses.take(2).toList();

      expect(handle.initialStatus.messageKey, PaymentMessageKeys.flowStarted);
      expect(initialStatuses[0].phase, PaymentPhase.requesting);
      expect(initialStatuses[1].phase, PaymentPhase.confirming);

      backend.complete();
      final result = await handle.result;
      expect(result.status, PaymentStatusType.success);
    },
  );
}

PaymentContext _context() {
  return PaymentContext(
    order: const OrderSubmissionResult(
      orderId: 'ORDER-1',
      tax1: 0,
      baseTax1: 1000,
      tax2: 0,
      baseTax2: 0,
      total: 1000,
    ),
    channel: const PaymentChannel(group: PaymentChannels.card, code: 'card'),
    mode: PaymentFlowMode.bookkeeping,
  );
}

class _CompletingBackendGateway implements PaymentBackendGateway {
  final _completer = Completer<void>();

  void complete() => _completer.complete();

  @override
  Future<void> confirmPayment(
    PaymentContext context,
    Map<String, dynamic> payload,
  ) {
    return _completer.future;
  }
}
