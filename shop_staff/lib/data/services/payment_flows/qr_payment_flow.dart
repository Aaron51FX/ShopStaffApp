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

  static const Duration _scanTimeout = Duration(seconds: 60);
  static const Duration _backendRequestTimeout = Duration(seconds: 30);
  static const Duration _posStartTimeout = Duration(seconds: 20);
  static const Duration _posStatusInactivityTimeout = Duration(seconds: 90);
  static const String _stageTimeoutDetail = 'PAYMENT_STAGE_TIMEOUT';

  @override
  PaymentFlowRun start(PaymentContext context) {
    final controller = StreamController<PaymentStatus>.broadcast();
    final completer = Completer<PaymentResult>();
    var isFinished = false;
    String? activeSessionId;
    StreamSubscription<PosPaymentStatus>? sessionSubscription;
    Timer? stageTimer;

    Future<void> finish(PaymentResult result) async {
      if (isFinished) return;
      isFinished = true;
      stageTimer?.cancel();
      stageTimer = null;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      await sessionSubscription?.cancel();
      await controller.close();
    }

    void clearStageTimer() {
      stageTimer?.cancel();
      stageTimer = null;
    }

    Future<void> failWithTimeout({
      required String stage,
      required String messageKey,
      required PaymentErrorType errorType,
      Map<String, dynamic>? payload,
    }) async {
      if (isFinished) return;
      _logger.warning('QR payment stage timed out: $stage');
      final args = {'detail': _stageTimeoutDetail};
      controller.add(PaymentStatus(
        type: PaymentStatusType.failure,
        messageKey: messageKey,
        messageArgs: args,
        details: {'stage': stage, if (payload != null) ...payload},
        errorType: errorType,
        retryable: true,
      ));
      await finish(PaymentResult.failure(
        messageKey: messageKey,
        messageArgs: args,
        payload: {'stage': stage, if (payload != null) ...payload},
        errorType: errorType,
        retryable: true,
      ));
    }

    void armPosStageTimeout({required Duration timeout, required String stage}) {
      clearStageTimer();
      stageTimer = Timer(timeout, () {
        if (isFinished) return;
        unawaited(() async {
          final sessionId = activeSessionId;
          if (sessionId != null) {
            try {
              await _posPaymentService.cancel(sessionId);
            } catch (error, stack) {
              _logger.warning('Failed to cancel POS session after timeout', error, stack);
            }
          }
          await failWithTimeout(
            stage: stage,
            messageKey: PaymentMessageKeys.posTimeout,
            errorType: PaymentErrorType.device,
          );
        }());
      });
    }

    Future<void> run() async {
      try {
        controller.add(const PaymentStatus(
          type: PaymentStatusType.waitingForUser,
          messageKey: PaymentMessageKeys.qrWaitScan,
          phase: PaymentPhase.waitingUser,
        ));
        final code = await _scannerService
            .acquireCode(context)
            .timeout(_scanTimeout, onTimeout: () => throw TimeoutException('qr_scan'));
        controller.add(const PaymentStatus(
          type: PaymentStatusType.processing,
          messageKey: PaymentMessageKeys.qrRequestBackend,
          phase: PaymentPhase.requesting,
        ));
        final request = _buildPosRequest(context, code);
        final cardData = await _cardGateway
            .createPaymentRequest(request)
            .timeout(_backendRequestTimeout, onTimeout: () => throw TimeoutException('qr_backend_request'));

        if (!cardData.success) {
          final message = cardData.exceptionMessage ?? '';
          controller.add(PaymentStatus(
            type: PaymentStatusType.failure,
            messageKey: PaymentMessageKeys.qrFailure,
            messageArgs: {'detail': message},
            errorType: PaymentErrorType.backend,
            retryable: true,
            phase: PaymentPhase.requesting,
          ));
          await finish(PaymentResult.failure(
            message: message,
            messageKey: PaymentMessageKeys.qrFailure,
            messageArgs: {'detail': message},
            errorType: PaymentErrorType.backend,
            retryable: true,
          ));
          return;
        }

        final requestInfo = cardData.requestInfo;
        if (requestInfo != null && requestInfo.isNotEmpty) {
          controller.add(const PaymentStatus(
            type: PaymentStatusType.processing,
            messageKey: PaymentMessageKeys.qrPosPrompt,
            phase: PaymentPhase.waitingUser,
          ));
          final sessionRequest = _requestWithPrefetchedData(context, request, cardData);
          _ensurePosConfig(sessionRequest.customPayload);
          armPosStageTimeout(timeout: _posStartTimeout, stage: 'pos_start');
          final session = await _posPaymentService.startPayment(sessionRequest);
          activeSessionId = session.sessionId;
          controller.add(_mapPosStatus(session.initialStatus));
          if (session.initialStatus.type == PosPaymentStatusType.success ||
              session.initialStatus.type == PosPaymentStatusType.failure ||
              session.initialStatus.type == PosPaymentStatusType.cancelled) {
            clearStageTimer();
          } else {
            armPosStageTimeout(timeout: _posStatusInactivityTimeout, stage: 'pos_waiting');
          }
          sessionSubscription = _posPaymentService.watchStatus(session.sessionId).listen(
            (status) {
              final mapped = _mapPosStatus(status);
              controller.add(mapped);
              if (mapped.isTerminal) {
                clearStageTimer();
                if (mapped.type == PaymentStatusType.success) {
                  unawaited(finish(PaymentResult.success(
                    message: mapped.message,
                    messageKey: mapped.messageKey,
                    messageArgs: mapped.messageArgs,
                  )));
                } else if (mapped.type == PaymentStatusType.cancelled) {
                  unawaited(finish(PaymentResult.cancelled(
                    message: mapped.message,
                    messageKey: mapped.messageKey,
                    messageArgs: mapped.messageArgs,
                    errorType: mapped.errorType ?? PaymentErrorType.userCancelled,
                    retryable: mapped.retryable ?? true,
                  )));
                } else {
                  unawaited(finish(PaymentResult.failure(
                    message: mapped.message,
                    messageKey: mapped.messageKey,
                    messageArgs: mapped.messageArgs,
                    errorType: mapped.errorType ?? PaymentErrorType.device,
                    retryable: mapped.retryable ?? true,
                  )));
                }
              } else {
                armPosStageTimeout(timeout: _posStatusInactivityTimeout, stage: 'pos_waiting');
              }
            },
            onError: (error, stack) {
              if (isFinished) return;
              final trace = stack is StackTrace ? stack : StackTrace.current;
              _logger.warning('POS状态流异常: $error', error, trace);
              controller.add(PaymentStatus(
                type: PaymentStatusType.failure,
                messageKey: PaymentMessageKeys.errorUnknown,
                messageArgs: {'detail': error.toString()},
                errorType: PaymentErrorType.device,
                retryable: true,
              ));
              unawaited(finish(PaymentResult.failure(
                message: error.toString(),
                messageKey: PaymentMessageKeys.errorUnknown,
                messageArgs: {'detail': error.toString()},
                errorType: PaymentErrorType.device,
                retryable: true,
              )));
            },
            onDone: () {
              if (isFinished) return;
              unawaited(finish(PaymentResult.failure(
                messageKey: PaymentMessageKeys.posStreamClosed,
                errorType: PaymentErrorType.device,
                retryable: true,
              )));
            },
          );
          return;
        }

        final resultFlag = _readResultFlag(cardData.data);
        if (resultFlag == true) {
          controller.add(const PaymentStatus(
            type: PaymentStatusType.success,
            messageKey: PaymentMessageKeys.qrSuccess,
            phase: PaymentPhase.confirming,
          ));
          try {
            await _backendGateway.confirmPayment(context, {
              'method': PaymentChannels.qr,
              'code': code,
              'result': true,
            });
          } catch (e, stack) {
            _logger.warning('二维码支付结果上报失败', e, stack);
          }
          await finish(PaymentResult.success(
            messageKey: PaymentMessageKeys.qrSuccess,
            payload: {'code': code},
          ));
        } else {
          final message = cardData.exceptionMessage ?? '';
          controller.add(PaymentStatus(
            type: PaymentStatusType.failure,
            messageKey: PaymentMessageKeys.qrFailure,
            messageArgs: {'detail': message},
            errorType: PaymentErrorType.backend,
            retryable: true,
            phase: PaymentPhase.requesting,
          ));
          await finish(PaymentResult.failure(
            message: message,
            messageKey: PaymentMessageKeys.qrFailure,
            messageArgs: {'detail': message},
            errorType: PaymentErrorType.backend,
            retryable: true,
          ));
        }
      } catch (e, stack) {
        if (e is TimeoutException) {
          final stage = e.message?.toString() ?? 'unknown';
          if (stage.startsWith('pos_')) {
            await failWithTimeout(
              stage: stage,
              messageKey: PaymentMessageKeys.posTimeout,
              errorType: PaymentErrorType.device,
            );
          } else {
            await failWithTimeout(
              stage: stage,
              messageKey: PaymentMessageKeys.qrFailure,
              errorType: PaymentErrorType.network,
            );
          }
          return;
        }
        if (_isUserCancelled(e)) {
          controller.add(const PaymentStatus(
            type: PaymentStatusType.cancelled,
            messageKey: PaymentMessageKeys.qrCancelled,
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
            phase: PaymentPhase.initializing,
          ));
          await finish(PaymentResult.cancelled(
            messageKey: PaymentMessageKeys.qrCancelled,
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
          ));
          return;
        }
        final errorType = _isConfigError(e) ? PaymentErrorType.config : PaymentErrorType.unknown;
        _logger.severe('QR payment flow failed', e, stack);
        controller.add(PaymentStatus(
          type: PaymentStatusType.failure,
          messageKey: errorType == PaymentErrorType.config
              ? PaymentMessageKeys.qrConfigMissing
              : PaymentMessageKeys.errorUnknown,
          messageArgs: {'detail': e.toString()},
          errorType: errorType,
          retryable: true,
          phase: PaymentPhase.requesting,
        ));
        await finish(PaymentResult.failure(
          message: e.toString(),
          messageKey: errorType == PaymentErrorType.config
              ? PaymentMessageKeys.qrConfigMissing
              : PaymentMessageKeys.errorUnknown,
          messageArgs: {'detail': e.toString()},
          errorType: errorType,
          retryable: true,
        ));
      }
    }

    Future<void> cancel() async {
      if (isFinished) {
        return;
      }
      clearStageTimer();
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
      controller.add(const PaymentStatus(
        type: PaymentStatusType.cancelled,
        messageKey: PaymentMessageKeys.qrCancelled,
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
        phase: PaymentPhase.initializing,
      ));
      await finish(PaymentResult.cancelled(
        messageKey: PaymentMessageKeys.qrCancelled,
        errorType: PaymentErrorType.userCancelled,
        retryable: true,
      ));
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
      throw StateError('POS_CONFIG_MISSING');
    }
  }

  PaymentStatus _mapPosStatus(PosPaymentStatus status) {
    final messageArgs = {
      if (status.messageArgs != null) ...status.messageArgs!,
      if (status.errorCode != null) 'errorCode': status.errorCode,
    };
    switch (status.type) {
      case PosPaymentStatusType.pending:
        return PaymentStatus(
          type: PaymentStatusType.pending,
          message: status.message,
          messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.posWaitingResponse : null),
          messageArgs: messageArgs.isEmpty ? null : messageArgs,
          phase: PaymentPhase.sending,
        );
      case PosPaymentStatusType.processing:
        return PaymentStatus(
          type: PaymentStatusType.processing,
          message: status.message,
          messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.posProcessing : null),
          messageArgs: messageArgs.isEmpty ? null : messageArgs,
          phase: PaymentPhase.waitingUser,
        );
      case PosPaymentStatusType.success:
        return PaymentStatus(
          type: PaymentStatusType.success,
          message: status.message,
          messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.qrSuccess : null),
          messageArgs: messageArgs.isEmpty ? null : messageArgs,
        );
      case PosPaymentStatusType.failure:
        return PaymentStatus(
          type: PaymentStatusType.failure,
          message: status.message,
          messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.qrFailure : null),
          messageArgs: messageArgs.isEmpty ? null : messageArgs,
          errorType: PaymentErrorType.device,
          retryable: true,
        );
      case PosPaymentStatusType.cancelled:
        return PaymentStatus(
          type: PaymentStatusType.cancelled,
          message: status.message,
          messageKey: status.messageKey ?? (status.message == null ? PaymentMessageKeys.qrCancelled : null),
          messageArgs: messageArgs.isEmpty ? null : messageArgs,
          errorType: PaymentErrorType.userCancelled,
          retryable: true,
        );
    }
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
    if (error is StateError && error.message == 'POS_CONFIG_MISSING') return true;
    if (error is ArgumentError && error.message == 'POS_CONFIG_MISSING') return true;
    return error is StateError &&
        (error.message == 'POS_IP_MISSING' || error.message == 'POS_PORT_INVALID');
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
