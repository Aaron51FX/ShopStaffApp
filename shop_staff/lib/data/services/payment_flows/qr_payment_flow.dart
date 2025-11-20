import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

import '../payment_channel_support.dart';
import '../payment_backend_gateway.dart';
import '../pos_card_payment_gateway.dart';
import '../pos_payment_constants.dart';

/// QR payment flow: handles scanning and server confirmation, with optional POS assistance.
class QrPaymentFlow implements PaymentFlow {
  QrPaymentFlow({
    required QrScannerService scannerService,
    required PaymentBackendGateway backendGateway,
    required PosPaymentService posPaymentService,
    required PosCardPaymentGateway cardGateway,
    Logger? logger,
  })  : _scannerService = scannerService,
        _backendGateway = backendGateway,
        _posPaymentService = posPaymentService,
        _cardGateway = cardGateway,
        _logger = logger ?? Logger('QrPaymentFlow');

  final QrScannerService _scannerService;
  final PaymentBackendGateway _backendGateway;
  final PosPaymentService _posPaymentService;
  final PosCardPaymentGateway _cardGateway;
  final Logger _logger;

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    String? activeSessionId;
    StreamSubscription<PosPaymentStatus>? sessionSubscription;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await sessionSubscription?.cancel();
      await controller.close();
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(type: PaymentStatusType.waitingForUser, message: '请将二维码对准扫描区域'));
        final code = await _scannerService.acquireCode(context);
        controller.add(const PaymentStatus(type: PaymentStatusType.processing, message: '二维码已识别，正在请求后台…'));
        final request = _buildPosRequest(context, code);
        final cardData = await _cardGateway.createPaymentRequest(request);

        if (cardData.hasError) {
          final message = cardData.exceptionMessage ?? '二维码支付失败';
          controller.add(PaymentStatus(type: PaymentStatusType.failure, message: message));
          await finish(PaymentResult.failure(message: message));
          return;
        }

        final requestInfo = cardData.requestInfo;
        if (requestInfo != null && requestInfo.isNotEmpty) {
          controller.add(const PaymentStatus(type: PaymentStatusType.processing, message: '请按照POS终端提示完成支付'));
          final sessionRequest = _requestWithPrefetchedData(context, request, cardData);
          _ensurePosConfig(sessionRequest.customPayload);
          final session = await _posPaymentService.startPayment(sessionRequest);
          activeSessionId = session.sessionId;
          controller.add(_mapPosStatus(session.initialStatus));
          sessionSubscription = _posPaymentService.watchStatus(session.sessionId).listen(
            (status) {
              final mapped = _mapPosStatus(status);
              controller.add(mapped);
              if (mapped.isTerminal) {
                if (mapped.type == PaymentStatusType.success) {
                  unawaited(finish(PaymentResult.success(message: mapped.message)));
                } else if (mapped.type == PaymentStatusType.cancelled) {
                  unawaited(finish(PaymentResult.cancelled(message: mapped.message)));
                } else {
                  unawaited(finish(PaymentResult.failure(message: mapped.message)));
                }
              }
            },
            onError: (error, stack) {
              if (isFinished) return;
              final trace = stack is StackTrace ? stack : StackTrace.current;
              _logger.warning('POS状态流异常: $error', error, trace);
              controller.add(PaymentStatus(type: PaymentStatusType.failure, message: error.toString()));
              unawaited(finish(PaymentResult.failure(message: error.toString())));
            },
          );
          return;
        }

        final resultFlag = _readResultFlag(cardData.data);
        if (resultFlag == true) {
          controller.add(const PaymentStatus(type: PaymentStatusType.success, message: '二维码支付完成'));
          try {
            await _backendGateway.confirmPayment(context, {
              'method': PaymentChannels.qr,
              'code': code,
              'result': true,
            });
          } catch (e, stack) {
            _logger.warning('二维码支付结果上报失败', e, stack);
          }
          await finish(PaymentResult.success(message: '二维码支付完成', payload: {'code': code}));
        } else {
          final message = cardData.exceptionMessage ?? '二维码支付失败';
          controller.add(PaymentStatus(type: PaymentStatusType.failure, message: message));
          await finish(PaymentResult.failure(message: message));
        }
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
      if (activeSessionId != null) {
        try {
          await _posPaymentService.cancel(activeSessionId!);
        } catch (e, stack) {
          _logger.warning('取消POS扫码支付失败', e, stack);
        }
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

  PosPaymentRequest _buildPosRequest(PaymentContext context, String code) {
    final base = <String, dynamic>{};
    if (context.channelConfig != null) {
      base.addAll(context.channelConfig!);
    }
    base['machineCode'] ??= context.metadata?['machineCode'] ?? context.order.orderId;
    base['authCode'] = code;
    base['payType'] ??= context.channel.code;
    return PosPaymentRequest(
      order: context.order,
      channelGroup: PaymentChannels.card,
      channelCode: context.channel.code,
      customPayload: base,
    );
  }

  PosPaymentRequest _requestWithPrefetchedData(
    PaymentContext context,
    PosPaymentRequest original,
    CardPaymentRequestData cardData,
  ) {
    final payload = Map<String, dynamic>.from(original.customPayload ?? const {});
    payload[prefetchedCardRequestKey] = cardData;
    payload['requestData'] = cardData.requestInfo;
    return PosPaymentRequest(
      order: context.order,
      channelGroup: original.channelGroup,
      channelCode: original.channelCode,
      customPayload: payload,
    );
  }

  void _ensurePosConfig(Map<String, dynamic>? payload) {
    if (payload == null || payload['posIp'] == null || payload['posPort'] == null) {
      throw StateError('缺少POS终端配置，无法完成扫码支付');
    }
  }

  PaymentStatus _mapPosStatus(PosPaymentStatus status) {
    switch (status.type) {
      case PosPaymentStatusType.pending:
        return PaymentStatus(type: PaymentStatusType.pending, message: status.message ?? '等待终端响应');
      case PosPaymentStatusType.processing:
        return PaymentStatus(type: PaymentStatusType.processing, message: status.message ?? '终端处理中');
      case PosPaymentStatusType.success:
        return PaymentStatus(type: PaymentStatusType.success, message: status.message ?? '扫码支付完成');
      case PosPaymentStatusType.failure:
        return PaymentStatus(type: PaymentStatusType.failure, message: status.message ?? '扫码支付失败');
      case PosPaymentStatusType.cancelled:
        return PaymentStatus(type: PaymentStatusType.cancelled, message: status.message ?? '扫码支付已取消');
    }
  }

  bool _readResultFlag(Map<String, dynamic> data) {
    final result = data['result'];
    if (result is bool) return result;
    if (result is String) {
      return result.toLowerCase() == 'true';
    }
    return false;
  }
}
