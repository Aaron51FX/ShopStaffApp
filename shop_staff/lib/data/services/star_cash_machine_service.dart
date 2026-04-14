import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:starxpand_flutter/starxpand_flutter.dart';

import 'starxpand_cash_drawer_service.dart';

class StarCashMachineService implements CashMachineService {
  StarCashMachineService({
    required CashMachineSettings settings,
    required StarXpandCashDrawerService drawerService,
    Logger? logger,
    Duration drawerClosePollInterval = const Duration(milliseconds: 500),
  }) : _settings = settings,
       _drawerService = drawerService,
       _logger = logger ?? Logger('StarCashMachineService'),
       _drawerClosePollInterval = drawerClosePollInterval,
       _eventsController = StreamController<CashMachineEvent>.broadcast();

  final CashMachineSettings _settings;
  final StarXpandCashDrawerService _drawerService;
  final Logger _logger;
  final Duration _drawerClosePollInterval;
  final StreamController<CashMachineEvent> _eventsController;

  bool _isRunning = false;
  bool _awaitingCompletion = false;
  CashMachineReceipt? _pendingReceipt;
  Completer<void>? _cancelSignal;

  @override
  Stream<CashMachineEvent> get events => _eventsController.stream;

  @override
  Future<CashMachineInitResult> initialize() async {
    _emitStage(CashMachineStage.checking, '正在检查 Star 钱箱状态…');

    try {
      final status = await _drawerService.getStatus(settings: _settings);
      if (status.drawerOpenCloseSignal) {
        const message = 'Star 钱箱当前处于打开状态，请关闭后重试。';
        _emitError(message);
        return const CashMachineInitResult(isReady: false, message: message);
      }

      if (status.hasError) {
        const message = 'Star 钱箱返回异常状态，请检查连接后重试。';
        _emitError(message);
        return const CashMachineInitResult(isReady: false, message: message);
      }

      _emitStage(CashMachineStage.idle, 'Star 钱箱状态正常。');
      return const CashMachineInitResult(isReady: true);
    } catch (error, stack) {
      _logger.severe('Star cash drawer check failed', error, stack);
      final message = 'Star 钱箱检测失败: $error';
      _emitError(message);
      return CashMachineInitResult(isReady: false, message: message);
    }
  }

  @override
  Future<CashMachineReceipt> runPayment(int amount) async {
    if (_isRunning || _awaitingCompletion) {
      throw StateError('CASH_BUSY');
    }

    _isRunning = true;
    _cancelSignal = Completer<void>();
    _emitStage(CashMachineStage.opening, '正在打开 Star 钱箱…');

    try {
      await _drawerService.openDrawer(
        settings: _settings,
        channel: StarXpandDrawerChannel.no1,
      );

      final receipt = CashMachineReceipt(
        acceptedAmount: amount,
        expectedAmount: amount,
        raw: {
          'acceptedAmount': amount,
          'expectedAmount': amount,
          'brand': 'star',
          'mode': 'drawer_only',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _pendingReceipt = receipt;
      _awaitingCompletion = true;
      _emit(CashMachineAmountEvent(amount, isFinal: true));
      _emit(CashMachineReceiptReadyEvent(receipt));
      _emitStage(CashMachineStage.accepting, '钱箱已打开，请收款后点击确认。');
      return receipt;
    } catch (error, stack) {
      _logger.severe('Failed to open Star cash drawer', error, stack);
      _pendingReceipt = null;
      _awaitingCompletion = false;
      _isRunning = false;
      _cancelSignal = null;
      _emitError('Star 钱箱打开失败: $error');
      rethrow;
    }
  }

  @override
  Future<CashMachineReceipt> completePayment() async {
    if (_pendingReceipt == null || !_awaitingCompletion) {
      throw StateError('CASH_NO_PENDING');
    }

    final receipt = _pendingReceipt!;
    _emitStage(CashMachineStage.closing, '正在确认 Star 钱箱状态…');

    try {
      await _waitUntilDrawerClosed();
      _pendingReceipt = null;
      _awaitingCompletion = false;
      _isRunning = false;
      _cancelSignal = null;
      _emitStage(CashMachineStage.completed, '钱箱已关闭，现金交易完成。');
      return receipt;
    } catch (error, stack) {
      if (error is StateError && error.message == 'CASH_CANCELLED') {
        rethrow;
      }

      _logger.warning(
        'Failed while waiting for Star drawer to close',
        error,
        stack,
      );
      _emitError('等待 Star 钱箱关闭失败: $error');
      rethrow;
    }
  }

  @override
  Future<void> cancelPayment() async {
    if (!_isRunning && !_awaitingCompletion) {
      return;
    }

    final cancelSignal = _cancelSignal;
    if (cancelSignal != null && !cancelSignal.isCompleted) {
      cancelSignal.complete();
    }
    _pendingReceipt = null;
    _awaitingCompletion = false;
    _isRunning = false;
    _cancelSignal = null;
    _emitStage(CashMachineStage.closing, '已取消 Star 钱箱流程。');
    _emitStage(CashMachineStage.idle, 'Star 钱箱已回到待命状态。');
  }

  @override
  Future<void> dispose() async {
    await cancelPayment();
    await _eventsController.close();
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

  Future<void> _waitUntilDrawerClosed() async {
    var waitingPromptEmitted = false;

    while (true) {
      _throwIfCancelled();
      final status = await _drawerService.getStatus(settings: _settings);
      _throwIfCancelled();

      if (status.hasError) {
        throw StateError('Star 钱箱状态异常，请检查连接后重试。');
      }

      if (!status.drawerOpenCloseSignal) {
        return;
      }

      if (!waitingPromptEmitted) {
        waitingPromptEmitted = true;
        _emitStage(CashMachineStage.waitingDrawerClose, '请关闭钱箱，关闭后将自动完成现金交易。');
      }

      await _delayOrCancel(_drawerClosePollInterval);
    }
  }

  Future<void> _delayOrCancel(Duration duration) async {
    final cancelSignal = _cancelSignal;
    if (cancelSignal == null) {
      throw StateError('CASH_CANCELLED');
    }

    if (duration <= Duration.zero) {
      _throwIfCancelled();
      return;
    }

    await Future.any<void>([
      Future<void>.delayed(duration),
      cancelSignal.future,
    ]);
    _throwIfCancelled();
  }

  void _throwIfCancelled() {
    final cancelSignal = _cancelSignal;
    if (cancelSignal == null || cancelSignal.isCompleted) {
      throw StateError('CASH_CANCELLED');
    }
  }
}
