import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

/// Legacy POS socket manager kept for compatibility with the existing payment
/// service. Internally it now uses an explicit session model so connection
/// retries, write timeouts, and frame parsing are easier to reason about.
class LegacyPosSocketManager {
  LegacyPosSocketManager({Logger? logger})
      : _logger = logger ?? Logger('LegacyPosSocketManager');

  static const Duration _flushTimeout = Duration(seconds: 15);
  static const Duration _responseTimeout = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const Duration _loadingEndDelay = Duration(milliseconds: 1300);
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
  static const Set<String> _cancelOnlyCodes = {'L06'};
  static const Set<String> _fatalErrorCodes = {'L11', 'T10'};

  final Logger _logger;

  Socket? _socket;
  _LegacyPosSession? _session;
  bool _isConnected = false;
  int _connectAttempts = 0;

  Timer? _responseTimer;
  Timer? _loadingEndTimer;
  Timer? _deferredErrorTimer;

  Future<void> dispose() async {
    await closePos();
  }

  Future<void> closePos() async {
    _cancelTimers();
    _clearSessionState();
    final socket = _socket;
    _socket = null;
    _isConnected = false;
    socket?.destroy();
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

    if (!_isConnected || _socket == null) {
      if (action == PosAction.cancel) {
        if (backTask != null) {
          backTask.call();
        } else {
          session.callbacks.onDone(action);
        }
        return;
      }
      session.callbacks.onError('POS disconnected');
      return;
    }

    if (action == PosAction.cancel) {
      session.callbacks.onLoading(0);
    }

    await _writePayload(session, writeData);
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
    required void Function() onTimeOut,
    bool isRetry = false,
  }) async {
    final session = _LegacyPosSession(
      payment: payment,
      machineCode: machineCode,
      callbacks: _LegacyPosCallbacks(
        onError: onError,
        onLoading: onLoading,
        onLoadingEnd: onLoadingEnd,
        onSuccess: onSuccess,
        onRequestPayData: onRequestPayData,
        onDone: onDone,
        onCancel: onCancel,
        onTimeOut: onTimeOut,
      ),
    );
    _session = session;
    session.payProcess = true;

    if (!isRetry) {
      _connectAttempts = 0;
    }

    _logger.fine(
      'Starting POS socket connect: ip=$posIp port=$posPort payment=$payment retry=$isRetry',
    );

    if (_isConnected && _socket != null) {
      if (questData.isNotEmpty) {
        await write(PosAction.writePay, questData);
      }
      _scheduleLoadingEnd(session);
      return;
    }

    await _connectAndListen(
      session: session,
      posIp: posIp,
      posPort: posPort,
      questData: questData,
    );
  }

  Future<void> _connectAndListen({
    required _LegacyPosSession session,
    required String posIp,
    required int posPort,
    required String questData,
  }) async {
    session.action = PosAction.connect;
    _connectAttempts++;
    if (_connectAttempts > _maxConnectAttempts) {
      session.callbacks.onTimeOut();
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

      if (questData.isNotEmpty) {
        await write(PosAction.writePay, questData);
      }

      if (_requestPayDataPayments.contains(session.payment)) {
        session.callbacks.onRequestPayData();
      }
      _scheduleLoadingEnd(session);

      socket.listen(
        (event) => _handleSocketData(session, event),
        onDone: () => _handleSocketDone(session),
        onError: (Object error) => _handleSocketError(session, error.toString()),
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
            questData: questData,
          ),
        );
      });
    }
  }

  Future<void> _writePayload(
    _LegacyPosSession session,
    String payload,
  ) async {
    final socket = _socket;
    if (!_isConnected || socket == null) {
      session.callbacks.onError('POS disconnected');
      return;
    }

    try {
      socket.write(payload);
      await socket.flush().timeout(_flushTimeout);
    } on TimeoutException {
      session.callbacks.onError('POS write timeout');
      return;
    } catch (e) {
      session.callbacks.onError(e.toString());
      return;
    }

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
      _handleCancelFrame(session, frame);
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

  void _handleCancelFrame(_LegacyPosSession session, _ParsedPosFrame frame) {
    if (frame.isCancelAck && session.buffer.length == 40) {
      if (session.action == PosAction.cancel) {
        session.callbacks.onLoading(0);
      }
      return;
    }

    if (frame.resultCode.trim() == '000') {
      if (session.action == PosAction.cancel) {
        session.callbacks.onLoading(0);
      }
      return;
    }

    if (_cancelOnlyCodes.contains(frame.resultCode)) {
      session.interactive = true;
      session.callbacks.onCancel(frame.resultCode, frame.mpfsCode);
    }
  }

  void _handleLongSuccessFrame(
    _LegacyPosSession session,
    _ParsedPosFrame frame,
    String eventString,
  ) {
    if (!frame.isSuccess) {
      if (frame.resultCode.trim().isNotEmpty) {
        session.interactive = true;
        session.callbacks.onCancel(frame.resultCode, frame.mpfsCode);
      }
      return;
    }

    if (session.payment != '2') {
      session.callbacks.onLoading(0);
    }

    final payload = _thincaCloudPayments.contains(session.payment)
        ? _safePrefix(eventString, 169)
        : session.buffer;
    if (session.payProcess) {
      session.callbacks.onSuccess(payload);
    }
    _clearSessionState();
  }

  void _handleGenericPaymentFrame(
    _LegacyPosSession session,
    _ParsedPosFrame frame,
    String eventString,
  ) {
    if (session.payment != '2') {
      session.callbacks.onLoading(1);
    }

    if (frame.isSuccess) {
      final payload = _thincaCloudPayments.contains(session.payment)
          ? _safePrefix(eventString, 169)
          : eventString;
      if (session.payProcess) {
        session.callbacks.onSuccess(payload);
      }
      _clearSessionState();
      return;
    }

    if (frame.resultCode.trim().isEmpty) {
      return;
    }

    session.interactive = true;
    if (_fatalErrorCodes.contains(frame.resultCode)) {
      _deferredErrorTimer?.cancel();
      _deferredErrorTimer = Timer(_fatalResultDelay, () {
        if (!identical(_session, session) || session.action == PosAction.none) {
          return;
        }
        session.callbacks.onError(frame.resultCode);
      });
      return;
    }

    session.callbacks.onCancel(frame.resultCode, frame.mpfsCode);
  }

  void _handleSocketDone(_LegacyPosSession session) {
    if (!identical(_session, session)) return;

    _stopResponseTimer();
    _connectAttempts = 0;
    _isConnected = false;
    if (!session.interactive && session.action != PosAction.none) {
      session.callbacks.onDone(session.action);
    }
  }

  void _handleSocketError(_LegacyPosSession session, String error) {
    if (!identical(_session, session)) return;

    _stopResponseTimer();
    _connectAttempts = 0;
    _isConnected = false;
    if (!session.interactive && session.action != PosAction.none) {
      session.callbacks.onError(error);
    }
    session.interactive = true;
  }

  void _startResponseTimer(_LegacyPosSession session) {
    _responseTimer?.cancel();
    _responseTimer = Timer(_responseTimeout, () {
      if (!identical(_session, session)) return;
      _responseTimer = null;
      session.callbacks.onError('POS response timeout');
    });
  }

  void _stopResponseTimer() {
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  void _scheduleLoadingEnd(_LegacyPosSession session) {
    if (session.payment == '2') {
      return;
    }
    _loadingEndTimer?.cancel();
    _loadingEndTimer = Timer(_loadingEndDelay, () {
      if (!identical(_session, session) || session.action == PosAction.none) {
        return;
      }
      session.callbacks.onLoadingEnd();
    });
  }

  void _cancelTimers() {
    _responseTimer?.cancel();
    _responseTimer = null;
    _loadingEndTimer?.cancel();
    _loadingEndTimer = null;
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
    required this.callbacks,
  });

  final String payment;
  final String machineCode;
  final _LegacyPosCallbacks callbacks;

  bool interactive = false;
  bool payProcess = false;
  String buffer = '';
  PosAction action = PosAction.none;
}

class _LegacyPosCallbacks {
  const _LegacyPosCallbacks({
    required this.onError,
    required this.onLoading,
    required this.onLoadingEnd,
    required this.onSuccess,
    required this.onRequestPayData,
    required this.onDone,
    required this.onCancel,
    required this.onTimeOut,
  });

  final void Function(String) onError;
  final void Function(int) onLoading;
  final void Function() onLoadingEnd;
  final void Function(String) onSuccess;
  final void Function() onRequestPayData;
  final void Function(PosAction) onDone;
  final void Function(String, String) onCancel;
  final void Function() onTimeOut;
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
