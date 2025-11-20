import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

import 'payment_backend_gateway.dart';

/// Interface for communicating with a physical cash handling machine.
abstract class CashMachineClient {
  Future<void> startTransaction(PaymentContext context);
  Future<CashMachineReceipt> waitForSettlement();
  Future<void> cancelTransaction();
}

/// Receipt modeled from the cash machine output.
class CashMachineReceipt {
  CashMachineReceipt({required this.acceptedAmount, this.raw});

  final int acceptedAmount;
  final Map<String, dynamic>? raw;

  Map<String, dynamic> toJson() => {
        'acceptedAmount': acceptedAmount,
        if (raw != null) 'raw': raw,
      };
}

/// Interface for scanning QR codes (camera / external scanners).
abstract class QrScannerService {
  Future<String> acquireCode(PaymentContext context);
  Future<void> cancelScan();
}

enum QrScanDialogStatus { hidden, waiting, error }

class QrScanUiState {
  const QrScanUiState._(this.status, this.message);

  final QrScanDialogStatus status;
  final String? message;

  const QrScanUiState.hidden() : this._(QrScanDialogStatus.hidden, null);

  factory QrScanUiState.waiting({String? message}) {
    return QrScanUiState._(QrScanDialogStatus.waiting, message);
  }

  factory QrScanUiState.error(String message) {
    return QrScanUiState._(QrScanDialogStatus.error, message);
  }

  bool get isVisible => status != QrScanDialogStatus.hidden;

  @override
  bool operator ==(Object other) {
    return other is QrScanUiState && other.status == status && other.message == message;
  }

  @override
  int get hashCode => Object.hash(status, message);
}

class DialogDrivenQrScannerService extends ChangeNotifier implements QrScannerService {
  DialogDrivenQrScannerService({Logger? logger}) : _logger = logger ?? Logger('DialogDrivenQrScannerService');

  final Logger _logger;
  Completer<String>? _pending;
  QrScanUiState _state = const QrScanUiState.hidden();

  QrScanUiState get state => _state;

  @override
  Future<String> acquireCode(PaymentContext context) {
    if (_pending != null && !_pending!.isCompleted) {
      throw StateError('已有扫码任务正在进行');
    }
    final completer = Completer<String>();
    _pending = completer;
    _logger.info('等待扫码，订单 ${context.order.orderId}');
    _setState(QrScanUiState.waiting(message: '请扫码'));
    return completer.future;
  }

  void submitCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      _setState(QrScanUiState.error('扫码结果为空，请重试'));
      return;
    }
    _logger.info('收到扫码数据，长度 ${trimmed.length}');
    final completer = _pending;
    if (completer != null && !completer.isCompleted) {
      completer.complete(trimmed);
    }
    _completeScan();
  }

  void showError(String message) {
    _setState(QrScanUiState.error(message));
  }

  void resetPrompt({String? message}) {
    _setState(QrScanUiState.waiting(message: message ?? '请扫码'));
  }

  void _completeScan() {
    _pending = null;
    _setState(const QrScanUiState.hidden());
  }

  void _setState(QrScanUiState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  Future<void> cancelScan() async {
    if (_pending != null && !_pending!.isCompleted) {
      _logger.info('取消扫码');
      _pending!.completeError(StateError('扫码已取消'));
    }
    _pending = null;
    _setState(const QrScanUiState.hidden());
  }

  @override
  void dispose() {
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.completeError(StateError('扫码服务已释放'));
    }
    _pending = null;
    super.dispose();
  }
}

/// Default stubbed implementations used until real integrations are provided.
class StubCashMachineClient implements CashMachineClient {
  StubCashMachineClient({Logger? logger}) : _logger = logger ?? Logger('StubCashMachineClient');

  final Logger _logger;
  PaymentContext? _activeContext;

  @override
  Future<void> startTransaction(PaymentContext context) async {
    _activeContext = context;
    _logger.info('Simulating cash transaction start for order ${context.order.orderId}');
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<CashMachineReceipt> waitForSettlement() async {
    _logger.info('Waiting for simulated cash settlement...');
    await Future<void>.delayed(const Duration(seconds: 2));
    final amount = _activeContext?.order.total ?? 0;
    return CashMachineReceipt(acceptedAmount: amount, raw: {
      'simulated': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> cancelTransaction() async {
    _logger.info('Cancelling simulated cash transaction');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _activeContext = null;
  }
}

class StubPaymentBackendGateway implements PaymentBackendGateway {
  StubPaymentBackendGateway({Logger? logger}) : _logger = logger ?? Logger('StubPaymentBackendGateway');

  final Logger _logger;

  @override
  Future<void> confirmPayment(PaymentContext context, Map<String, dynamic> payload) async {
    _logger.info('Reporting payment for order ${context.order.orderId}: $payload');
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

class StubQrScannerService implements QrScannerService {
  StubQrScannerService({Logger? logger}) : _logger = logger ?? Logger('StubQrScannerService');

  final Logger _logger;
  bool _isScanning = false;

  @override
  Future<String> acquireCode(PaymentContext context) async {
    _isScanning = true;
    _logger.info('Simulating QR scan for order ${context.order.orderId}');
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!_isScanning) {
      throw StateError('QR scan cancelled');
    }
    _isScanning = false;
    return 'SIMULATED_QR_${context.order.orderId}';
  }

  @override
  Future<void> cancelScan() async {
    if (_isScanning) {
      _logger.info('Cancelling simulated QR scan');
    }
    _isScanning = false;
  }
}
