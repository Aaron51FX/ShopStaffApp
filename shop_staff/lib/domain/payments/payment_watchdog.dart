import 'dart:async';

import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';

class PaymentWatchdogTimeout {
  const PaymentWatchdogTimeout({
    required this.phase,
    required this.operation,
    required this.deadline,
  });

  final PaymentPhase phase;
  final String operation;
  final DateTime deadline;

  PaymentTimeoutOutcome get outcome => phase.policy.timeoutOutcome;

  PaymentOutcomeCertainty get certainty =>
      outcome == PaymentTimeoutOutcome.indeterminate
      ? PaymentOutcomeCertainty.indeterminate
      : PaymentOutcomeCertainty.known;

  PaymentRecovery get recovery {
    return switch (outcome) {
      PaymentTimeoutOutcome.failure => PaymentRecovery.retryCurrentStep,
      PaymentTimeoutOutcome.cancelled => PaymentRecovery.restartPayment,
      PaymentTimeoutOutcome.indeterminate => PaymentRecovery.reconcileResult,
    };
  }
}

/// Owns the single inactivity deadline for one payment execution.
class PaymentWatchdog {
  Timer? _timer;

  PaymentPhase? _phase;
  String? _operation;
  DateTime? _deadline;

  bool get isArmed => _timer?.isActive ?? false;
  PaymentPhase? get phase => _phase;
  String? get operation => _operation;
  DateTime? get deadline => _deadline;

  void arm({
    required PaymentPhase phase,
    required String operation,
    required Duration timeout,
    required void Function(PaymentWatchdogTimeout timeout) onTimeout,
  }) {
    cancel();
    final deadline = DateTime.now().add(timeout);
    _phase = phase;
    _operation = operation;
    _deadline = deadline;
    _timer = Timer(timeout, () {
      _timer = null;
      onTimeout(
        PaymentWatchdogTimeout(
          phase: phase,
          operation: operation,
          deadline: deadline,
        ),
      );
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _phase = null;
    _operation = null;
    _deadline = null;
  }
}
