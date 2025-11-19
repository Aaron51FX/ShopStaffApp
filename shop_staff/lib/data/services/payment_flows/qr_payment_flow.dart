import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

import '../payment_channel_support.dart';
import '../payment_backend_gateway.dart';

/// QR payment flow: handles scanning and server confirmation.
class QrPaymentFlow implements PaymentFlow {
  QrPaymentFlow({
    required QrScannerService scannerService,
    required PaymentBackendGateway backendGateway,
    Logger? logger,
  })  : _scannerService = scannerService,
        _backendGateway = backendGateway,
        _logger = logger ?? Logger('QrPaymentFlow');

  final QrScannerService _scannerService;
  final PaymentBackendGateway _backendGateway;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await controller.close();
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(type: PaymentStatusType.waitingForUser, message: '请将二维码对准扫描区域'));
        final code = await _scannerService.acquireCode(context);
        controller.add(const PaymentStatus(type: PaymentStatusType.processing, message: '二维码已识别，通知后台确认'));
        await _backendGateway.confirmPayment(context, {
          'method': PaymentChannels.qr,
          'code': code,
        });
        controller.add(const PaymentStatus(type: PaymentStatusType.success, message: '二维码支付完成'));
        await finish(PaymentResult.success(message: '二维码支付完成', payload: {'code': code}));
      } catch (e, stack) {
        _logger.severe('QR payment flow failed', e, stack);
        controller.add(PaymentStatus(type: PaymentStatusType.failure, message: '二维码支付失败: $e'));
        await finish(PaymentResult.failure(message: e.toString()));
      }
    }

    Future<void> cancel() async {
      if (isFinished) {
        return;
      }
      try {
        await _scannerService.cancelScan();
      } catch (e, stack) {
        _logger.warning('Failed to cancel QR scan', e, stack);
      }
      controller.add(const PaymentStatus(type: PaymentStatusType.cancelled, message: '操作员取消二维码支付'));
      await finish(PaymentResult.cancelled(message: '操作员取消二维码支付'));
    }

    unawaited(run());

    return PaymentFlowRun(
      statuses: controller.stream,
      result: completer.future,
      cancel: cancel,
    );
  }
}
