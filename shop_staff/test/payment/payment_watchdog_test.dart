import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/payments/payment_watchdog.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';

void main() {
  test('watchdog emits phase-aware timeout information', () async {
    final watchdog = PaymentWatchdog();
    final timeout = Completer<PaymentWatchdogTimeout>();

    watchdog.arm(
      phase: PaymentPhase.waitingTerminalResult,
      operation: 'wait_terminal',
      timeout: const Duration(milliseconds: 10),
      onTimeout: timeout.complete,
    );

    final event = await timeout.future.timeout(const Duration(seconds: 1));
    expect(event.phase, PaymentPhase.waitingTerminalResult);
    expect(event.operation, 'wait_terminal');
    expect(event.outcome, PaymentTimeoutOutcome.indeterminate);
    expect(watchdog.isArmed, isFalse);
  });

  test('rearming replaces the previous deadline', () async {
    final watchdog = PaymentWatchdog();
    var firstFired = false;
    final second = Completer<PaymentWatchdogTimeout>();

    watchdog.arm(
      phase: PaymentPhase.connecting,
      operation: 'first',
      timeout: const Duration(milliseconds: 10),
      onTimeout: (_) => firstFired = true,
    );
    watchdog.arm(
      phase: PaymentPhase.waitingUser,
      operation: 'second',
      timeout: const Duration(milliseconds: 20),
      onTimeout: second.complete,
    );

    final event = await second.future.timeout(const Duration(seconds: 1));
    expect(firstFired, isFalse);
    expect(event.operation, 'second');
  });

  test('cancel prevents timeout delivery', () async {
    final watchdog = PaymentWatchdog();
    var fired = false;

    watchdog.arm(
      phase: PaymentPhase.connecting,
      operation: 'connect',
      timeout: const Duration(milliseconds: 10),
      onTimeout: (_) => fired = true,
    );
    watchdog.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(fired, isFalse);
    expect(watchdog.isArmed, isFalse);
  });
}
