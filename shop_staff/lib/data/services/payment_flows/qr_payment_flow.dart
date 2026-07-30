import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shop_staff/core/async/buffered_broadcast_controller.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

import '../payment_channel_support.dart';
import '../payment_backend_gateway.dart';
import '../pos_card_payment_gateway.dart';
import '../pos_payment_constants.dart';
import 'pos_payment_status_adapter.dart';
import 'pos_terminal_payment_step.dart';

/// QR payment flow: handles scanning and server confirmation, with optional POS assistance.
class QrPaymentFlow implements PaymentFlow {
  QrPaymentFlow({
    required QrScannerService scannerService,
    required PaymentBackendGateway backendGateway,
    required PosPaymentService posPaymentService,
    PosCardPaymentGateway? cardGateway,
    Future<CardPaymentRequestData> Function(PosPaymentRequest request)?
    createPaymentRequest,
    required PosTerminalSettings? Function() readPosTerminalSettings,
    Logger? logger,
  }) : _scannerService = scannerService,
       _backendGateway = backendGateway,
       _posPaymentService = posPaymentService,
       assert(cardGateway != null || createPaymentRequest != null),
       _createPaymentRequest =
           createPaymentRequest ?? cardGateway!.createPaymentRequest,
       _readPosTerminalSettings = readPosTerminalSettings,
       _logger = logger ?? Logger('QrPaymentFlow');

  final QrScannerService _scannerService;
  final PaymentBackendGateway _backendGateway;
  final PosPaymentService _posPaymentService;
  final Future<CardPaymentRequestData> Function(PosPaymentRequest request)
  _createPaymentRequest;
  final PosTerminalSettings? Function() _readPosTerminalSettings;
  final Logger _logger;

  static const Duration _scanTimeout = Duration(seconds: 60);
  static const Duration _backendRequestTimeout = Duration(seconds: 30);
  static const String _stageTimeoutDetail = 'PAYMENT_STAGE_TIMEOUT';
  static const PosPaymentStatusAdapter _statusAdapter = PosPaymentStatusAdapter(
    PosPaymentStatusAdapterConfig(
      successMessageKey: PaymentMessageKeys.qrSuccess,
      failureMessageKey: PaymentMessageKeys.qrFailure,
      cancelledMessageKey: PaymentMessageKeys.qrCancelled,
    ),
  );

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = BufferedBroadcastController<PaymentStatus>();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    late final PosTerminalPaymentStep terminalStep;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await terminalStep.dispose();
      await controller.close();
    }

    terminalStep = PosTerminalPaymentStep(
      service: _posPaymentService,
      adapter: _statusAdapter,
      config: const PosTerminalPaymentStepConfig(
        startStatus: PaymentStatus(
          type: PaymentStatusType.processing,
          messageKey: PaymentMessageKeys.qrPosPrompt,
          phase: PaymentPhase.connecting,
        ),
        startFailureMessageKey: PaymentMessageKeys.qrFailure,
        startStage: 'qr_pos_start',
        waitingStage: 'qr_pos_waiting',
      ),
      emitStatus: controller.add,
      complete: finish,
      logger: _logger,
    );

    Future<void> failWithTimeout({
      required String stage,
      required String messageKey,
      required PaymentErrorType errorType,
      Map<String, dynamic>? payload,
      PaymentOutcomeCertainty certainty = PaymentOutcomeCertainty.known,
      PaymentRecovery recovery = PaymentRecovery.retryCurrentStep,
    }) async {
      if (isFinished) return;
      _logger.warning('QR payment stage timed out: $stage');
      final args = {'detail': _stageTimeoutDetail};
      controller.add(
        PaymentStatus(
          type: certainty == PaymentOutcomeCertainty.indeterminate
              ? PaymentStatusType.indeterminate
              : PaymentStatusType.failure,
          messageKey: certainty == PaymentOutcomeCertainty.indeterminate
              ? PaymentMessageKeys.resultIndeterminate
              : messageKey,
          messageArgs: args,
          details: {'stage': stage, if (payload != null) ...payload},
          errorType: errorType,
          retryable: certainty != PaymentOutcomeCertainty.indeterminate,
          certainty: certainty,
          recovery: recovery,
        ),
      );
      final result = certainty == PaymentOutcomeCertainty.indeterminate
          ? PaymentResult.indeterminate(
              messageKey: PaymentMessageKeys.resultIndeterminate,
              messageArgs: args,
              payload: {'stage': stage, if (payload != null) ...payload},
              errorType: errorType,
              recovery: recovery,
            )
          : PaymentResult.failure(
              messageKey: messageKey,
              messageArgs: args,
              payload: {'stage': stage, if (payload != null) ...payload},
              errorType: errorType,
              retryable: true,
              recovery: recovery,
              certainty: certainty,
            );
      await finish(result);
    }

    Future<void> run() async {
      try {
        controller.add(
          const PaymentStatus(
            type: PaymentStatusType.waitingForUser,
            messageKey: PaymentMessageKeys.qrWaitScan,
            phase: PaymentPhase.waitingUser,
          ),
        );
        final code = await _scannerService
            .acquireCode(context)
            .timeout(
              _scanTimeout,
              onTimeout: () => throw TimeoutException('qr_scan'),
            );
        controller.add(
          const PaymentStatus(
            type: PaymentStatusType.processing,
            messageKey: PaymentMessageKeys.qrRequestBackend,
            phase: PaymentPhase.requesting,
          ),
        );
        final request = _buildPosRequest(context, code);
        final cardData = await _createPaymentRequest(request).timeout(
          _backendRequestTimeout,
          onTimeout: () => throw TimeoutException('qr_backend_request'),
        );

        if (!cardData.success) {
          final message = cardData.exceptionMessage ?? '';
          controller.add(
            PaymentStatus(
              type: PaymentStatusType.failure,
              messageKey: PaymentMessageKeys.qrFailure,
              messageArgs: {'detail': message},
              errorType: PaymentErrorType.backend,
              retryable: true,
              phase: PaymentPhase.requesting,
            ),
          );
          await finish(
            PaymentResult.failure(
              message: message,
              messageKey: PaymentMessageKeys.qrFailure,
              messageArgs: {'detail': message},
              errorType: PaymentErrorType.backend,
              retryable: true,
            ),
          );
          return;
        }

        final requestInfo = cardData.requestInfo?.trim() ?? '';
        final exceptionMessage = cardData.exceptionMessage?.trim() ?? '';
        if (requestInfo.isNotEmpty) {
          if (exceptionMessage.isNotEmpty) {
            await _finishBackendFailure(
              controller: controller,
              finish: finish,
              message: exceptionMessage,
            );
            return;
          }

          final sessionRequest = _requestWithPrefetchedData(
            context,
            request,
            cardData,
          );
          _applyDeferredPosConfig(sessionRequest.customPayload);
          await terminalStep.start(sessionRequest);
          return;
        }

        final resultFlag = _readResultFlag(cardData.data);
        if (resultFlag == true) {
          controller.add(
            const PaymentStatus(
              type: PaymentStatusType.success,
              messageKey: PaymentMessageKeys.qrSuccess,
              phase: PaymentPhase.confirming,
            ),
          );
          try {
            await _backendGateway.confirmPayment(context, {
              'method': PaymentChannels.qr,
              'code': code,
              'result': true,
            });
          } catch (e, stack) {
            _logger.warning('二维码支付结果上报失败', e, stack);
          }
          await finish(
            PaymentResult.success(
              messageKey: PaymentMessageKeys.qrSuccess,
              payload: {'code': code},
            ),
          );
        } else {
          await _finishBackendFailure(
            controller: controller,
            finish: finish,
            message: exceptionMessage,
          );
        }
      } catch (e, stack) {
        if (e is TimeoutException) {
          final stage = e.message?.toString() ?? 'unknown';
          final isBackendRequest = stage == 'qr_backend_request';
          await failWithTimeout(
            stage: stage,
            messageKey: PaymentMessageKeys.qrFailure,
            errorType: PaymentErrorType.network,
            certainty: isBackendRequest
                ? PaymentOutcomeCertainty.indeterminate
                : PaymentOutcomeCertainty.known,
            recovery: isBackendRequest
                ? PaymentRecovery.contactSupervisor
                : PaymentRecovery.restartPayment,
          );
          return;
        }
        if (_isUserCancelled(e)) {
          controller.add(
            const PaymentStatus(
              type: PaymentStatusType.cancelled,
              messageKey: PaymentMessageKeys.qrCancelled,
              errorType: PaymentErrorType.userCancelled,
              retryable: true,
              phase: PaymentPhase.initializing,
            ),
          );
          await finish(
            PaymentResult.cancelled(
              messageKey: PaymentMessageKeys.qrCancelled,
              errorType: PaymentErrorType.userCancelled,
              retryable: true,
            ),
          );
          return;
        }
        final errorType = _isConfigError(e)
            ? PaymentErrorType.config
            : PaymentErrorType.unknown;
        _logger.severe('QR payment flow failed', e, stack);
        controller.add(
          PaymentStatus(
            type: PaymentStatusType.failure,
            messageKey: errorType == PaymentErrorType.config
                ? PaymentMessageKeys.qrConfigMissing
                : PaymentMessageKeys.errorUnknown,
            messageArgs: {'detail': e.toString()},
            errorType: errorType,
            retryable: true,
            phase: PaymentPhase.requesting,
          ),
        );
        await finish(
          PaymentResult.failure(
            message: e.toString(),
            messageKey: errorType == PaymentErrorType.config
                ? PaymentMessageKeys.qrConfigMissing
                : PaymentMessageKeys.errorUnknown,
            messageArgs: {'detail': e.toString()},
            errorType: errorType,
            retryable: true,
          ),
        );
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
      if (terminalStep.hasSession) {
        try {
          await terminalStep.cancel();
        } catch (e, stack) {
          _logger.warning('取消POS扫码支付失败', e, stack);
        }
        return;
      }
      controller.add(
        const PaymentStatus(
          type: PaymentStatusType.cancelled,
          messageKey: PaymentMessageKeys.qrCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
          phase: PaymentPhase.initializing,
        ),
      );
      await finish(
        PaymentResult.cancelled(
          messageKey: PaymentMessageKeys.qrCancelled,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        ),
      );
    }

    unawaited(run());

    return PaymentFlowRun(
      statuses: controller.stream,
      result: completer.future,
      cancel: cancel,
      reconcile: terminalStep.reconcile,
    );
  }

  PosPaymentRequest _buildPosRequest(PaymentContext context, String code) {
    final base = <String, dynamic>{};
    if (context.channelConfig != null) {
      base.addAll(context.channelConfig!);
    }
    base['machineCode'] ??=
        context.metadata?['machineCode'] ?? context.order.orderId;
    base['authCode'] = code;
    base['payType'] = '';
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
    final payload = Map<String, dynamic>.from(
      original.customPayload ?? const {},
    );
    payload[prefetchedCardRequestKey] = cardData;
    payload['requestData'] = cardData.requestInfo;
    return PosPaymentRequest(
      order: context.order,
      channelGroup: original.channelGroup,
      channelCode: original.channelCode,
      customPayload: payload,
    );
  }

  void _applyDeferredPosConfig(Map<String, dynamic>? payload) {
    final settings = _readPosTerminalSettings();
    final posIp = settings?.posIp?.trim() ?? '';
    final posPort = settings?.posPort;
    if (payload == null || posIp.isEmpty || posPort == null || posPort <= 0) {
      throw StateError('POS_CONFIG_MISSING');
    }
    payload['posIp'] = posIp;
    payload['posPort'] = posPort;
    payload['paymentCode'] = (payload['paymentCode'] ?? '3').toString();
  }

  bool _isUserCancelled(Object error) {
    if (error is StateError) {
      final msg = error.message.toString();
      if (msg == 'QR_SCAN_CANCELLED') return true;
    }
    final text = error.toString();
    return text.contains('QR_SCAN_CANCELLED') || text.contains('cancelled');
  }

  bool _isConfigError(Object error) {
    if (error is StateError && error.message == 'POS_CONFIG_MISSING') {
      return true;
    }
    if (error is ArgumentError && error.message == 'POS_CONFIG_MISSING') {
      return true;
    }
    return error is StateError &&
        (error.message == 'POS_IP_MISSING' ||
            error.message == 'POS_PORT_INVALID');
  }

  bool? _readResultFlag(Map<String, dynamic> data) {
    if (!data.containsKey('result') || data['result'] == null) {
      return null;
    }
    final result = data['result'];
    if (result is bool) return result;
    if (result is num) return result != 0;
    if (result is String) {
      switch (result.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }

  Future<void> _finishBackendFailure({
    required BufferedBroadcastController<PaymentStatus> controller,
    required Future<void> Function(PaymentResult result) finish,
    required String message,
  }) async {
    controller.add(
      PaymentStatus(
        type: PaymentStatusType.failure,
        messageKey: PaymentMessageKeys.qrFailure,
        messageArgs: {'detail': message},
        errorType: PaymentErrorType.backend,
        retryable: true,
        phase: PaymentPhase.requesting,
      ),
    );
    await finish(
      PaymentResult.failure(
        message: message,
        messageKey: PaymentMessageKeys.qrFailure,
        messageArgs: {'detail': message},
        errorType: PaymentErrorType.backend,
        retryable: true,
      ),
    );
  }
}
