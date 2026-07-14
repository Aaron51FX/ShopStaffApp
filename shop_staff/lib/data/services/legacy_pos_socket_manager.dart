import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

/// Fine-grained transport events emitted by [LegacyPosSocketManager].
enum LegacyPosTransportEventType {
  connecting,
  connected,
  writeStarted,
  writeCompleted,
  requestPayData,
  waitingForTerminal,
  loading,
  cancelAcknowledged,
  cancelWaitResult,
  success,
  cancelled,
  timeout,
  error,
  done,
}

enum LegacyPosLoadingState { finalizing, terminalProcessing }

class LegacyPosTransportEvent {
  const LegacyPosTransportEvent({
    required this.type,
    required this.phase,
    this.action,
    this.attempt,
    this.loadingState,
    this.message,
    this.payload,
    this.resultCode,
    this.mpfsCode,
    this.errorType,
    this.retryable,
  });

  final LegacyPosTransportEventType type;
  final PaymentPhase phase;
  final PosAction? action;
  final int? attempt;
  final LegacyPosLoadingState? loadingState;
  final String? message;
  final String? payload;
  final String? resultCode;
  final String? mpfsCode;
  final PaymentErrorType? errorType;
  final bool? retryable;
}

class LegacyPosTransportRun {
  const LegacyPosTransportRun({required this.events});

  final Stream<LegacyPosTransportEvent> events;
}

/// Legacy POS socket manager kept for compatibility with the existing payment
/// service. It now exposes a typed transport event stream so session runners can
/// reason about connect/write/wait phases directly instead of inferring them.
class LegacyPosSocketManager {
  LegacyPosSocketManager({Logger? logger})
    : _logger = logger ?? Logger('LegacyPosSocketManager');

  static const Duration _flushTimeout = Duration(seconds: 15);
  static const Duration _responseTimeout = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const Duration _waitingForTerminalDelay = Duration(milliseconds: 1300);
  static const Duration _fatalResultDelay = Duration(milliseconds: 2500);
  static const int _maxConnectAttempts = 3;
  static const Set<String> _requestPayDataPayments = {
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  };
  static const Set<String> _thincaCloudPayments = {
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  };
  static const Set<String> _cancelWaitCodes = {'L06'};
  static const Set<String> _fatalErrorCodes = {'L11', 'T10'};

  final Logger _logger;

  Socket? _socket;
  _LegacyPosSession? _session;
  bool _isConnected = false;
  int _connectAttempts = 0;

  Timer? _responseTimer;
  Timer? _waitingForTerminalTimer;
  Timer? _deferredErrorTimer;

  Future<void> dispose() async {
    await closePos();
  }

  Future<void> closePos() async {
    _cancelTimers();
    final session = _session;
    _clearSessionState();
    final socket = _socket;
    _socket = null;
    _isConnected = false;
    socket?.destroy();
    await session?.closeEvents();
  }

  LegacyPosTransportRun startTransportSession({
    required String payment,
    required String posIp,
    required int posPort,
    required String machineCode,
    required String requestData,
    bool isRetry = false,
  }) {
    final session = _LegacyPosSession(
      payment: payment,
      machineCode: machineCode,
      eventController: StreamController<LegacyPosTransportEvent>.broadcast(),
    );
    _session = session;
    session.payProcess = true;

    if (!isRetry) {
      _connectAttempts = 0;
    }

    _logger.fine(
      'Starting POS socket connect: ip=$posIp port=$posPort payment=$payment retry=$isRetry',
    );

    scheduleMicrotask(() async {
      if (!identical(_session, session)) {
        return;
      }
      if (_isConnected && _socket != null) {
        if (requestData.isNotEmpty) {
          await write(PosAction.writePay, requestData);
        }
        if (_requestPayDataPayments.contains(session.payment)) {
          _emitEvent(
            session,
            const LegacyPosTransportEvent(
              type: LegacyPosTransportEventType.requestPayData,
              phase: PaymentPhase.sending,
            ),
          );
        }
        _scheduleWaitingForTerminal(session);
        return;
      }

      await _connectAndListen(
        session: session,
        posIp: posIp,
        posPort: posPort,
        requestData: requestData,
      );
    });

    return LegacyPosTransportRun(events: session.eventController.stream);
  }

  Future<void> payConnectSocket(
    String payment,
    String posIp,
    int posPort,
    String machineCode,
    String questData, {
    required void Function(String) onError,
    required void Function(int) onLoading,
    required void Function() onLoadingEnd,
    required void Function(String) onSuccess,
    required void Function() onRequestPayData,
    required void Function(PosAction) onDone,
    required void Function(String, String) onCancel,
    void Function(String, String)? onCancelWaitResult,
    required void Function() onTimeOut,
    bool isRetry = false,
  }) async {
    final run = startTransportSession(
      payment: payment,
      posIp: posIp,
      posPort: posPort,
      machineCode: machineCode,
      requestData: questData,
      isRetry: isRetry,
    );

    run.events.listen((event) {
      switch (event.type) {
        case LegacyPosTransportEventType.requestPayData:
          onRequestPayData();
          break;
        case LegacyPosTransportEventType.waitingForTerminal:
          onLoadingEnd();
          break;
        case LegacyPosTransportEventType.loading:
          onLoading(_legacyLoadingModeForState(event.loadingState));
          break;
        case LegacyPosTransportEventType.cancelAcknowledged:
          onLoading(
            _legacyLoadingModeForState(LegacyPosLoadingState.finalizing),
          );
          break;
        case LegacyPosTransportEventType.cancelWaitResult:
          onCancelWaitResult?.call(
            event.resultCode ?? '',
            event.mpfsCode ?? '',
          );
          break;
        case LegacyPosTransportEventType.success:
          onSuccess(event.payload ?? '');
          break;
        case LegacyPosTransportEventType.cancelled:
          onCancel(event.resultCode ?? '', event.mpfsCode ?? '');
          break;
        case LegacyPosTransportEventType.timeout:
          onTimeOut();
          break;
        case LegacyPosTransportEventType.error:
          onError(event.message ?? event.resultCode ?? 'POS transport error');
          break;
        case LegacyPosTransportEventType.done:
          onDone(event.action ?? PosAction.none);
          break;
        case LegacyPosTransportEventType.writeStarted:
          if (event.action == PosAction.cancel) {
            onLoading(0);
          }
          break;
        case LegacyPosTransportEventType.connecting:
        case LegacyPosTransportEventType.connected:
        case LegacyPosTransportEventType.writeCompleted:
          break;
      }
    });
  }

  Future<void> write(
    PosAction action,
    String writeData, {
    Function? backTask,
  }) async {
    final session = _session;
    if (session == null) {
      backTask?.call();
      return;
    }

    session.action = action;
    if (action != PosAction.connect) {
      _connectAttempts = 0;
    }

    final phase = _phaseForAction(action);
    if (phase != null) {
      session.phase = phase;
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.writeStarted,
          action: action,
          phase: phase,
        ),
      );
    }

    if (!_isConnected || _socket == null) {
      if (action == PosAction.cancel) {
        if (backTask != null) {
          backTask.call();
        } else {
          _emitEvent(
            session,
            LegacyPosTransportEvent(
              type: LegacyPosTransportEventType.done,
              action: action,
              phase: session.phase,
            ),
          );
        }
        return;
      }
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.error,
          phase: session.phase,
          message: 'POS disconnected',
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
      return;
    }

    await _writePayload(session, writeData, action);
  }

  Future<void> _connectAndListen({
    required _LegacyPosSession session,
    required String posIp,
    required int posPort,
    required String requestData,
  }) async {
    session.action = PosAction.connect;
    session.phase = PaymentPhase.connecting;
    _connectAttempts++;
    _emitEvent(
      session,
      LegacyPosTransportEvent(
        type: LegacyPosTransportEventType.connecting,
        phase: session.phase,
        attempt: _connectAttempts,
      ),
    );

    if (_connectAttempts > _maxConnectAttempts) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.timeout,
          phase: session.phase,
          message: 'POS connect timeout',
          errorType: PaymentErrorType.network,
          retryable: true,
        ),
      );
      return;
    }

    try {
      final socket = await Socket.connect(
        posIp,
        posPort,
        timeout: _flushTimeout,
      );
      if (!identical(_session, session)) {
        socket.destroy();
        return;
      }

      _socket = socket;
      _isConnected = true;
      _logger.fine('POS socket connected');
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.connected,
          phase: session.phase,
          attempt: _connectAttempts,
        ),
      );

      if (requestData.isNotEmpty) {
        await write(PosAction.writePay, requestData);
      }

      if (_requestPayDataPayments.contains(session.payment)) {
        _emitEvent(
          session,
          const LegacyPosTransportEvent(
            type: LegacyPosTransportEventType.requestPayData,
            phase: PaymentPhase.sending,
          ),
        );
      }
      _scheduleWaitingForTerminal(session);

      socket.listen(
        (event) => _handleSocketData(session, event),
        onDone: () => _handleSocketDone(session),
        onError: (Object error) =>
            _handleSocketError(session, error.toString()),
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      _logger.warning('POS socket connect failed: $e');
      if (!identical(_session, session) || session.action == PosAction.none) {
        return;
      }
      Future<void>.delayed(_reconnectDelay, () {
        if (!identical(_session, session) || session.action == PosAction.none) {
          return;
        }
        unawaited(
          _connectAndListen(
            session: session,
            posIp: posIp,
            posPort: posPort,
            requestData: requestData,
          ),
        );
      });
    }
  }

  Future<void> _writePayload(
    _LegacyPosSession session,
    String payload,
    PosAction action,
  ) async {
    final socket = _socket;
    if (!_isConnected || socket == null) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.error,
          phase: session.phase,
          message: 'POS disconnected',
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
      return;
    }

    try {
      socket.write(payload);
      await socket.flush().timeout(_flushTimeout);
    } on TimeoutException {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.error,
          phase: session.phase,
          message: 'POS write timeout',
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
      return;
    } catch (e) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.error,
          phase: session.phase,
          message: e.toString(),
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
      return;
    }

    _emitEvent(
      session,
      LegacyPosTransportEvent(
        type: LegacyPosTransportEventType.writeCompleted,
        action: action,
        phase: session.phase,
      ),
    );
    _startResponseTimer(session);
  }

  void _handleSocketData(_LegacyPosSession session, List<int> event) {
    if (!identical(_session, session)) return;

    _stopResponseTimer();
    final eventString = _decodePayload(event);
    session.buffer += eventString;
    if (session.buffer.length < 16) {
      return;
    }

    final frame = _ParsedPosFrame.tryParse(session.buffer);
    if (frame == null) {
      return;
    }

    _logger.finer(
      'POS socket event type=${frame.transactionType} result=${frame.resultCode} mpfs=${frame.mpfsCode}',
    );

    if (frame.transactionType == '900') {
      _consumeCancelFrames(session);
      if (session.buffer.length < 16) {
        return;
      }
      final nextFrame = _ParsedPosFrame.tryParse(session.buffer);
      if (nextFrame == null) {
        return;
      }
      _logger.finer(
        'POS socket post-cancel event type=${nextFrame.transactionType} '
        'result=${nextFrame.resultCode} mpfs=${nextFrame.mpfsCode}',
      );
      if ((nextFrame.transactionType == '600' ||
              nextFrame.transactionType == '601') &&
          session.buffer.length > 4800) {
        _handleLongSuccessFrame(session, nextFrame, session.buffer);
        return;
      }
      if (nextFrame.transactionType != '900' &&
          nextFrame.transactionType != '600' &&
          nextFrame.transactionType != '601') {
        _handleGenericPaymentFrame(session, nextFrame, session.buffer);
      }
      return;
    }

    if ((frame.transactionType == '600' || frame.transactionType == '601') &&
        session.buffer.length > 4800) {
      _handleLongSuccessFrame(session, frame, eventString);
      return;
    }

    if (frame.transactionType != '900' &&
        frame.transactionType != '600' &&
        frame.transactionType != '601') {
      _handleGenericPaymentFrame(session, frame, eventString);
    }
  }

  void _consumeCancelFrames(_LegacyPosSession session) {
    while (identical(_session, session) && session.buffer.length >= 16) {
      final frame = _ParsedPosFrame.tryParse(session.buffer);
      if (frame == null || frame.transactionType != '900') {
        return;
      }

      final handling = _handleCancelFrame(session, frame);
      if (handling == null) {
        return;
      }

      session.buffer = handling.consumeFromBuffer(session.buffer);

      if (handling.clearSession) {
        _clearSessionState();
        return;
      }
    }
  }

  _LegacyPosFrameHandling? _handleCancelFrame(
    _LegacyPosSession session,
    _ParsedPosFrame frame,
  ) {
    if (frame.resultCode.trim() == '000') {
      final consumedLength = _resolveCancelAckLength(session.buffer);
      if (consumedLength == null) {
        return null;
      }
      if (session.action == PosAction.cancel) {
        session.phase = PaymentPhase.sending;
        _emitEvent(
          session,
          const LegacyPosTransportEvent(
            type: LegacyPosTransportEventType.cancelAcknowledged,
            phase: PaymentPhase.sending,
          ),
        );
        _startResponseTimer(session);
      }
      return _LegacyPosFrameHandling(consumedLength: consumedLength);
    }

    if (frame.resultCode.trim().isEmpty) {
      return _LegacyPosFrameHandling(consumedLength: 16);
    }

    final consumedLength = _nextFrameBoundary(session.buffer) ?? 16;

    if (_cancelWaitCodes.contains(frame.resultCode)) {
      session.phase = PaymentPhase.waitingTerminalResult;
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.cancelWaitResult,
          phase: session.phase,
          resultCode: frame.resultCode,
          mpfsCode: frame.mpfsCode,
        ),
      );
      _startResponseTimer(session);
      return _LegacyPosFrameHandling(consumedLength: consumedLength);
    }

    session.interactive = true;
    session.phase = PaymentPhase.waitingUser;
    _emitEvent(
      session,
      LegacyPosTransportEvent(
        type: LegacyPosTransportEventType.error,
        phase: session.phase,
        message: frame.resultCode,
        resultCode: frame.resultCode,
        mpfsCode: frame.mpfsCode,
        errorType: PaymentErrorType.device,
        retryable: true,
      ),
    );
    return _LegacyPosFrameHandling(
      consumedLength: consumedLength,
      clearSession: true,
    );
  }

  void _handleLongSuccessFrame(
    _LegacyPosSession session,
    _ParsedPosFrame frame,
    String eventString,
  ) {
    if (!frame.isSuccess) {
      if (frame.resultCode.trim().isNotEmpty) {
        session.interactive = true;
        session.phase = PaymentPhase.waitingUser;
        _emitEvent(
          session,
          LegacyPosTransportEvent(
            type: LegacyPosTransportEventType.cancelled,
            phase: session.phase,
            resultCode: frame.resultCode,
            mpfsCode: frame.mpfsCode,
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
          ),
        );
      }
      return;
    }

    session.phase = PaymentPhase.waitingUser;
    if (session.payment != '2') {
      _emitLoading(session, LegacyPosLoadingState.finalizing);
    }

    final payload = _thincaCloudPayments.contains(session.payment)
        ? _safePrefix(eventString, 169)
        : session.buffer;
    if (session.payProcess) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.success,
          phase: session.phase,
          payload: payload,
          resultCode: frame.resultCode,
          mpfsCode: frame.mpfsCode,
        ),
      );
    }
    _clearSessionState();
  }

  void _handleGenericPaymentFrame(
    _LegacyPosSession session,
    _ParsedPosFrame frame,
    String eventString,
  ) {
    session.phase = PaymentPhase.waitingUser;
    if (session.payment != '2') {
      _emitLoading(session, LegacyPosLoadingState.terminalProcessing);
    }

    if (frame.isSuccess) {
      final payload = _thincaCloudPayments.contains(session.payment)
          ? _safePrefix(eventString, 169)
          : eventString;
      if (session.payProcess) {
        _emitEvent(
          session,
          LegacyPosTransportEvent(
            type: LegacyPosTransportEventType.success,
            phase: session.phase,
            payload: payload,
            resultCode: frame.resultCode,
            mpfsCode: frame.mpfsCode,
          ),
        );
      }
      _clearSessionState();
      return;
    }

    if (frame.resultCode.trim().isEmpty) {
      return;
    }

    session.interactive = true;
    if (_fatalErrorCodes.contains(frame.resultCode)) {
      if (session.action == PosAction.cancel ||
          session.phase == PaymentPhase.waitingTerminalResult) {
        session.phase = PaymentPhase.waitingTerminalResult;
        _emitEvent(
          session,
          LegacyPosTransportEvent(
            type: LegacyPosTransportEventType.cancelled,
            phase: session.phase,
            resultCode: frame.resultCode,
            mpfsCode: frame.mpfsCode,
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
          ),
        );
        _clearSessionState();
        return;
      }
      _deferredErrorTimer?.cancel();
      _deferredErrorTimer = Timer(_fatalResultDelay, () {
        if (!identical(_session, session) || session.action == PosAction.none) {
          return;
        }
        _emitEvent(
          session,
          LegacyPosTransportEvent(
            type: LegacyPosTransportEventType.error,
            phase: session.phase,
            message: frame.resultCode,
            resultCode: frame.resultCode,
            mpfsCode: frame.mpfsCode,
            errorType: PaymentErrorType.device,
            retryable: true,
          ),
        );
      });
      return;
    }

    _emitEvent(
      session,
      LegacyPosTransportEvent(
        type: LegacyPosTransportEventType.cancelled,
        phase: session.phase,
        resultCode: frame.resultCode,
        mpfsCode: frame.mpfsCode,
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
      ),
    );
  }

  void _handleSocketDone(_LegacyPosSession session) {
    if (!identical(_session, session)) return;

    _stopResponseTimer();
    _connectAttempts = 0;
    _isConnected = false;
    if (session.phase == PaymentPhase.waitingTerminalResult &&
        session.action != PosAction.none) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.error,
          phase: session.phase,
          message: 'POS disconnected',
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
      return;
    }
    if (!session.interactive && session.action != PosAction.none) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.done,
          action: session.action,
          phase: session.phase,
        ),
      );
    }
  }

  void _handleSocketError(_LegacyPosSession session, String error) {
    if (!identical(_session, session)) return;

    _stopResponseTimer();
    _connectAttempts = 0;
    _isConnected = false;
    if (!session.interactive && session.action != PosAction.none) {
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.error,
          phase: session.phase,
          message: error,
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
    }
    session.interactive = true;
  }

  void _startResponseTimer(_LegacyPosSession session) {
    _responseTimer?.cancel();
    _responseTimer = Timer(_responseTimeout, () {
      if (!identical(_session, session)) return;
      _responseTimer = null;
      _emitEvent(
        session,
        LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.timeout,
          phase: session.phase,
          message: 'POS response timeout',
          errorType: _transportErrorTypeForPhase(session.phase),
          retryable: true,
        ),
      );
    });
  }

  void _stopResponseTimer() {
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  void _scheduleWaitingForTerminal(_LegacyPosSession session) {
    if (session.payment == '2') {
      return;
    }
    _waitingForTerminalTimer?.cancel();
    _waitingForTerminalTimer = Timer(_waitingForTerminalDelay, () {
      if (!identical(_session, session) || session.action == PosAction.none) {
        return;
      }
      session.phase = PaymentPhase.waitingUser;
      _emitEvent(
        session,
        const LegacyPosTransportEvent(
          type: LegacyPosTransportEventType.waitingForTerminal,
          phase: PaymentPhase.waitingUser,
        ),
      );
    });
  }

  void _emitLoading(_LegacyPosSession session, LegacyPosLoadingState state) {
    _emitEvent(
      session,
      LegacyPosTransportEvent(
        type: LegacyPosTransportEventType.loading,
        phase: session.phase,
        loadingState: state,
      ),
    );
  }

  int _legacyLoadingModeForState(LegacyPosLoadingState? state) {
    switch (state) {
      case LegacyPosLoadingState.terminalProcessing:
        return 1;
      case LegacyPosLoadingState.finalizing:
      case null:
        return 0;
    }
  }

  int? _resolveCancelAckLength(String buffer) {
    final nextBoundary = _nextFrameBoundary(buffer);
    if (nextBoundary != null) {
      return nextBoundary;
    }
    if (buffer.length >= 40) {
      return 40;
    }
    if (buffer.length == 16) {
      return 16;
    }
    return null;
  }

  int? _nextFrameBoundary(String buffer) {
    final boundary = buffer.indexOf('311', 1);
    if (boundary <= 0) {
      return null;
    }
    return boundary;
  }

  void _emitEvent(_LegacyPosSession session, LegacyPosTransportEvent event) {
    if (!identical(_session, session) || session.eventController.isClosed) {
      return;
    }
    session.eventController.add(event);
  }

  PaymentPhase? _phaseForAction(PosAction action) {
    switch (action) {
      case PosAction.connect:
        return PaymentPhase.connecting;
      case PosAction.writePay:
      case PosAction.cancel:
      case PosAction.close:
        return PaymentPhase.sending;
      case PosAction.none:
        return null;
    }
  }

  PaymentErrorType _transportErrorTypeForPhase(PaymentPhase phase) {
    switch (phase) {
      case PaymentPhase.connecting:
      case PaymentPhase.requesting:
      case PaymentPhase.sending:
        return PaymentErrorType.network;
      case PaymentPhase.waitingUser:
      case PaymentPhase.waitingTerminalResult:
      case PaymentPhase.reconciling:
      case PaymentPhase.confirming:
      case PaymentPhase.initializing:
        return PaymentErrorType.device;
    }
  }

  void _cancelTimers() {
    _responseTimer?.cancel();
    _responseTimer = null;
    _waitingForTerminalTimer?.cancel();
    _waitingForTerminalTimer = null;
    _deferredErrorTimer?.cancel();
    _deferredErrorTimer = null;
  }

  void _clearSessionState() {
    final session = _session;
    if (session == null) {
      _connectAttempts = 0;
      return;
    }
    session.payProcess = false;
    session.buffer = '';
    session.interactive = false;
    session.action = PosAction.none;
    _connectAttempts = 0;
    _deferredErrorTimer?.cancel();
    _deferredErrorTimer = null;
  }

  String _decodePayload(List<int> event) {
    final sanitized = event.map((byte) => byte > 127 ? 32 : byte).toList();
    return const Utf8Codec().decode(Uint8List.fromList(sanitized));
  }

  String _safePrefix(String value, int length) {
    if (value.length <= length) {
      return value;
    }
    return value.substring(0, length);
  }
}

class _LegacyPosSession {
  _LegacyPosSession({
    required this.payment,
    required this.machineCode,
    required this.eventController,
  });

  final String payment;
  final String machineCode;
  final StreamController<LegacyPosTransportEvent> eventController;

  bool interactive = false;
  bool payProcess = false;
  String buffer = '';
  PosAction action = PosAction.none;
  PaymentPhase phase = PaymentPhase.connecting;

  Future<void> closeEvents() async {
    if (!eventController.isClosed) {
      await eventController.close();
    }
  }
}

class _LegacyPosFrameHandling {
  const _LegacyPosFrameHandling({
    required this.consumedLength,
    this.clearSession = false,
  });

  final int consumedLength;
  final bool clearSession;

  String consumeFromBuffer(String buffer) {
    if (consumedLength >= buffer.length) {
      return '';
    }
    return buffer.substring(consumedLength);
  }
}

class _ParsedPosFrame {
  const _ParsedPosFrame({
    required this.firstFlag,
    required this.secondFlag,
    required this.transactionType,
    required this.resultCode,
    required this.mpfsCode,
  });

  final String firstFlag;
  final String secondFlag;
  final String transactionType;
  final String resultCode;
  final String mpfsCode;

  bool get isSuccess =>
      firstFlag == '3' &&
      secondFlag == '11' &&
      resultCode == '000' &&
      mpfsCode == '000';

  bool get isCancelAck =>
      firstFlag == '3' && secondFlag == '11' && resultCode == '000';

  static _ParsedPosFrame? tryParse(String buffer) {
    if (buffer.length < 16) {
      return null;
    }
    return _ParsedPosFrame(
      firstFlag: buffer.substring(0, 1),
      secondFlag: buffer.substring(1, 3),
      transactionType: buffer.substring(3, 6),
      resultCode: buffer.substring(10, 13),
      mpfsCode: buffer.substring(13, 16),
    );
  }
}

enum PosAction { connect, writePay, cancel, close, none }
