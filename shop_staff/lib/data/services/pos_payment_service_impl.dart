import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

import 'legacy_pos_socket_manager.dart';
import 'pos_card_payment_gateway.dart';
import 'pos_payment_constants.dart';

class PosPaymentServiceImpl implements PosPaymentService {
  PosPaymentServiceImpl({
    LegacyPosSocketManager Function()? managerFactory,
    PosCardPaymentGateway? cardGateway,
    Logger? logger,
  }) : _managerFactory =
           managerFactory ?? (() => LegacyPosSocketManager(logger: logger)),
       _cardGateway = cardGateway,
       _logger = logger ?? Logger('PosPaymentServiceImpl');

  final LegacyPosSocketManager Function() _managerFactory;
  final PosCardPaymentGateway? _cardGateway;
  final Logger _logger;
  final Map<String, _PosSessionEntry> _sessions = {};
  final Random _random = Random();

  @override
  Future<PosPaymentSession> startPayment(PosPaymentRequest request) async {
    final sessionId = _generateSessionId();
    final controller = StreamController<PosPaymentStatus>();
    const initialStatus = PosPaymentStatus(
      type: PosPaymentStatusType.pending,
      messageKey: PaymentMessageKeys.posWaitingResponse,
      phase: PaymentPhase.connecting,
    );

    final entry = _PosSessionEntry(
      controller: controller,
      manager: _managerFactory(),
      payload: LegacyPosPaymentPayload.fromRequest(request),
      request: request,
      initialStatus: initialStatus,
      cardGateway: _shouldUseCardGateway(request) ? _cardGateway : null,
    );
    try {
      await _prepareEntry(entry);
    } catch (e, stack) {
      _logger.severe('Failed to prepare POS payment session', e, stack);
      await controller.close();
      rethrow;
    }

    _sessions[sessionId] = entry;
    unawaited(
      _PosSessionRunner(
        sessionId: sessionId,
        entry: entry,
        logger: _logger,
        finishSession: _finishSession,
      ).run(),
    );

    return PosPaymentSession(
      sessionId: sessionId,
      initialStatus: initialStatus,
    );
  }

  @override
  Stream<PosPaymentStatus> watchStatus(String sessionId) {
    final entry = _sessions[sessionId];
    if (entry == null) {
      return Stream.value(
        const PosPaymentStatus(
          type: PosPaymentStatusType.failure,
          messageKey: PaymentMessageKeys.sessionMissing,
          errorType: PaymentErrorType.unknown,
          retryable: true,
        ),
      );
    }
    entry.attachWatcher();
    return entry.controller.stream;
  }

  @override
  Future<void> cancel(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) {
      throw StateError('POS_SESSION_MISSING');
    }
    if (entry.isCompleted) {
      return;
    }

    try {
      if (entry.supportsCard && entry.cardGateway != null) {
        final instruction = await entry.ensureCancelInstruction(_logger);
        final payload = instruction.payload;
        if (payload.isEmpty) {
          throw StateError('POS_CANCEL_INSTRUCTION_EMPTY');
        }

        await entry.manager.write(PosAction.cancel, payload);
      } else {
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.cancelled,
            messageKey: PaymentMessageKeys.posOperatorCancelled,
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
            phase: entry.currentPhase,
          ),
        );
        await _finishSession(sessionId);
      }
    } catch (e, stack) {
      _logger.severe('POS取消失败', e, stack);
      final errorType = _errorTypeForException(e);
      entry.emit(
        PosPaymentStatus(
          type: PosPaymentStatusType.failure,
          messageKey: PaymentMessageKeys.posCancelFailed,
          messageArgs: {'detail': _errorDetail(e)},
          errorCode: _errorCodeForException(e),
          errorType: errorType,
          retryable: _retryableForErrorType(errorType),
          phase: entry.currentPhase,
        ),
      );
      await _finishSession(sessionId);
      throw StateError('POS_CANCEL_FAILED');
    }
  }

  Future<void> _prepareEntry(_PosSessionEntry entry) async {
    final prefetched = entry.request.customPayload?[prefetchedCardRequestKey];
    if (prefetched is CardPaymentRequestData) {
      entry.cardRequest = prefetched;
    }

    if (!entry.supportsCard) {
      return;
    }

    final gateway = entry.cardGateway;
    if (gateway == null) {
      throw StateError('POS_CARD_GATEWAY_REQUIRED');
    }

    final shouldFetchRequestData = entry.cardRequest == null;
    if (shouldFetchRequestData) {
      entry.updatePhase(PaymentPhase.requesting);
      entry.emit(
        const PosPaymentStatus(
          type: PosPaymentStatusType.processing,
          messageKey: PaymentMessageKeys.posFetchingPayData,
          phase: PaymentPhase.requesting,
        ),
      );
    }

    try {
      entry.cardRequest ??= await gateway.createPaymentRequest(entry.request);
      final cardRequest = entry.cardRequest;
      if (cardRequest == null) {
        throw StateError('POS_REQUEST_DATA_MISSING');
      }
      if (cardRequest.hasError) {
        throw StateError(
          cardRequest.exceptionMessage ?? 'POS_REQUEST_DATA_MISSING',
        );
      }
      final requestInfo = cardRequest.requestInfo;
      if (requestInfo == null || requestInfo.isEmpty) {
        throw StateError('POS_REQUEST_DATA_MISSING');
      }
      entry.payload = entry.payload.copyWith(requestData: requestInfo);
    } catch (e, stack) {
      _logger.severe('Failed to prepare card payment data', e, stack);
      rethrow;
    }
  }

  Future<void> _finishSession(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) return;
    if (entry.isCompleted) return;
    entry.isCompleted = true;
    try {
      await entry.transportSubscription?.cancel();
      await entry.manager.closePos();
    } catch (e, stack) {
      _logger.warning('Error closing POS session $sessionId', e, stack);
    }
    await entry.controller.close();
    _sessions.remove(sessionId);
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1 << 32);
    return '$timestamp-$randomPart';
  }

  bool _shouldUseCardGateway(PosPaymentRequest request) {
    return request.channelGroup == PaymentChannels.card;
  }
}

class _PosSessionEntry {
  _PosSessionEntry({
    required this.controller,
    required this.manager,
    required this.payload,
    required this.request,
    required this.initialStatus,
    this.cardGateway,
  }) : currentPhase = initialStatus.phase,
       cancelInstruction =
           (payload.cancelData != null && payload.cancelData!.isNotEmpty)
           ? CardCancelInstruction(payload: payload.cancelData!)
           : null;

  final StreamController<PosPaymentStatus> controller;
  final LegacyPosSocketManager manager;
  LegacyPosPaymentPayload payload;
  final PosPaymentRequest request;
  final PosPaymentStatus initialStatus;
  final PosCardPaymentGateway? cardGateway;
  CardPaymentRequestData? cardRequest;
  CardCancelInstruction? cancelInstruction;
  PaymentPhase? currentPhase;
  StreamSubscription<LegacyPosTransportEvent>? transportSubscription;
  final List<PosPaymentStatus> _pendingStatuses = <PosPaymentStatus>[];
  bool _watchAttached = false;
  bool isCompleted = false;

  bool get supportsCard => cardGateway != null;

  void updatePhase(PaymentPhase phase) {
    currentPhase = phase;
  }

  void emit(PosPaymentStatus status) {
    if (isCompleted || controller.isClosed) {
      return;
    }
    currentPhase = status.phase ?? currentPhase;
    if (!_watchAttached) {
      _pendingStatuses.add(status);
      return;
    }
    controller.add(status);
  }

  void attachWatcher() {
    if (_watchAttached) {
      return;
    }
    _watchAttached = true;
    if (_pendingStatuses.isEmpty || controller.isClosed) {
      return;
    }
    final buffered = List<PosPaymentStatus>.from(_pendingStatuses);
    _pendingStatuses.clear();
    scheduleMicrotask(() {
      if (isCompleted || controller.isClosed) {
        return;
      }
      for (final status in buffered) {
        controller.add(status);
      }
    });
  }

  Future<CardPaymentRequestData?> ensureCardRequest(Logger logger) async {
    if (!supportsCard) return cardRequest;
    if (cardRequest != null) return cardRequest;
    try {
      final data = await cardGateway!.createPaymentRequest(request);
      if (data.hasError) {
        throw StateError(data.exceptionMessage ?? 'POS_REQUEST_DATA_MISSING');
      }
      final info = data.requestInfo;
      if (info == null || info.isEmpty) {
        throw StateError('POS_REQUEST_DATA_MISSING');
      }
      cardRequest = data;
      return cardRequest;
    } catch (e, stack) {
      logger.severe('Retry create card payment request failed', e, stack);
      rethrow;
    }
  }

  Future<CardCancelInstruction> ensureCancelInstruction(Logger logger) async {
    if (!supportsCard || cardGateway == null) {
      throw StateError('POS_CANCEL_NOT_SUPPORTED');
    }
    final existing = cancelInstruction;
    if (existing != null && existing.payload.isNotEmpty) {
      return existing;
    }
    try {
      final instruction = await cardGateway!.fetchCancelInstruction(request);
      cancelInstruction = instruction;
      return instruction;
    } catch (e, stack) {
      logger.severe('获取POS取消指令失败', e, stack);
      rethrow;
    }
  }
}

class _PosSessionRunner {
  _PosSessionRunner({
    required this.sessionId,
    required this.entry,
    required this.logger,
    required this.finishSession,
  });

  final String sessionId;
  final _PosSessionEntry entry;
  final Logger logger;
  final Future<void> Function(String sessionId) finishSession;

  Future<void> run() async {
    try {
      final run = entry.manager.startTransportSession(
        payment: entry.payload.paymentCode,
        posIp: entry.payload.posIp,
        posPort: entry.payload.posPort,
        machineCode: entry.payload.machineCode,
        requestData: entry.payload.requestData,
      );
      entry.transportSubscription = run.events.listen(_handleTransportEvent);
    } catch (e, stack) {
      logger.severe('POS payment session failed', e, stack);
      final errorType = _errorTypeForException(e);
      entry.emit(
        PosPaymentStatus(
          type: PosPaymentStatusType.failure,
          message: e.toString(),
          messageKey: PaymentMessageKeys.errorUnknown,
          messageArgs: {'detail': _errorDetail(e)},
          errorCode: _errorCodeForException(e),
          errorType: errorType,
          retryable: _retryableForErrorType(errorType),
          phase: entry.currentPhase,
        ),
      );
      await finishSession(sessionId);
    }
  }

  void _handleTransportEvent(LegacyPosTransportEvent event) {
    entry.updatePhase(event.phase);
    switch (event.type) {
      case LegacyPosTransportEventType.connecting:
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.pending,
            messageKey: PaymentMessageKeys.posWaitingResponse,
            phase: event.phase,
          ),
        );
        return;
      case LegacyPosTransportEventType.connected:
      case LegacyPosTransportEventType.writeCompleted:
        return;
      case LegacyPosTransportEventType.writeStarted:
        entry.emit(
          PosPaymentStatus(
            type: event.action == PosAction.cancel
                ? PosPaymentStatusType.processing
                : PosPaymentStatusType.pending,
            messageKey: event.action == PosAction.cancel
                ? PaymentMessageKeys.posCancelProcessing
                : PaymentMessageKeys.posWaitingResponse,
            phase: event.phase,
          ),
        );
        return;
      case LegacyPosTransportEventType.requestPayData:
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.processing,
            messageKey: PaymentMessageKeys.posRequestPayData,
            phase: event.phase,
          ),
        );
        return;
      case LegacyPosTransportEventType.cancelAcknowledged:
        entry.emit(
          const PosPaymentStatus(
            type: PosPaymentStatusType.processing,
            messageKey: PaymentMessageKeys.posFinalizing,
            phase: PaymentPhase.sending,
          ),
        );
        return;
      case LegacyPosTransportEventType.cancelWaitResult:
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.processing,
            messageKey: PaymentMessageKeys.posCancelWaitResult,
            messageArgs: {
              if (event.resultCode != null) 'code': event.resultCode,
              if (event.mpfsCode != null) 'mpfs': event.mpfsCode,
            },
            details: {
              if (event.resultCode != null) 'code': event.resultCode,
              if (event.mpfsCode != null) 'mpfs': event.mpfsCode,
            },
            errorCode: event.resultCode,
            phase: event.phase,
          ),
        );
        return;
      case LegacyPosTransportEventType.waitingForTerminal:
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.processing,
            messageKey: PaymentMessageKeys.posWaitingUser,
            phase: event.phase,
          ),
        );
        return;
      case LegacyPosTransportEventType.loading:
        String messageKey;
        switch (event.loadingState) {
          case LegacyPosLoadingState.terminalProcessing:
            messageKey = PaymentMessageKeys.posTerminalProcessing;
            break;
          case LegacyPosLoadingState.finalizing:
          case null:
            messageKey = PaymentMessageKeys.posFinalizing;
            break;
        }
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.processing,
            messageKey: messageKey,
            phase: event.phase,
          ),
        );
        return;
      case LegacyPosTransportEventType.success:
        final payload = event.payload;
        if (payload == null) {
          entry.emit(
            PosPaymentStatus(
              type: PosPaymentStatusType.failure,
              messageKey: PaymentMessageKeys.errorUnknown,
              errorType: PaymentErrorType.device,
              retryable: true,
              phase: event.phase,
            ),
          );
          unawaited(finishSession(sessionId));
          return;
        }
        unawaited(_handleSuccess(payload));
        return;
      case LegacyPosTransportEventType.cancelled:
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.cancelled,
            messageKey: PaymentMessageKeys.posTerminalCancelled,
            messageArgs: {
              if (event.resultCode != null) 'code': event.resultCode,
              if (event.mpfsCode != null) 'mpfs': event.mpfsCode,
            },
            details: {
              if (event.resultCode != null) 'code': event.resultCode,
              if (event.mpfsCode != null) 'mpfs': event.mpfsCode,
            },
            errorCode: event.resultCode,
            errorType: event.errorType ?? PaymentErrorType.userCancelled,
            retryable: event.retryable ?? true,
            phase: event.phase,
          ),
        );
        unawaited(finishSession(sessionId));
        return;
      case LegacyPosTransportEventType.timeout:
        final errorType =
            event.errorType ?? _timeoutErrorTypeForPhase(event.phase);
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.failure,
            messageKey: PaymentMessageKeys.posTimeout,
            messageArgs: event.message == null
                ? null
                : {'detail': event.message},
            errorCode: event.resultCode,
            errorType: errorType,
            retryable: event.retryable ?? _retryableForErrorType(errorType),
            phase: event.phase,
          ),
        );
        unawaited(finishSession(sessionId));
        return;
      case LegacyPosTransportEventType.error:
        final errorType =
            event.errorType ??
            _errorTypeForTransportMessage(
              event.message ?? event.resultCode ?? '',
              event.phase,
            );
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.failure,
            message: event.message,
            messageArgs: event.message == null
                ? null
                : {'detail': event.message},
            errorCode:
                event.resultCode ??
                ((event.message != null && _looksLikeErrorCode(event.message!))
                    ? event.message
                    : null),
            errorType: errorType,
            retryable: event.retryable ?? _retryableForErrorType(errorType),
            phase: event.phase,
          ),
        );
        unawaited(finishSession(sessionId));
        return;
      case LegacyPosTransportEventType.done:
        entry.emit(
          PosPaymentStatus(
            type: PosPaymentStatusType.cancelled,
            messageKey: PaymentMessageKeys.posTerminalDone,
            messageArgs: {'action': (event.action ?? PosAction.none).name},
            details: {'action': (event.action ?? PosAction.none).name},
            errorType: PaymentErrorType.userCancelled,
            retryable: true,
            phase: event.phase,
          ),
        );
        unawaited(finishSession(sessionId));
        return;
    }
  }

  Future<void> _handleSuccess(String data) async {
    try {
      if (entry.supportsCard && entry.cardGateway != null) {
        final cardRequest =
            entry.cardRequest ?? await entry.ensureCardRequest(logger);
        final reportPayload = cardRequest?.data;
        if (reportPayload != null) {
          entry.updatePhase(PaymentPhase.confirming);
          entry.emit(
            const PosPaymentStatus(
              type: PosPaymentStatusType.processing,
              messageKey: PaymentMessageKeys.posReportResult,
              phase: PaymentPhase.confirming,
            ),
          );
          await entry.cardGateway!.reportPayment(
            reportPayload: reportPayload,
            paymentInfo: data,
          );
        }
      }
      logger.fine('POS payment success data: $data');
      entry.emit(
        const PosPaymentStatus(
          type: PosPaymentStatusType.success,
          messageKey: PaymentMessageKeys.posPaymentSuccess,
        ),
      );
    } catch (e, stack) {
      logger.severe('POS payment success handling failed', e, stack);
      final errorType = _errorTypeForException(e);
      entry.emit(
        PosPaymentStatus(
          type: PosPaymentStatusType.failure,
          messageKey: PaymentMessageKeys.posResultHandleFailed,
          messageArgs: {'detail': _errorDetail(e)},
          errorCode: _errorCodeForException(e),
          errorType: errorType,
          retryable: _retryableForErrorType(errorType),
          phase: entry.currentPhase,
        ),
      );
    } finally {
      await finishSession(sessionId);
    }
  }
}

PaymentErrorType _errorTypeForTransportMessage(
  String message,
  PaymentPhase? phase,
) {
  final normalized = message.toLowerCase();
  if (normalized.contains('timeout') || normalized.contains('disconnected')) {
    return _timeoutErrorTypeForPhase(phase);
  }
  if (_looksLikeErrorCode(message)) {
    return PaymentErrorType.device;
  }
  return PaymentErrorType.device;
}

PaymentErrorType _timeoutErrorTypeForPhase(PaymentPhase? phase) {
  if (phase == null) {
    return PaymentErrorType.device;
  }
  switch (phase) {
    case PaymentPhase.connecting:
    case PaymentPhase.requesting:
    case PaymentPhase.sending:
      return PaymentErrorType.network;
    case PaymentPhase.waitingUser:
    case PaymentPhase.waitingTerminalResult:
    case PaymentPhase.confirming:
    case PaymentPhase.initializing:
      return PaymentErrorType.device;
  }
}

PaymentErrorType _errorTypeForException(Object error) {
  final code = _errorCodeForException(error);
  switch (code) {
    case 'POS_IP_MISSING':
    case 'POS_PORT_INVALID':
    case 'POS_CONFIG_MISSING':
    case 'POS_CARD_GATEWAY_REQUIRED':
    case 'POS_CANCEL_NOT_SUPPORTED':
      return PaymentErrorType.config;
    case 'POS_REQUEST_DATA_MISSING':
    case 'POS_CANCEL_INSTRUCTION_EMPTY':
      return PaymentErrorType.backend;
    case 'QR_SCAN_CANCELLED':
      return PaymentErrorType.userCancelled;
    default:
      return PaymentErrorType.device;
  }
}

bool _retryableForErrorType(PaymentErrorType errorType) {
  switch (errorType) {
    case PaymentErrorType.config:
      return false;
    case PaymentErrorType.userCancelled:
    case PaymentErrorType.device:
    case PaymentErrorType.network:
    case PaymentErrorType.backend:
    case PaymentErrorType.unknown:
      return true;
  }
}

String _errorDetail(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  if (error is ArgumentError) {
    return error.message?.toString() ?? error.toString();
  }
  return error.toString();
}

String? _errorCodeForException(Object error) {
  final detail = _errorDetail(error);
  return _looksLikeErrorCode(detail) ? detail : null;
}

bool _looksLikeErrorCode(String value) {
  final code = value.trim();
  return RegExp(r'^[A-Z0-9_]{3,}$').hasMatch(code);
}

class LegacyPosPaymentPayload {
  LegacyPosPaymentPayload({
    required this.paymentCode,
    required this.posIp,
    required this.posPort,
    required this.machineCode,
    required this.requestData,
    this.cancelData,
  });

  final String paymentCode;
  final String posIp;
  final int posPort;
  final String machineCode;
  final String requestData;
  final String? cancelData;

  LegacyPosPaymentPayload copyWith({String? requestData, String? cancelData}) {
    return LegacyPosPaymentPayload(
      paymentCode: paymentCode,
      posIp: posIp,
      posPort: posPort,
      machineCode: machineCode,
      requestData: requestData ?? this.requestData,
      cancelData: cancelData ?? this.cancelData,
    );
  }

  static LegacyPosPaymentPayload fromRequest(PosPaymentRequest request) {
    final map = request.customPayload;
    if (map == null) {
      throw ArgumentError('POS_CONFIG_MISSING');
    }

    String? readString(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is String) return value;
      if (value is num) return value.toString();
      return null;
    }

    final payment = readString('paymentCode') ?? readString('payment');
    final ip = readString('posIp') ?? readString('ip');
    final machineCode = readString('machineCode') ?? request.order.orderId;
    final requestData =
        readString('requestData') ?? readString('payload') ?? '';
    final cancelData = readString('cancelData');

    final portRaw = map['posPort'] ?? map['port'];
    int? port;
    if (portRaw is int) {
      port = portRaw;
    } else if (portRaw is String) {
      port = int.tryParse(portRaw);
    }

    if (payment == null || ip == null || port == null) {
      throw ArgumentError('POS_CONFIG_MISSING');
    }

    return LegacyPosPaymentPayload(
      paymentCode: payment,
      posIp: ip,
      posPort: port,
      machineCode: machineCode,
      requestData: requestData,
      cancelData: cancelData,
    );
  }
}
