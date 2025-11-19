import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';

class PosPaymentOrchestrator implements PaymentOrchestrator {
  PosPaymentOrchestrator({
    required Map<String, PaymentFlow> flows,
    Logger? logger,
  })  : _flows = flows,
        _logger = logger ?? Logger('PosPaymentOrchestrator');

  final Map<String, PaymentFlow> _flows;
  final Logger _logger;
  final Map<String, _PaymentSessionEntry> _sessions = {};
  final Random _random = Random();

  @override
  PaymentSession start(PaymentContext context) {
    final key = context.channel.group;
    final flow = _flows[key];
    if (flow == null) {
      throw UnsupportedError('当前不支持的支付方式: ${context.channel.group}');
    }

    final run = flow.start(context);
    final sessionId = _generateSessionId();
    final controller = StreamController<PaymentStatus>.broadcast();
    final entry = _PaymentSessionEntry(run: run, controller: controller);
    _sessions[sessionId] = entry;

    final initialStatus = PaymentStatus(
      type: PaymentStatusType.pending,
      message: '支付流程启动(${context.channel.displayName ?? context.channel.group})',
    );
    controller.add(initialStatus);
    entry.lastStatus = initialStatus;

    entry.subscription = run.statuses.listen(
      (status) {
        entry.lastStatus = status;
        controller.add(status);
      },
      onError: (error, stack) {
        _logger.warning('支付状态流异常: $error', error, stack);
        if (!entry.completer.isCompleted) {
          entry.completer.complete(
            PaymentResult.failure(message: error.toString()),
          );
        }
        controller.add(PaymentStatus(type: PaymentStatusType.failure, message: error.toString()));
      },
      onDone: () {
        if (!entry.completer.isCompleted) {
          // Fallback: mark as failure if the run completed without result.
          entry.completer.complete(
            PaymentResult.failure(message: '支付流程已结束'),
          );
        }
      },
    );

    run.result.then((result) {
      if (!entry.completer.isCompleted) {
        entry.completer.complete(result);
      }
      if (entry.lastStatus?.isTerminal != true) {
        controller.add(_statusFromResult(result));
      }
    }).catchError((error, stack) {
      _logger.severe('支付流程执行失败', error, stack);
      if (!entry.completer.isCompleted) {
        entry.completer.complete(
          PaymentResult.failure(message: error.toString()),
        );
      }
      controller.add(PaymentStatus(type: PaymentStatusType.failure, message: error.toString()));
    }).whenComplete(() async {
      await entry.subscription?.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
      _sessions.remove(sessionId);
    });

    return PaymentSession(sessionId: sessionId, initialStatus: initialStatus);
  }

  @override
  Stream<PaymentStatus> watch(String sessionId) {
    final entry = _sessions[sessionId];
    if (entry == null) {
      return Stream<PaymentStatus>.value(
        const PaymentStatus(type: PaymentStatusType.failure, message: '支付会话不存在'),
      );
    }
    return entry.controller.stream;
  }

  @override
  Future<PaymentResult> result(String sessionId) {
    final entry = _sessions[sessionId];
    if (entry == null) {
      return Future.value(
        PaymentResult.failure(message: '支付会话不存在'),
      );
    }
    return entry.completer.future;
  }

  @override
  Future<void> cancel(String sessionId) async {
    final entry = _sessions[sessionId];
    if (entry == null) {
      throw StateError('支付会话不存在');
    }
    try {
      await entry.run.cancel();
    } catch (e, stack) {
      _logger.warning('取消支付流程失败', e, stack);
      rethrow;
    }
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1 << 32);
    return '$timestamp-$randomPart';
  }

  PaymentStatus _statusFromResult(PaymentResult result) {
    switch (result.status) {
      case PaymentStatusType.success:
        return PaymentStatus(type: PaymentStatusType.success, message: result.message, details: result.payload);
      case PaymentStatusType.cancelled:
        return PaymentStatus(type: PaymentStatusType.cancelled, message: result.message, details: result.payload);
      case PaymentStatusType.failure:
      default:
        return PaymentStatus(type: PaymentStatusType.failure, message: result.message, details: result.payload);
    }
  }
}

class _PaymentSessionEntry {
  _PaymentSessionEntry({required this.run, required this.controller});

  final PaymentFlowRun run;
  final StreamController<PaymentStatus> controller;
  final Completer<PaymentResult> completer = Completer<PaymentResult>();
  StreamSubscription<PaymentStatus>? subscription;
  PaymentStatus? lastStatus;
}
