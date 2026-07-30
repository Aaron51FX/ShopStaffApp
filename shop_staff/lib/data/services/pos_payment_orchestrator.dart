import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:shop_staff/core/async/buffered_broadcast_controller.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';

class PosPaymentOrchestrator implements PaymentOrchestrator {
  PosPaymentOrchestrator({
    required Map<String, PaymentFlow> flows,
    Logger? logger,
  }) : _flows = flows,
       _logger = logger ?? Logger('PosPaymentOrchestrator');

  final Map<String, PaymentFlow> _flows;
  final Logger _logger;
  final Map<String, _PaymentSessionEntry> _sessions = {};
  final Random _random = Random();

  @override
  PaymentSessionHandle start(PaymentContext context) {
    final key = context.mode == PaymentFlowMode.bookkeeping
        ? PaymentChannels.bookkeeping
        : context.channel.group;
    final flow = _flows[key];
    if (flow == null) {
      throw StateError('PAYMENT_CHANNEL_UNSUPPORTED');
    }

    final run = flow.start(context);
    final sessionId = _generateSessionId();
    final controller = BufferedBroadcastController<PaymentStatus>();
    final entry = _PaymentSessionEntry(run: run, controller: controller);
    _sessions[sessionId] = entry;

    final initialStatus = PaymentStatus(
      type: PaymentStatusType.pending,
      messageKey: PaymentMessageKeys.flowStarted,
      messageArgs: {
        'channel': context.channel.displayName ?? context.channel.group,
      },
      phase: PaymentPhase.initializing,
    );
    entry.lastStatus = initialStatus;

    entry.subscription = run.statuses.listen(
      (status) {
        entry.lastStatus = status;
        controller.add(status);
      },
      onError: (error, stack) {
        _logger.warning('支付状态流异常: $error', error, stack);
        _handleUnexpectedStatusFailure(entry);
      },
      onDone: () {
        scheduleMicrotask(() => _handleUnexpectedStatusFailure(entry));
      },
    );

    run.result
        .then((result) {
          if (!entry.completer.isCompleted) {
            entry.completer.complete(result);
          }
          if (entry.lastStatus?.isTerminal != true &&
              entry.lastStatus?.type != result.status) {
            controller.add(_statusFromResult(result));
          }
        })
        .catchError((error, stack) {
          _logger.severe('支付流程执行失败', error, stack);
          if (!entry.completer.isCompleted) {
            final result = _unexpectedTerminalResult(entry.lastStatus);
            entry.completer.complete(result);
            controller.add(_statusFromResult(result));
          }
        })
        .whenComplete(() async {
          await entry.subscription?.cancel();
          if (!controller.isClosed) {
            await controller.close();
          }
          _sessions.remove(sessionId);
        });

    entry.finalize = run.finalize;
    entry.reconcile = run.reconcile;

    return PaymentSessionHandle(
      sessionId: sessionId,
      initialStatus: initialStatus,
      statuses: controller.stream,
      result: entry.completer.future,
      cancel: () => cancel(sessionId),
      finalize: run.finalize == null ? null : () => finalize(sessionId),
      reconcile: run.reconcile == null ? null : () => reconcile(sessionId),
      requiresManualCompletion: run.finalize != null,
    );
  }

  @override
  Stream<PaymentStatus> watch(String sessionId) {
    final entry = _sessions[sessionId];
    if (entry == null) {
      return Stream<PaymentStatus>.value(
        const PaymentStatus(
          type: PaymentStatusType.failure,
          messageKey: PaymentMessageKeys.sessionMissing,
          errorType: PaymentErrorType.unknown,
          retryable: true,
        ),
      );
    }
    return entry.controller.stream;
  }

  @override
  Future<PaymentResult> result(String sessionId) {
    final entry = _sessions[sessionId];
    if (entry == null) {
      return Future.value(
        PaymentResult.failure(
          messageKey: PaymentMessageKeys.sessionMissing,
          errorType: PaymentErrorType.unknown,
          retryable: true,
        ),
      );
    }
    return entry.completer.future;
  }

  @override
  Future<void> cancel(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) {
      throw StateError('POS_SESSION_MISSING');
    }
    try {
      await entry.run.cancel();
    } catch (e, stack) {
      _logger.warning('取消支付流程失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> finalize(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) {
      throw StateError('POS_SESSION_MISSING');
    }
    final finalize = entry.finalize;
    if (finalize == null) {
      throw StateError('PAYMENT_FINALIZE_NOT_REQUIRED');
    }
    try {
      await finalize();
    } catch (e, stack) {
      _logger.warning('支付流程确认失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> reconcile(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) {
      throw StateError('POS_SESSION_MISSING');
    }
    final reconcile = entry.reconcile;
    if (reconcile == null) {
      throw StateError('PAYMENT_RECONCILE_NOT_AVAILABLE');
    }
    await reconcile();
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1 << 32);
    return '$timestamp-$randomPart';
  }

  void _handleUnexpectedStatusFailure(_PaymentSessionEntry entry) {
    if (entry.completer.isCompleted || entry.controller.isClosed) return;
    if (_hasUncertainOutcome(entry.lastStatus)) {
      final status = const PaymentStatus(
        type: PaymentStatusType.indeterminate,
        messageKey: PaymentMessageKeys.errorRuntime,
        errorType: PaymentErrorType.unknown,
        retryable: false,
        certainty: PaymentOutcomeCertainty.indeterminate,
        recovery: PaymentRecovery.contactSupervisor,
      );
      entry.lastStatus = status;
      entry.controller.add(status);
      return;
    }
    final result = PaymentResult.failure(
      messageKey: PaymentMessageKeys.errorRuntime,
      errorType: PaymentErrorType.unknown,
      retryable: true,
      recovery: PaymentRecovery.restartPayment,
      certainty: PaymentOutcomeCertainty.known,
    );
    entry.completer.complete(result);
    entry.controller.add(_statusFromResult(result));
  }

  PaymentResult _unexpectedTerminalResult(PaymentStatus? lastStatus) {
    if (_hasUncertainOutcome(lastStatus)) {
      return PaymentResult.indeterminate(
        messageKey: PaymentMessageKeys.errorRuntime,
        errorType: PaymentErrorType.unknown,
        recovery: PaymentRecovery.contactSupervisor,
      );
    }
    return PaymentResult.failure(
      messageKey: PaymentMessageKeys.errorRuntime,
      errorType: PaymentErrorType.unknown,
      retryable: true,
      recovery: PaymentRecovery.restartPayment,
      certainty: PaymentOutcomeCertainty.known,
    );
  }

  bool _hasUncertainOutcome(PaymentStatus? status) {
    if (status?.certainty == PaymentOutcomeCertainty.indeterminate) return true;
    final phase = status?.phase;
    return phase != null &&
        phase.policy.timeoutOutcome == PaymentTimeoutOutcome.indeterminate;
  }

  PaymentStatus _statusFromResult(PaymentResult result) {
    switch (result.status) {
      case PaymentStatusType.success:
        return PaymentStatus(
          type: PaymentStatusType.success,
          message: result.message,
          messageKey: result.messageKey,
          messageArgs: result.messageArgs,
          details: result.payload,
        );
      case PaymentStatusType.cancelled:
        return PaymentStatus(
          type: PaymentStatusType.cancelled,
          message: result.message,
          messageKey: result.messageKey,
          messageArgs: result.messageArgs,
          details: result.payload,
          errorType: result.errorType,
          retryable: result.retryable,
        );
      case PaymentStatusType.failure:
        return PaymentStatus(
          type: PaymentStatusType.failure,
          message: result.message,
          messageKey: result.messageKey,
          messageArgs: result.messageArgs,
          details: result.payload,
          errorType: result.errorType,
          retryable: result.retryable,
          certainty: result.failure?.certainty,
          recovery: result.failure?.recovery,
        );
      case PaymentStatusType.indeterminate:
        return PaymentStatus(
          type: PaymentStatusType.indeterminate,
          message: result.message,
          messageKey: result.messageKey,
          messageArgs: result.messageArgs,
          details: result.payload,
          errorType: result.errorType,
          retryable: false,
          certainty: PaymentOutcomeCertainty.indeterminate,
          recovery: result.failure?.recovery,
        );
      case PaymentStatusType.reconciling:
      case PaymentStatusType.initialized:
      case PaymentStatusType.pending:
      case PaymentStatusType.waitingForUser:
      case PaymentStatusType.processing:
        return PaymentStatus(
          type: result.status,
          message: result.message,
          messageKey: result.messageKey,
          messageArgs: result.messageArgs,
          details: result.payload,
        );
    }
  }
}

class _PaymentSessionEntry {
  _PaymentSessionEntry({required this.run, required this.controller});

  final PaymentFlowRun run;
  final BufferedBroadcastController<PaymentStatus> controller;
  final Completer<PaymentResult> completer = Completer<PaymentResult>();
  StreamSubscription<PaymentStatus>? subscription;
  PaymentStatus? lastStatus;
  Future<void> Function()? finalize;
  Future<void> Function()? reconcile;
}
