import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

/// Legacy POS socket manager extracted from the previous implementation.
/// Emits lifecycle callbacks for connection, loading indicators, success and errors.
class LegacyPosSocketManager {
  LegacyPosSocketManager({Logger? logger}) : _logger = logger ?? Logger('LegacyPosSocketManager');

  final Logger _logger;

  Socket? _socket;
  bool _isConnected = false;
  bool _needInterActive = false;
  bool _payProcess = false;

  int _socketNumberTimes = 0;
  String _eventReportString = '';
  PosAction _posAction = PosAction.none;

  Timer? _responseTimer;
  final Duration _flushTimeout = const Duration(seconds: 15);
  final Duration _responseTimeout = const Duration(seconds: 30);

  Future<void> dispose() async {
    await closePos();
  }

  Future<void> resetState() async {
    _payProcess = false;
    _eventReportString = '';
    _needInterActive = false;
    _posAction = PosAction.none;
    _socketNumberTimes = 0;
  }

  void _startResponseTimer(void Function(String) onError) {
    _responseTimer?.cancel();
    _responseTimer = Timer(_responseTimeout, () {
      _responseTimer = null;
      onError('POS response timeout');
    });
  }

  void _stopResponseTimer() {
    _responseTimer?.cancel();
    _responseTimer = null;
  }

  Future<void> closePos() async {
    await resetState();
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
  }

  Future<void> write(PosAction action, String payload, {required void Function(String) onError}) async {
  _posAction = action;
    final s = _socket;
    if (s == null || !_isConnected) {
      onError('POS disconnected');
      return;
    }
    try {
      s.write(payload);
      await s.flush().timeout(_flushTimeout);
    } on TimeoutException {
      onError('POS write timeout');
      return;
    } catch (e) {
      onError(e.toString());
      return;
    }
    _startResponseTimer(onError);
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
    _logger.fine('Starting POS socket connect: ip=$posIp port=$posPort payment=$payment');
    _eventReportString = '';
    _payProcess = true;

    if (!isRetry) {
      _socketNumberTimes = 0;
    }

    if (_isConnected) {
      _logger.fine('Socket already connected, writing questData');
      if (questData.isNotEmpty) {
        _posAction = PosAction.writePay;
        await write(PosAction.writePay, questData, onError: onError);
      }
      if (payment != '2') {
        Future<void>.delayed(const Duration(milliseconds: 1300), onLoadingEnd);
      }
      return;
    }

    await _connectAndListen(
      payment,
      posIp,
      posPort,
      machineCode,
      questData,
      onError: onError,
      onLoading: onLoading,
      onLoadingEnd: onLoadingEnd,
      onSuccess: onSuccess,
      onRequestPayData: onRequestPayData,
      onDone: onDone,
      onTimeOut: onTimeOut,
      onCancel: onCancel,
    );
  }

  Future<void> _connectAndListen(
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
    required void Function() onTimeOut,
    required void Function(String, String) onCancel,
  }) async {
    _posAction = PosAction.connect;
    _socketNumberTimes++;
    if (_socketNumberTimes > 3) {
      onTimeOut();
      return;
    }

    try {
      final socket = await Socket.connect(posIp, posPort, timeout: const Duration(seconds: 15));
      _socket = socket;
      _isConnected = true;
      _logger.fine('POS socket connected');

      if (questData.isNotEmpty) {
        _posAction = PosAction.writePay;
        await write(PosAction.writePay, questData, onError: onError);
      }

      const paymentMethod = ['3', '4', '5', '6', '7', '8', '9', '10'];
      if (paymentMethod.contains(payment)) {
        onRequestPayData();
      }

      if (payment != '2') {
        Future<void>.delayed(const Duration(milliseconds: 1300), onLoadingEnd);
      }

      socket.listen(
        (event) {
          _stopResponseTimer();
          final sanitized = event.map((e) => e > 127 ? 32 : e).toList();
          final eventString = Utf8Codec().decode(Uint8List.fromList(sanitized));
          _logger.finer('POS socket event: $eventString');
          _eventReportString += eventString;
          if (_eventReportString.isEmpty) return;
          if (_eventReportString.length < 16) return;
          final first = _eventReportString.substring(0, 1);
          final second = _eventReportString.substring(1, 3);
          final transactionType = _eventReportString.substring(3, 6);
          final resultString = _eventReportString.substring(10, 13);
          final resultMPFSString = _eventReportString.substring(13, 16);
          _logger.finer('Transaction $transactionType result=$resultString mpfs=$resultMPFSString');

          if (transactionType == '900') {
            if (first == '3' && second == '11' && resultString == '000' && _eventReportString.length == 40) {
              if (_posAction == PosAction.cancel) onLoading(0);
            } else if (resultString.trim() != '000') {
              const posErrorCode = ['L06'];
              if (posErrorCode.contains(resultString)) {
                _needInterActive = true;
                onCancel(resultString, resultMPFSString);
              }
            } else {
              if (_posAction == PosAction.cancel) onLoading(0);
            }
          } else if ((transactionType == '600' || transactionType == '601') && _eventReportString.length > 4800) {
            if (first == '3' && second == '11' && resultString == '000' && resultMPFSString == '000') {
              if (payment != '2') {
                onLoading(0);
              }
              const thincaCloud = ['5', '6', '7', '8', '9', '10'];
              if (thincaCloud.contains(payment)) {
                final reportString = eventString.substring(0, 169);
                if (_payProcess) onSuccess(reportString);
              } else {
                if (_payProcess) onSuccess(_eventReportString);
              }
              resetState();
              _eventReportString = '';
            } else {
              if (resultString.trim().isNotEmpty) {
                _needInterActive = true;
                onCancel(resultString, resultMPFSString);
              }
            }
          } else if (transactionType != '900' && transactionType != '600' && transactionType != '601') {
            if (payment != '2') {
              onLoading(1);
            }
            if (first == '3' && second == '11' && resultString == '000' && resultMPFSString == '000') {
              const thincaCloud = ['5', '6', '7', '8', '9', '10'];
              if (thincaCloud.contains(payment)) {
                final reportString = eventString.substring(0, 169);
                if (_payProcess) onSuccess(reportString);
              } else {
                if (_payProcess) onSuccess(eventString);
              }
              resetState();
              _eventReportString = '';
            } else {
              if (resultString.trim().isNotEmpty) {
                _needInterActive = true;
                const posErrorCode = ['L11', 'T10'];
                if (posErrorCode.contains(resultString)) {
                  Future<void>.delayed(const Duration(milliseconds: 2500), () {
                    if (_posAction != PosAction.none) {
                      onError(resultString);
                    }
                  });
                } else {
                  onCancel(resultString, resultMPFSString);
                }
              }
            }
          }
        },
        onDone: () {
          _stopResponseTimer();
          _socketNumberTimes = 0;
          _isConnected = false;
          if (!_needInterActive && _posAction != PosAction.none) {
            onDone(_posAction);
          }
        },
        onError: (error) {
          _stopResponseTimer();
          _socketNumberTimes = 0;
          _isConnected = false;
          if (!_needInterActive && _posAction != PosAction.none) {
            onError(error.toString());
          }
          _needInterActive = true;
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      _logger.warning('POS socket connect failed: $e');
      if (_posAction == PosAction.none) return;
      Future<void>.delayed(const Duration(milliseconds: 2000), () {
        payConnectSocket(
          payment,
          posIp,
          posPort,
          machineCode,
          questData,
          onError: onError,
          onLoading: onLoading,
          onLoadingEnd: onLoadingEnd,
          onSuccess: onSuccess,
          onRequestPayData: onRequestPayData,
          onDone: onDone,
          onTimeOut: onTimeOut,
          onCancel: onCancel,
          isRetry: true,
        );
      });
    }
  }
}

enum PosAction { connect, writePay, cancel, close, none }
