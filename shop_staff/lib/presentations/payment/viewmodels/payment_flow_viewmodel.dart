import 'dart:async';

import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';

import '../../../data/providers.dart';
import '../../../domain/entities/order_submission_result.dart';

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

enum CancelDialogStatus { hidden, loading, success, failure }

class CancelDialogState {
  const CancelDialogState._(this.status, this.message);

  final CancelDialogStatus status;
  final String? message;

  bool get isVisible => status != CancelDialogStatus.hidden;
  bool get isTerminal =>
      status == CancelDialogStatus.success || status == CancelDialogStatus.failure;

  const CancelDialogState.hidden() : this._(CancelDialogStatus.hidden, null);

  factory CancelDialogState.loading(String? message) {
    return CancelDialogState._(CancelDialogStatus.loading, message);
  }

  factory CancelDialogState.success(String? message) {
    return CancelDialogState._(CancelDialogStatus.success, message);
  }

  factory CancelDialogState.failure(String? message) {
    return CancelDialogState._(CancelDialogStatus.failure, message);
  }
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
    this.cancelDialog = const CancelDialogState.hidden(),
  });

  final String? sessionId;
  final PaymentStatus? currentStatus;
  final List<PaymentStatus> timeline;
  final PaymentResult? result;
  final String? error;
  final bool isCancelling;
  final bool hasStarted;
  final CancelDialogState cancelDialog;

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
    CancelDialogState? cancelDialog,
  }) {
    return PaymentFlowState(
      sessionId: sessionId ?? this.sessionId,
      currentStatus: currentStatus ?? this.currentStatus,
      timeline: timeline ?? this.timeline,
      result: result ?? this.result,
      error: error,
      isCancelling: isCancelling ?? this.isCancelling,
      hasStarted: hasStarted ?? this.hasStarted,
      cancelDialog: cancelDialog ?? this.cancelDialog,
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

      _statusSubscription = _orchestrator.watch(session.sessionId).listen((status) {
        final previous = state;
        final timeline = List<PaymentStatus>.from(previous.timeline)..add(status);
        final dialogUpdate = _cancelDialogStateForStatus(status, previous.cancelDialog);
        state = previous.copyWith(
          currentStatus: status,
          timeline: timeline,
          cancelDialog: dialogUpdate ?? previous.cancelDialog,
        );
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
    final posInfo = _ref.read(appSettingsSnapshotProvider)?.posTerminal;
    if (posInfo == null || posInfo.posIp == null || posInfo.posPort == null || raw == null) {
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
      final ipSource = posInfo.posIp;
      final ip = ipSource?.toString();
      if (ip == null || ip.isEmpty) {
        throw StateError('POS终端 IP 未配置');
      }

      final portSource = posInfo.posPort;
      int? port;
      if (portSource is int) {
        port = portSource;
      } else if (portSource is String) {
        port = int.tryParse(portSource ?? '');
      }
      if (port == null) {
        throw StateError('POS终端端口未配置或格式错误');
      }
      config['posIp'] = ip.toString();
      config['posPort'] = port;
      config['paymentCode'] = (config['paymentCode'] ?? '3').toString();
      config.putIfAbsent('authCode', () => '0000000088888888');
    }

    return config;
  }

  void cancelPayment() async {
    final ok = await _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: '注意', message: '确认要取消支付吗？', destructive: true);
    if (ok) {
      _cancelPayment();
    }
  }


  Future<void> _cancelPayment() async {
    final id = state.sessionId;
    if (id == null || state.isCancelling || state.isFinished) return;
    state = state.copyWith(
      isCancelling: true,
      cancelDialog: CancelDialogState.loading(_cancelLoadingMessage()),
    );
    try {
      await _orchestrator.cancel(id);
    } catch (e, stack) {
      _logger.warning('Cancel payment failed', e, stack);
      state = state.copyWith(
        cancelDialog: CancelDialogState.failure('取消失败: $e'),
      );
    } finally {
      state = state.copyWith(isCancelling: false);
    }
  }

  void dismissCancelDialog() {
    if (state.cancelDialog.status != CancelDialogStatus.hidden) {
      state = state.copyWith(cancelDialog: const CancelDialogState.hidden());
    }
  }

  String _cancelLoadingMessage() {
    switch (_args.channelGroup) {
      case PaymentChannels.card:
        return '正在取消信用卡支付…';
      case PaymentChannels.cash:
        return '正在取消现金支付…';
      default:
        return '正在取消支付…';
    }
  }

  String _defaultCancelSuccessMessage() {
    switch (_args.channelGroup) {
      case PaymentChannels.card:
        return 'POS终端已取消交易';
      case PaymentChannels.cash:
        return '现金支付已取消';
      default:
        return '支付已取消';
    }
  }

  CancelDialogState? _cancelDialogStateForStatus(
    PaymentStatus status,
    CancelDialogState currentDialog,
  ) {
    if (currentDialog.status != CancelDialogStatus.loading) {
      return null;
    }
    if (status.type == PaymentStatusType.cancelled) {
      final message = (status.message != null && status.message!.trim().isNotEmpty)
          ? status.message
          : _defaultCancelSuccessMessage();
      return CancelDialogState.success(message);
    }
    if (status.type == PaymentStatusType.failure) {
      final fallback = '取消失败，请稍后重试';
      final message = (status.message != null && status.message!.trim().isNotEmpty)
          ? status.message
          : fallback;
      return CancelDialogState.failure(message);
    }
    return null;
  }

  void _handleError(Object error, StackTrace stack) {
    _logger.severe('Payment flow error', error, stack);
    final message = error.toString();
    if (state.error != message) {
      final dialogNeedsUpdate = state.cancelDialog.status == CancelDialogStatus.loading;
      final nextDialog = dialogNeedsUpdate ? CancelDialogState.failure(message) : state.cancelDialog;
      state = state.copyWith(error: message, cancelDialog: nextDialog);
      SimpleToast.errorGlobal(message);
    }
  }

  void goEntryPage() {
    _ref.read(appRouterProvider).go('/entry');
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
