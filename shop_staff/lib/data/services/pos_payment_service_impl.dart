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
  })  : _managerFactory = managerFactory ?? (() => LegacyPosSocketManager(logger: logger)),
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
    final controller = StreamController<PosPaymentStatus>.broadcast();
    const initialStatus = PosPaymentStatus(type: PosPaymentStatusType.pending);
    final pendingStatuses = <PosPaymentStatus>[initialStatus];

    var payload = LegacyPosPaymentPayload.fromRequest(request);
    CardPaymentRequestData? cardRequest;
    final prefetched = request.customPayload?[prefetchedCardRequestKey];
    if (prefetched is CardPaymentRequestData) {
      cardRequest = prefetched;
    }

    if (_shouldUseCardGateway(request)) {
      final gateway = _cardGateway;
      if (gateway == null) {
        await controller.close();
        throw StateError('PosCardPaymentGateway is required for card payments');
      }
      pendingStatuses.add(const PosPaymentStatus(type: PosPaymentStatusType.processing, message: '获取POS支付数据'));
      try {
        cardRequest ??= await gateway.createPaymentRequest(request);
        if (cardRequest.hasError) {
          final msg = cardRequest.exceptionMessage ?? 'POS支付数据异常';
          await controller.close();
          throw StateError(msg);
        }
        final requestInfo = cardRequest.requestInfo;
        if (requestInfo == null || requestInfo.isEmpty) {
          const msg = 'POS支付缺少请求数据';
          await controller.close();
          throw StateError(msg);
        }
        payload = payload.copyWith(requestData: requestInfo);
      } catch (e, stack) {
        _logger.severe('Failed to prepare card payment data', e, stack);
        await controller.close();
        rethrow;
      }
    }

    final manager = _managerFactory();
    final entry = _PosSessionEntry(
      controller: controller,
      manager: manager,
      payload: payload,
      request: request,
      cardGateway: _shouldUseCardGateway(request) ? _cardGateway : null,
      initialCardRequest: cardRequest,
      initialCancelData: payload.cancelData,
    );
    _sessions[sessionId] = entry;

    scheduleMicrotask(() {
      if (controller.isClosed) return;
      for (final status in pendingStatuses) {
        controller.add(status);
      }
      pendingStatuses.clear();
    });

    unawaited(_runSession(sessionId));

    return PosPaymentSession(sessionId: sessionId, initialStatus: initialStatus);
  }

  @override
  Stream<PosPaymentStatus> watchStatus(String sessionId) {
    final entry = _sessions[sessionId];
    if (entry == null) {
      return Stream.value(
        const PosPaymentStatus(type: PosPaymentStatusType.failure, message: '会话不存在或已结束'),
      );
    }
    return entry.controller.stream;
  }

  @override
  Future<void> cancel(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) {
      throw StateError('支付会话不存在或已结束');
    }
    if (entry.isCompleted) {
      return;
    }

    void emit(PosPaymentStatus status) {
      if (entry.isCompleted) return;
      if (!entry.controller.isClosed) {
        entry.controller.add(status);
      }
    }

    emit(const PosPaymentStatus(type: PosPaymentStatusType.processing, message: '正在取消POS交易…'));

    try {
      if (entry.supportsCard && entry.cardGateway != null) {
        final instruction = await entry.ensureCancelInstruction(_logger);
        final payload = instruction.payload;
        if (payload.isEmpty) {
          throw StateError('POS取消指令为空');
        }

        await entry.manager.write(PosAction.cancel, payload);
      } else {
        emit(const PosPaymentStatus(type: PosPaymentStatusType.cancelled, message: '操作员取消交易'));
        await _finishSession(sessionId);
      }
    } catch (e, stack) {
      _logger.severe('POS取消失败', e, stack);
      emit(PosPaymentStatus(type: PosPaymentStatusType.failure, message: 'POS取消失败: $e'));
      await _finishSession(sessionId);
      throw StateError('POS取消失败: $e');
    }
  }

  Future<void> _runSession(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) return;
    final payload = entry.payload;
    final controller = entry.controller;
    try {
      await entry.manager.payConnectSocket(
        payload.paymentCode,
        payload.posIp,
        payload.posPort,
        payload.machineCode,
        payload.requestData,
        onError: (msg) {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(PosPaymentStatus(type: PosPaymentStatusType.failure, message: msg));
        },
        onLoading: (mode) {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(PosPaymentStatus(type: PosPaymentStatusType.processing, message: '加载中($mode)'));
        },
        onLoadingEnd: () {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(const PosPaymentStatus(type: PosPaymentStatusType.processing, message: '等待终端操作'));
        },
        onSuccess: (data) {
          if (entry.isCompleted || controller.isClosed) return;
          unawaited(_handleSessionSuccess(sessionId, entry, data));
        },
        onRequestPayData: () {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(const PosPaymentStatus(type: PosPaymentStatusType.processing, message: '请求付款数据'));
        },
        onDone: (action) {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(PosPaymentStatus(
            type: PosPaymentStatusType.cancelled,
            message: '终端完成操作: ${action.name}',
          ));
          unawaited(_finishSession(sessionId));
        },
        onCancel: (code, mpfs) {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(PosPaymentStatus(
            type: PosPaymentStatusType.cancelled,
            message: '终端取消 code=$code mpfs=$mpfs',
            errorCode: code,
          ));
          unawaited(_finishSession(sessionId));
        },
        onTimeOut: () {
          if (entry.isCompleted || controller.isClosed) return;
          controller.add(const PosPaymentStatus(type: PosPaymentStatusType.failure, message: 'POS连接超时'));
          unawaited(_finishSession(sessionId));
        },
      );
    } catch (e, stack) {
      _logger.severe('POS payment session failed', e, stack);
      if (!entry.isCompleted && !controller.isClosed) {
        controller.add(PosPaymentStatus(type: PosPaymentStatusType.failure, message: e.toString()));
      }
      await _finishSession(sessionId);
    }
  }

  Future<void> _handleSessionSuccess(String sessionId, _PosSessionEntry entry, String data) async {
    final controller = entry.controller;
    try {
      if (entry.supportsCard && entry.cardGateway != null) {
        final cardRequest = _sessions[sessionId]?.cardRequest ??
            await entry.ensureCardRequest(_logger);
        final reportPayload = cardRequest?.data;
        // final reportPayload = cardData?.reportPayload;
        if (cardRequest == null && reportPayload != null) {
          controller.add(const PosPaymentStatus(type: PosPaymentStatusType.processing, message: '上报支付结果'));
          await entry.cardGateway!.reportPayment(reportPayload: reportPayload, paymentInfo: data);
        }
      }
      if (!entry.isCompleted && !controller.isClosed) {
        _logger.fine('POS payment success data: $data');
        controller.add(const PosPaymentStatus(type: PosPaymentStatusType.success, message: '支付成功'));
      }
    } catch (e, stack) {
      _logger.severe('POS payment success handling failed', e, stack);
      if (!entry.isCompleted && !controller.isClosed) {
        controller.add(PosPaymentStatus(type: PosPaymentStatusType.failure, message: 'POS支付结果处理失败: $e'));
      }
    } finally {
      await _finishSession(sessionId);
    }
  }

  Future<void> _finishSession(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) return;
    if (entry.isCompleted) return;
    entry.isCompleted = true;
    try {
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
    this.cardGateway,
    CardPaymentRequestData? initialCardRequest,
    String? initialCancelData,
  })  : cardRequest = initialCardRequest,
        cancelInstruction = (initialCancelData != null && initialCancelData.isNotEmpty)
            ? CardCancelInstruction(payload: initialCancelData)
            : null;

  final StreamController<PosPaymentStatus> controller;
  final LegacyPosSocketManager manager;
  final LegacyPosPaymentPayload payload;
  final PosPaymentRequest request;
  final PosCardPaymentGateway? cardGateway;
  CardPaymentRequestData? cardRequest;
  CardCancelInstruction? cancelInstruction;
  bool isCompleted = false;

  bool get supportsCard => cardGateway != null;

  Future<CardPaymentRequestData?> ensureCardRequest(Logger logger) async {
    if (!supportsCard) return cardRequest;
    if (cardRequest != null) return cardRequest;
    try {
      final data = await cardGateway!.createPaymentRequest(request);
      if (data.hasError) {
        throw StateError(data.exceptionMessage ?? 'POS支付数据异常');
      }
      final info = data.requestInfo;
      if (info == null || info.isEmpty) {
        throw StateError('POS支付缺少请求数据');
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
      throw StateError('当前POS会话不支持取消指令');
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
      throw ArgumentError('POS payment请求缺少终端配置(customPayload)');
    }

    String? _readString(String key) {
      final value = map[key];
      if (value == null) return null;
      if (value is String) return value;
      if (value is num) return value.toString();
      return null;
    }

    final payment = _readString('paymentCode') ?? _readString('payment');
    final ip = _readString('posIp') ?? _readString('ip');
    final machineCode = _readString('machineCode') ?? request.order.orderId;
    final requestData = _readString('requestData') ?? _readString('payload') ?? '';
    final cancelData = _readString('cancelData');

    final portRaw = map['posPort'] ?? map['port'];
    int? port;
    if (portRaw is int) {
      port = portRaw;
    } else if (portRaw is String) {
      port = int.tryParse(portRaw);
    }

    if (payment == null || ip == null || port == null) {
      throw ArgumentError('POS payment请求缺少必要参数(paymentCode/ip/port/machineCode)');
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
