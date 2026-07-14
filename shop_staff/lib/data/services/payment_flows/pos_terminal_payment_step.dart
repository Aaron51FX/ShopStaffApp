import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/payments/payment_stage_policy.dart';
import 'package:shop_staff/domain/payments/payment_watchdog.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

import 'pos_payment_status_adapter.dart';

class PosTerminalPaymentStepConfig {
  const PosTerminalPaymentStepConfig({
    required this.startStatus,
    required this.startFailureMessageKey,
    required this.startStage,
    required this.waitingStage,
    this.startTimeout = const Duration(seconds: 20),
    this.inactivityTimeout = const Duration(seconds: 90),
  });

  final PaymentStatus startStatus;
  final String startFailureMessageKey;
  final String startStage;
  final String waitingStage;
  final Duration startTimeout;
  final Duration inactivityTimeout;
}

/// Shared lifecycle for POS-terminal-backed Card and QR payments.
///
/// A timeout after the request has reached the terminal does not cancel or
/// complete the transaction. It moves the session to `indeterminate`, keeps
/// the terminal subscription alive, and allows an explicit reconciliation
/// wait without risking a duplicate payment.
class PosTerminalPaymentStep {
  PosTerminalPaymentStep({
    required PosPaymentService service,
    required PosPaymentStatusAdapter adapter,
    required PosTerminalPaymentStepConfig config,
    required void Function(PaymentStatus status) emitStatus,
    required Future<void> Function(PaymentResult result) complete,
    Logger? logger,
  }) : _service = service,
       _adapter = adapter,
       _config = config,
       _emitStatus = emitStatus,
       _complete = complete,
       _logger = logger ?? Logger('PosTerminalPaymentStep');

  static const String _timeoutDetail = 'PAYMENT_STAGE_TIMEOUT';

  final PosPaymentService _service;
  final PosPaymentStatusAdapter _adapter;
  final PosTerminalPaymentStepConfig _config;
  final void Function(PaymentStatus status) _emitStatus;
  final Future<void> Function(PaymentResult result) _complete;
  final Logger _logger;
  final PaymentWatchdog _watchdog = PaymentWatchdog();

  StreamSubscription<PosPaymentStatus>? _subscription;
  String? _sessionId;
  bool _disposed = false;
  bool _indeterminate = false;

  bool get hasSession => _sessionId != null;
  bool get isIndeterminate => _indeterminate;

  Future<void> start(PosPaymentRequest request) async {
    if (_disposed) return;
    _emitStatus(_config.startStatus);
    _arm(
      phase: PaymentPhase.connecting,
      operation: _config.startStage,
      timeout: _config.startTimeout,
    );

    try {
      final session = await _service.startPayment(request);
      if (_disposed) return;
      _sessionId = session.sessionId;
      _arm(
        phase: PaymentPhase.waitingTerminalResult,
        operation: _config.waitingStage,
        timeout: _config.inactivityTimeout,
      );
      _subscription = _service
          .watchStatus(session.sessionId)
          .listen(
            _handleStatus,
            onError: _handleStreamError,
            onDone: _handleStreamDone,
          );
    } catch (error, stack) {
      if (_disposed) return;
      _logger.warning('Failed to start POS terminal payment', error, stack);
      await _completeKnownFailure(
        messageKey: _config.startFailureMessageKey,
        detail: error.toString(),
        stage: _config.startStage,
      );
    }
  }

  Future<void> cancel() async {
    final sessionId = _sessionId;
    if (_disposed || sessionId == null) return;
    _watchdog.cancel();
    await _service.cancel(sessionId);
  }

  Future<void> reconcile() async {
    if (_disposed || _sessionId == null || !_indeterminate) {
      throw StateError('PAYMENT_RECONCILE_NOT_AVAILABLE');
    }
    _indeterminate = false;
    _emitStatus(
      const PaymentStatus(
        type: PaymentStatusType.reconciling,
        messageKey: PaymentMessageKeys.posReconciling,
        phase: PaymentPhase.reconciling,
        certainty: PaymentOutcomeCertainty.indeterminate,
        recovery: PaymentRecovery.waitTerminal,
      ),
    );
    _arm(
      phase: PaymentPhase.reconciling,
      operation: '${_config.waitingStage}_reconcile',
      timeout: _config.inactivityTimeout,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _watchdog.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleStatus(PosPaymentStatus status) {
    if (_disposed) return;
    _indeterminate = false;
    final mapped = _adapter.map(status);
    _emitStatus(mapped);
    if (mapped.isTerminal) {
      _watchdog.cancel();
      final result = _adapter.toTerminalResult(status);
      if (result != null) unawaited(_complete(result));
      return;
    }
    _arm(
      phase: mapped.phase ?? PaymentPhase.waitingTerminalResult,
      operation: _config.waitingStage,
      timeout: _config.inactivityTimeout,
    );
  }

  void _handleStreamError(Object error, StackTrace stack) {
    if (_disposed) return;
    _logger.warning('POS terminal status stream failed', error, stack);
    unawaited(
      _completeIndeterminate(
        detail: error.toString(),
        stage: '${_config.waitingStage}_stream_error',
      ),
    );
  }

  void _handleStreamDone() {
    if (_disposed) return;
    unawaited(
      _completeIndeterminate(
        detail: 'POS_STREAM_CLOSED',
        stage: '${_config.waitingStage}_stream_closed',
      ),
    );
  }

  void _arm({
    required PaymentPhase phase,
    required String operation,
    required Duration timeout,
  }) {
    _watchdog.arm(
      phase: phase,
      operation: operation,
      timeout: timeout,
      onTimeout: _handleTimeout,
    );
  }

  void _handleTimeout(PaymentWatchdogTimeout timeout) {
    if (_disposed) return;
    _logger.warning('POS terminal stage timed out: ${timeout.operation}');
    if (timeout.certainty == PaymentOutcomeCertainty.indeterminate) {
      _indeterminate = true;
      _emitStatus(
        PaymentStatus(
          type: PaymentStatusType.indeterminate,
          messageKey: PaymentMessageKeys.posResultIndeterminate,
          messageArgs: const {'detail': _timeoutDetail},
          details: {'stage': timeout.operation},
          errorType: PaymentErrorType.device,
          retryable: false,
          phase: timeout.phase,
          certainty: PaymentOutcomeCertainty.indeterminate,
          recovery: PaymentRecovery.reconcileResult,
        ),
      );
      return;
    }
    if (timeout.outcome == PaymentTimeoutOutcome.cancelled) {
      unawaited(_completeCancelledTimeout(timeout));
      return;
    }
    unawaited(
      _completeKnownFailure(
        messageKey: PaymentMessageKeys.posTimeout,
        detail: _timeoutDetail,
        stage: timeout.operation,
      ),
    );
  }

  Future<void> _completeCancelledTimeout(PaymentWatchdogTimeout timeout) async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      try {
        await _service.cancel(sessionId);
      } catch (error, stack) {
        _logger.warning('Failed to cancel timed-out POS session', error, stack);
      }
    }
    _emitStatus(
      PaymentStatus(
        type: PaymentStatusType.cancelled,
        messageKey: _adapter.config.cancelledMessageKey,
        messageArgs: const {'detail': _timeoutDetail},
        details: {'stage': timeout.operation},
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
        phase: timeout.phase,
        certainty: PaymentOutcomeCertainty.known,
        recovery: PaymentRecovery.restartPayment,
      ),
    );
    await _complete(
      PaymentResult.cancelled(
        messageKey: _adapter.config.cancelledMessageKey,
        messageArgs: const {'detail': _timeoutDetail},
        payload: {'stage': timeout.operation},
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
      ),
    );
  }

  Future<void> _completeKnownFailure({
    required String messageKey,
    required String detail,
    required String stage,
  }) async {
    _emitStatus(
      PaymentStatus(
        type: PaymentStatusType.failure,
        messageKey: messageKey,
        messageArgs: {'detail': detail},
        details: {'stage': stage},
        errorType: PaymentErrorType.device,
        retryable: true,
        certainty: PaymentOutcomeCertainty.known,
        recovery: PaymentRecovery.retryCurrentStep,
      ),
    );
    await _complete(
      PaymentResult.failure(
        messageKey: messageKey,
        messageArgs: {'detail': detail},
        payload: {'stage': stage},
        errorType: PaymentErrorType.device,
        retryable: true,
      ),
    );
  }

  Future<void> _completeIndeterminate({
    required String detail,
    required String stage,
  }) async {
    _indeterminate = true;
    _emitStatus(
      PaymentStatus(
        type: PaymentStatusType.indeterminate,
        messageKey: PaymentMessageKeys.posResultIndeterminate,
        messageArgs: {'detail': detail},
        details: {'stage': stage},
        errorType: PaymentErrorType.device,
        retryable: false,
        phase: PaymentPhase.waitingTerminalResult,
        certainty: PaymentOutcomeCertainty.indeterminate,
        recovery: PaymentRecovery.contactSupervisor,
      ),
    );
    await _complete(
      PaymentResult.indeterminate(
        messageKey: PaymentMessageKeys.posResultIndeterminate,
        messageArgs: {'detail': detail},
        payload: {'stage': stage},
        errorType: PaymentErrorType.device,
        recovery: PaymentRecovery.contactSupervisor,
      ),
    );
  }
}
