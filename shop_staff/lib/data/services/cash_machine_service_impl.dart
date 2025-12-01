import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';
import 'package:shop_staff/plugins/cash_changer/lib/cash_changer.dart';
import 'package:shop_staff/plugins/cash_changer/lib/cash_changer_define.dart';

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
  int? _expectedAmount;

  @override
  Stream<CashMachineEvent> get events => _eventsController.stream;

  @override
  Future<CashMachineInitResult> initialize() async {
    _emitStage(CashMachineStage.checking, '正在检查现金机状态…');
    try {
      final status = await CashChanger.checkChangerStatus;
      // if (!status.isSuccess) {
      //   return _fail(status.error);
      // }
      
      if (!status.isSuccess) {
        final message = _messageFromError(status.error);
        _emitError(message);
        return CashMachineInitResult(isReady: false, message: message);
      }

      final recovered = await _recoverIfNeeded(status.error?.code ?? 0);
      if (!recovered.isSuccess) {
        final message = recovered.message ?? '现金机恢复失败';
        _emitError(message);
        return CashMachineInitResult(isReady: false, message: message);
      }

      final open = await CashChanger.openCashChanger();
      if (!open.isSuccess) {
        final code = open.error?.code ?? -1;
        if (code == 225) {
          // Already opened
        } else {
          final message = _messageFromError(open.error);
          _emitError(message);
          return CashMachineInitResult(isReady: false, message: message);
        }
      } 

      final deposit = await CashChanger.depositAmount;
      if (!deposit.isSuccess) _failAndThrow(deposit.error);

      final endDeposit = await CashChanger.endDeposit(DepositAction.repay.index);
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
    _logger.info('Starting cash payment sequence for amount: $expectedAmount');
    if (_isRunning || _awaitingCompletion) {
      throw StateError('上一笔现金支付仍在进行');
    }
    _isRunning = true;
    _expectedAmount = expectedAmount;
    try {
      _setupLiveListeners(expectedAmount);
      _emitStage(CashMachineStage.opening, '正在打开现金机…');
      final open = await CashChanger.openCashChanger();
      if (!open.isSuccess) _failAndThrow(open.error);

      final start = await CashChanger.startDeposit();
      if (!start.isSuccess) _failAndThrow(start.error);
      _emitStage(CashMachineStage.accepting, '等待顾客投入现金');

      // final deposit = await CashChanger.depositAmount;
      // if (!deposit.isSuccess) _failAndThrow(deposit.error);
      // final accepted = deposit.data ?? 0;
      // _emit(CashMachineAmountEvent(accepted, isFinal: true));

      // _emitStage(CashMachineStage.counting, '正在确认金额…');
      // final fix = await CashChanger.fixDeposit;
      // var fixedAmount = accepted;
      // if (fix.isSuccess && fix.data != null) {
      //   fixedAmount = fix.data!;
      //   if (fixedAmount != accepted) {
      //     _emit(CashMachineAmountEvent(fixedAmount, isFinal: true));
      //   }
      // }

      final receipt = CashMachineReceipt(
        acceptedAmount: 0,
        raw: {
          'deposit': 0,
          'fixed': 0,
          'expected': expectedAmount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _pendingReceipt = receipt;
      _awaitingCompletion = true;
      _emit(CashMachineReceiptReadyEvent(receipt));
      _emitStage(CashMachineStage.completed, '金额确认完成，等待人工确认');
      return receipt;
    } catch (e, s) {
      _logger.severe('Cash payment sequence failed', e, s);
      await _safeAbortDeposit();
      _emitError('现金机异常: $e');
      rethrow;
    } finally {
      _isRunning = false;
      _teardownLiveListeners();
    }
  }

  @override
  Future<CashMachineReceipt> completePayment() async {
    _logger.info('Completing cash payment');
    if (_pendingReceipt == null || !_awaitingCompletion) {
      throw StateError('没有待完成的现金交易');
    }
    final receipt = _pendingReceipt!;
    final expected = _expectedAmount ?? receipt.acceptedAmount;
    final changeAmount = receipt.acceptedAmount > expected ? (receipt.acceptedAmount - expected) : 0;

    if (changeAmount > 0) {
      _emitStage(CashMachineStage.closing, '正在找零 ¥$changeAmount…');
      final change = await CashChanger.dispenseChange(changeAmount);
      if (!change.isSuccess) _failAndThrow(change.error);
    }

    _emitStage(CashMachineStage.closing, '正在结束本次现金操作…');
    try {
      final end = await CashChanger.endDeposit(DepositAction.none.index);
      if (!end.isSuccess) _failAndThrow(end.error);
    } finally {
      try {
        await CashChanger.closeCashChanger;
      } catch (e, s) {
        _logger.warning('关闭现金机失败', e, s);
      }
    }
    _emitStage(CashMachineStage.idle, '现金机已回到空闲状态');
    _pendingReceipt = null;
    _awaitingCompletion = false;
    _expectedAmount = null;
    return receipt;
  }

  @override
  Future<void> cancelPayment() async {
    if (!_isRunning && !_awaitingCompletion) {
      return;
    }
    _emitStage(CashMachineStage.closing, '正在取消现金交易…');
    try {
      await CashChanger.endDeposit(DepositAction.repay.index);
    } catch (e, s) {
      _logger.warning('Failed to end deposit during cancel', e, s);
    }
    try {
      await CashChanger.closeCashChanger;
    } catch (e, s) {
      _logger.warning('Failed to close cash changer', e, s);
    }
    _pendingReceipt = null;
    _awaitingCompletion = false;
    _isRunning = false;
    _expectedAmount = null;
    _teardownLiveListeners();
    _emitStage(CashMachineStage.idle, '现金机已回到空闲状态');
  }

  @override
  Future<void> dispose() async {
    await cancelPayment();
    await _eventsController.close();
  }

  void _setupLiveListeners(int targetAmount) {
    if (targetAmount == 0) {
      _emit(CashMachineAmountEvent(0, isFinal: true));
    }

    CashChanger.onGetPutMoneyStringChange = (int value) {
      _logger.info('CashChanger onGetPutMoneyStringChange: $value');
      if (value <= 0) return;
      final isFinal = value >= targetAmount;
      _pendingReceipt = CashMachineReceipt(
        acceptedAmount: value,
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
      _expectedAmount = null;
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
        return const _RecoverResult.success();
      default:
        return const _RecoverResult.success();
    }
  }
}

class _RecoverResult {
  const _RecoverResult.success()
      : isSuccess = true,
        message = null;
  const _RecoverResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String? message;
}
