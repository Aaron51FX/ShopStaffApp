import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/payment_backend_gateway.dart';
import 'package:shop_staff/data/services/payment_flows/cash_payment_flow.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';

void main() {
  group('CashPaymentFlow boundary conditions', () {
    test('finalize before await-confirmation throws PAYMENT_FINALIZE_NOT_REQUIRED', () async {
      final runPaymentCompleter = Completer<CashMachineReceipt>();
      final machine = _FakeCashMachineService(
        runPaymentCompleter: runPaymentCompleter,
      );
      final backend = _FakePaymentBackendGateway();
      final flow = CashPaymentFlow(cashMachine: machine, backendGateway: backend);
      final run = flow.start(_context());

      expect(
        () => run.finalize!(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'PAYMENT_FINALIZE_NOT_REQUIRED',
          ),
        ),
      );

      await run.cancel();
      runPaymentCompleter.complete(const CashMachineReceipt(acceptedAmount: 1200, expectedAmount: 1200));
      await run.result;
      expect(machine.cancelCount, greaterThanOrEqualTo(1));
    });

    test('finalize succeeds after await-confirmation stage', () async {
      final runPaymentCompleter = Completer<CashMachineReceipt>();
      final machine = _FakeCashMachineService(
        runPaymentCompleter: runPaymentCompleter,
      );
      final backend = _FakePaymentBackendGateway();
      final flow = CashPaymentFlow(cashMachine: machine, backendGateway: backend);
      final run = flow.start(_context());

      final awaitConfirm = run.statuses.firstWhere(
        (status) => status.details?['stage'] == 'await_confirmation',
      );
      runPaymentCompleter.complete(const CashMachineReceipt(acceptedAmount: 1200, expectedAmount: 1200));
      await awaitConfirm;

      await run.finalize!();
      final result = await run.result;
      expect(result.status, PaymentStatusType.success);
      expect(machine.completeCount, 1);
      expect(backend.confirmedPayloads, hasLength(1));
      expect(backend.confirmedPayloads.single['method'], PaymentChannels.cash);
    });

    test('second finalize while confirming throws PAYMENT_FINALIZE_NOT_REQUIRED', () async {
      final runPaymentCompleter = Completer<CashMachineReceipt>();
      final completePaymentCompleter = Completer<CashMachineReceipt>();
      final machine = _FakeCashMachineService(
        runPaymentCompleter: runPaymentCompleter,
        completePaymentCompleter: completePaymentCompleter,
      );
      final backend = _FakePaymentBackendGateway();
      final flow = CashPaymentFlow(cashMachine: machine, backendGateway: backend);
      final run = flow.start(_context());

      final awaitConfirm = run.statuses.firstWhere(
        (status) => status.details?['stage'] == 'await_confirmation',
      );
      runPaymentCompleter.complete(const CashMachineReceipt(acceptedAmount: 1200, expectedAmount: 1200));
      await awaitConfirm;

      final firstFinalize = run.finalize!();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        () => run.finalize!(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'PAYMENT_FINALIZE_NOT_REQUIRED',
          ),
        ),
      );

      completePaymentCompleter.complete(
        const CashMachineReceipt(acceptedAmount: 1200, expectedAmount: 1200),
      );
      await firstFinalize;
      final result = await run.result;
      expect(result.status, PaymentStatusType.success);
    });

    test('cancel after await-confirmation ends flow and later finalize is a no-op', () async {
      final runPaymentCompleter = Completer<CashMachineReceipt>();
      final machine = _FakeCashMachineService(
        runPaymentCompleter: runPaymentCompleter,
      );
      final backend = _FakePaymentBackendGateway();
      final flow = CashPaymentFlow(cashMachine: machine, backendGateway: backend);
      final run = flow.start(_context());

      final awaitConfirm = run.statuses.firstWhere(
        (status) => status.details?['stage'] == 'await_confirmation',
      );
      runPaymentCompleter.complete(const CashMachineReceipt(acceptedAmount: 1200, expectedAmount: 1200));
      await awaitConfirm;

      await run.cancel();
      final result = await run.result;
      expect(result.status, PaymentStatusType.cancelled);

      await run.finalize!();
      expect(machine.completeCount, 0);
      expect(backend.confirmedPayloads, isEmpty);
    });
  });
}

PaymentContext _context() {
  return PaymentContext(
    order: const OrderSubmissionResult(
      orderId: 'ORD-1',
      tax1: 100,
      baseTax1: 1000,
      tax2: 0,
      baseTax2: 0,
      total: 1200,
    ),
    channel: const PaymentChannel(group: PaymentChannels.cash, code: 'cash'),
  );
}

class _FakeCashMachineService implements CashMachineService {
  _FakeCashMachineService({
    Completer<CashMachineReceipt>? runPaymentCompleter,
    Completer<CashMachineReceipt>? completePaymentCompleter,
  })  : _runPaymentCompleter = runPaymentCompleter,
        _completePaymentCompleter = completePaymentCompleter;

  final StreamController<CashMachineEvent> _events = StreamController<CashMachineEvent>.broadcast();
  final Completer<CashMachineReceipt>? _runPaymentCompleter;
  final Completer<CashMachineReceipt>? _completePaymentCompleter;

  int cancelCount = 0;
  int completeCount = 0;

  @override
  Stream<CashMachineEvent> get events => _events.stream;

  @override
  Future<CashMachineInitResult> initialize() async {
    return const CashMachineInitResult(isReady: true);
  }

  @override
  Future<CashMachineReceipt> runPayment(int amount) async {
    if (_runPaymentCompleter != null) {
      return _runPaymentCompleter.future;
    }
    return CashMachineReceipt(acceptedAmount: amount, expectedAmount: amount);
  }

  @override
  Future<CashMachineReceipt> completePayment() async {
    completeCount += 1;
    if (_completePaymentCompleter != null) {
      return _completePaymentCompleter.future;
    }
    return const CashMachineReceipt(acceptedAmount: 1200, expectedAmount: 1200);
  }

  @override
  Future<void> cancelPayment() async {
    cancelCount += 1;
  }

  @override
  Future<void> dispose() async {
    await _events.close();
  }
}

class _FakePaymentBackendGateway implements PaymentBackendGateway {
  final List<Map<String, dynamic>> confirmedPayloads = <Map<String, dynamic>>[];

  @override
  Future<void> confirmPayment(PaymentContext context, Map<String, dynamic> payload) async {
    confirmedPayloads.add(Map<String, dynamic>.from(payload));
  }
}
