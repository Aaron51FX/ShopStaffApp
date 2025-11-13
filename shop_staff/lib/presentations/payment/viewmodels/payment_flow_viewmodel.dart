import 'dart:async';

import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';

import '../../../data/providers.dart';
import '../../../domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart'
    show PaymentChannel;

class PaymentFlowPageArgs {
  const PaymentFlowPageArgs({
    required this.order,
    required this.channelGroup,
    required this.channelCode,
    this.channelDisplayName,
    this.channelConfig,
    this.metadata,
  });

  final OrderSubmissionResult order;
  final String channelGroup;
  final String channelCode;
  final String? channelDisplayName;
  final Map<String, dynamic>? channelConfig;
  final Map<String, dynamic>? metadata;
}

class PaymentFlowState {
  const PaymentFlowState({
    this.sessionId,
    this.currentStatus,
    this.timeline = const <PaymentStatus>[],
    this.result,
    this.error,
    this.isCancelling = false,
    this.hasStarted = false,
  });

  final String? sessionId;
  final PaymentStatus? currentStatus;
  final List<PaymentStatus> timeline;
  final PaymentResult? result;
  final String? error;
  final bool isCancelling;
  final bool hasStarted;

  bool get isFinished => result != null || (currentStatus?.isTerminal ?? false);
  bool get canExit => error != null || isFinished;

  PaymentFlowState copyWith({
    String? sessionId,
    PaymentStatus? currentStatus,
    List<PaymentStatus>? timeline,
    PaymentResult? result,
    String? error,
    bool? isCancelling,
    bool? hasStarted,
  }) {
    return PaymentFlowState(
      sessionId: sessionId ?? this.sessionId,
      currentStatus: currentStatus ?? this.currentStatus,
      timeline: timeline ?? this.timeline,
      result: result ?? this.result,
      error: error,
      isCancelling: isCancelling ?? this.isCancelling,
      hasStarted: hasStarted ?? this.hasStarted,
    );
  }
}

final paymentFlowViewModelProvider = StateNotifierProvider.autoDispose
    .family<PaymentFlowViewModel, PaymentFlowState, PaymentFlowPageArgs>(
      (ref, args) => PaymentFlowViewModel(ref, args),
    );

class PaymentFlowViewModel extends StateNotifier<PaymentFlowState> {
  PaymentFlowViewModel(this._ref, this._args)
    : _logger = Logger('PaymentFlowViewModel'),
      super(const PaymentFlowState()) {
    _start();
  }

  final Ref _ref;
  final PaymentFlowPageArgs _args;
  final Logger _logger;

  StreamSubscription<PaymentStatus>? _statusSubscription;
  Future<PaymentResult>? _resultFuture;

  PaymentOrchestrator get _orchestrator =>
      _ref.read(paymentOrchestratorProvider);

  Future<void> _start() async {
    Map<String, dynamic>? config;
    try {
      config = _prepareChannelConfig();
    } catch (e, stack) {
      _logger.warning('Invalid payment configuration', e, stack);
      state = state.copyWith(error: e.toString());
      SimpleToast.errorGlobal(e.toString());
      return;
    }

    final channel = PaymentChannel(
      group: _args.channelGroup,
      code: _args.channelCode,
      displayName: _args.channelDisplayName,
    );
    final context = PaymentContext(
      order: _args.order,
      channel: channel,
      channelConfig: config,
      metadata: _args.metadata,
    );

    try {
      final session = _orchestrator.start(context);
      final initial = session.initialStatus;
      state = state.copyWith(
        sessionId: session.sessionId,
        currentStatus: initial,
        timeline: <PaymentStatus>[initial],
        hasStarted: true,
      );

      _statusSubscription = _orchestrator.watch(session.sessionId).listen((
        status,
      ) {
        final timeline = List<PaymentStatus>.from(state.timeline)..add(status);
        state = state.copyWith(currentStatus: status, timeline: timeline);
      }, onError: (error, stack) => _handleError(error, stack));

      _resultFuture = _orchestrator.result(session.sessionId);
      _resultFuture
          ?.then((result) {
            state = state.copyWith(result: result);
          })
          .catchError((error, stack) {
            _handleError(
              error,
              stack is StackTrace ? stack : StackTrace.current,
            );
          });
    } catch (e, stack) {
      _handleError(e, stack);
    }
  }

  Map<String, dynamic>? _prepareChannelConfig() {
    final raw = _args.channelConfig;
    if (raw == null) {
      if (_args.channelGroup == PaymentChannels.card) {
        throw StateError('缺少POS终端配置，无法执行信用卡支付');
      }
      return null;
    }

    final config = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value != null) config[key] = value;
    });

    config.putIfAbsent('machineCode', () => _args.metadata?['machineCode']);

    if (_args.channelGroup == PaymentChannels.card) {
      final ip = '172.50.10.28'; //config['posIp'] ?? config['ip'];
      final portRaw = 9999; //config['posPort'] ?? config['port'];
      if (ip == null || ip.toString().isEmpty) {
        throw StateError('POS终端 IP 未配置');
      }
      if (portRaw == null || portRaw.toString().isEmpty) {
        throw StateError('POS终端端口未配置');
      }
      final port = portRaw is int ? portRaw : int.tryParse(portRaw.toString());
      if (port == null) {
        throw StateError('POS终端端口格式错误: $portRaw');
      }
      config['posIp'] = ip.toString();
      config['posPort'] = port;
      config['paymentCode'] = (config['paymentCode'] ?? '3').toString();
      config.putIfAbsent('authCode', () => '0000000088888888');
    }

    return config;
  }

  Future<void> cancelPayment() async {
    final id = state.sessionId;
    if (id == null || state.isCancelling || state.isFinished) return;
    state = state.copyWith(isCancelling: true);
    try {
      await _orchestrator.cancel(id);
    } catch (e, stack) {
      _handleError(e, stack);
    } finally {
      state = state.copyWith(isCancelling: false);
    }
  }

  void _handleError(Object error, StackTrace stack) {
    _logger.severe('Payment flow error', error, stack);
    final message = error.toString();
    if (state.error != message) {
      state = state.copyWith(error: message);
      SimpleToast.errorGlobal(message);
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
