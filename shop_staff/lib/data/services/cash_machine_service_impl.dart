import 'dart:async';

import 'package:cash_changer/cash_changer.dart';
import 'package:cash_changer/cash_changer_define.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';

/// Emits granular cash-machine states and orchestrates hardware operations.
class CashMachineServiceImpl implements CashMachineService {
  CashMachineServiceImpl(Logger logger)
    : _logger = logger,
      _eventsController = StreamController<CashMachineEvent>.broadcast();

  final Logger _logger;
  final StreamController<CashMachineEvent> _eventsController;
  bool _isRunning = false;
  bool _awaitingCompletion = false;
  CashMachineReceipt? _pendingReceipt;
  //int? _expectedAmount;

  @override
  Stream<CashMachineEvent> get events => _eventsController.stream;

  @override
  Future<CashMachineInitResult> initialize() async {
    _emitStage(CashMachineStage.checking, '正在检查现金机状态…');
    try {
      final status = await CashChanger.checkChangerStatus;

      final recovered = await _recoverIfNeeded(status.error?.code ?? 0);

      if (recovered.isSuccess) {
        _emitStage(CashMachineStage.idle, '现金机可用');
        return const CashMachineInitResult(isReady: true);
      } else if (recovered.message != 'continue') {
          // continue to open
          final message = recovered.message ?? '现金机恢复失败';
          _emitError(message);
          return CashMachineInitResult(isReady: false, message: message);
        
      }

      final open = await CashChanger.openCashChanger();
      final openCode = open.error?.code ?? -1;
      if (!open.isSuccess) {
        if (openCode == 225) {
          // openCode opened
        } else {
          final message = _messageFromError(open.error);
          _emitError(message);
          return CashMachineInitResult(isReady: false, message: message);
        }
      }

      await Future.delayed(Duration(milliseconds: 200));
      if (openCode != 225) {
        // already opened
        final start = await CashChanger.startDeposit();
        if (!start.isSuccess) {
          final message = _messageFromError(start.error);
          _emitError(message);
          return CashMachineInitResult(isReady: false, message: message);
        }
      }

      await Future.delayed(Duration(milliseconds: 200));
      final deposit = await CashChanger.depositAmount;
      if (!deposit.isSuccess) _failAndThrow(deposit.error);

      await Future.delayed(Duration(milliseconds: 200));
      final endDeposit = await CashChanger.endDeposit(
        DepositAction.repay.index,
      );
      if (!endDeposit.isSuccess) _failAndThrow(endDeposit.error);

      _emitStage(CashMachineStage.idle, '现金机可用');
      return const CashMachineInitResult(isReady: true);
    } catch (e, s) {
      _logger.severe('Cash init error', e, s);
      final message = '现金机检测异常: $e';
      _emitError(message);
      return CashMachineInitResult(isReady: false, message: message);
    }
  }

  @override
  Future<CashMachineReceipt> runPayment(int expectedAmount) async {
    debugPrint('---CashMachineServiceImpl.runPayment expectedAmount $expectedAmount called---');
    _logger.info('Starting cash payment sequence for amount: $expectedAmount');
    if (_isRunning || _awaitingCompletion) {
      throw StateError('CASH_BUSY');
    }
    _isRunning = true;

    try {
      _setupLiveListeners(expectedAmount);
      _emitStage(CashMachineStage.opening, '正在打开现金机…');
      // final open = await CashChanger.openCashChanger();
      // if (!open.isSuccess) _failAndThrow(open.error);

      final start = await CashChanger.startDeposit();
      if (!start.isSuccess) _failAndThrow(start.error);
      _emitStage(CashMachineStage.accepting, '现金机打开成功。');

      final receipt = CashMachineReceipt(
        acceptedAmount: 0,
        expectedAmount: expectedAmount,
        raw: {
          'acceptedAmount': 0,
          'expectedAmount': expectedAmount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _pendingReceipt = receipt;
      _awaitingCompletion = true;
      _emit(CashMachineReceiptReadyEvent(receipt));
      _emitStage(CashMachineStage.accepting, '金额确认，等待投入现金…');
      return receipt;
    } catch (e, s) {
      _logger.severe('Cash payment sequence failed', e, s);
      await _safeAbortDeposit();
      _emitError('现金机异常: $e');
      rethrow;
    } finally {
      // _isRunning = false;
      // _teardownLiveListeners();
    }
  }

  @override
  Future<CashMachineReceipt> completePayment() async {
    debugPrint('Completing cash payment');
    if (_pendingReceipt == null || !_awaitingCompletion) {
      throw StateError('CASH_NO_PENDING');
    }
    
    final deposit = await CashChanger.depositAmount;
    if (!deposit.isSuccess) _failAndThrow(deposit.error);
    final receipt = _pendingReceipt!;
    int acceptedAmount = deposit.data ?? receipt.acceptedAmount; 
    final expected = receipt.expectedAmount;
    final changeAmount = acceptedAmount > expected
        ? (acceptedAmount - expected)
        : 0;
    debugPrint('---CashMachineServiceImpl.completePayment changeAmount $changeAmount called---');
    await Future.delayed(Duration(milliseconds: 200));
    if (changeAmount > 0) {
      _emitStage(CashMachineStage.change, '正在找零 ¥$changeAmount…');
      final change = await CashChanger.dispenseChange(changeAmount);
      if (!change.isSuccess) _failAndThrow(change.error);
    }

    _emitStage(CashMachineStage.completed, '现金机已回到空闲状态');
    
    _pendingReceipt = null;
    _awaitingCompletion = false;
    _isRunning = false;
    _teardownLiveListeners();
    return receipt;
  }

  @override
  Future<void> cancelPayment() async {
    debugPrint('---CashMachineServiceImpl.cancelPayment called---');
    if (!_isRunning && !_awaitingCompletion) {
      return;
    }
    _emitStage(CashMachineStage.closing, '正在取消现金交易…');
    try {
      await CashChanger.fixDeposit;
      await CashChanger.endDeposit(DepositAction.repay.index);
    } catch (e, s) {
      _logger.warning('Failed to end deposit during cancel', e, s);
    }

    _pendingReceipt = null;
    _awaitingCompletion = false;
    _isRunning = false;
    _teardownLiveListeners();
    _emitStage(CashMachineStage.idle, '现金机已回到空闲状态');
  }

  @override
  Future<void> dispose() async {
    await cancelPayment();
    await _eventsController.close();
  }

  void _setupLiveListeners(int targetAmount) async {
    debugPrint('---CashMachineServiceImpl._setupLiveListeners targetAmount $targetAmount called---');
    await CashChanger.setEventsListener();
    if (targetAmount == 0) {
      _emit(CashMachineAmountEvent(0, isFinal: true));
    }
    debugPrint('---onGetPutMoneyStringChange listeners set---');
    CashChanger.onGetPutMoneyStringChange = (int value) {
      debugPrint('CashChanger onGetPutMoneyStringChange: $value');
      _logger.info('CashChanger onGetPutMoneyStringChange: $value');
      if (value <= 0) return;
      final isFinal = value >= targetAmount;
      _pendingReceipt = CashMachineReceipt(
        acceptedAmount: value,
        expectedAmount: targetAmount,
        raw: _pendingReceipt?.raw ?? {},  
      );
      _emit(CashMachineAmountEvent(value, isFinal: isFinal));
    };

    CashChanger.onStatusUpdateEventChange = (String status) {
      switch (status) {
        case 'NEARFULL':
          _emitStage(CashMachineStage.nearfull, '现金机即将满，请及时清空现金箱');
          break;
        case 'FULL':
          _emitStage(CashMachineStage.full, '现金机已满，请及时清空现金箱');
          break;
        default:
          break;
      }
    };
  }

  void _teardownLiveListeners() {
    CashChanger.onGetPutMoneyStringChange = null;
    CashChanger.onStatusUpdateEventChange = null;
  }

  Future<void> _safeAbortDeposit() async {
    try {
      await CashChanger.endDeposit(DepositAction.repay.index);
      //await CashChanger.closeCashChanger;
    } catch (e, s) {
      _logger.warning('Failed to abort deposit', e, s);
    } finally {
      _pendingReceipt = null;
      _awaitingCompletion = false;
      _teardownLiveListeners();
    }
  }

  void _emit(CashMachineEvent event) {
    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }

  void _emitStage(CashMachineStage stage, String message) {
    _emit(CashMachineStageEvent(stage, message: message));
  }

  void _emitError(String message) {
    _emit(CashMachineErrorEvent(message));
    _emit(CashMachineStageEvent(CashMachineStage.error, message: message));
  }

  Never _failAndThrow(CashOperationError? error) {
    final message = _messageFromError(error);
    _emitError(message);
    throw StateError(message);
  }

  String _messageFromError(CashOperationError? error) {
    return error?.message ?? 'cash_error_common';
  }

  Future<_RecoverResult> _recoverIfNeeded(int rawCode) async {
    if (rawCode == 0) rawCode = 100;
    if (rawCode < 100 || rawCode - 100 >= HealthResultCode.values.length) {
      return const _RecoverResult.success();
    }
    final code = HealthResultCode.values[rawCode - 100];
    switch (code) {
      case HealthResultCode.OPOS_SUCCESS:
      case HealthResultCode.OPOS_E_ILLEGAL:
        final end = await CashChanger.endDeposit(DepositAction.repay.index);
        if (!end.isSuccess) {
          return _RecoverResult.failure(_messageFromError(end.error));
        }
        return const _RecoverResult.success();
      case HealthResultCode.OPOS_E_BUSY:
        await Future.delayed(const Duration(seconds: 3));
        return _recoverIfNeeded(100);
      case HealthResultCode.OPOS_E_NOHARDWARE:
        return const _RecoverResult.failure('未检测到现金机硬件');
      case HealthResultCode.OPOS_E_CLOSED:
      case HealthResultCode.OPOS_E_NOTCLAIMED:
      case HealthResultCode.OPOS_E_DISABLED:
      default:
        return const _RecoverResult.failure('continue');
    }
  }
}

class _RecoverResult {
  const _RecoverResult.success() : isSuccess = true, message = null;
  const _RecoverResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String? message;
}
