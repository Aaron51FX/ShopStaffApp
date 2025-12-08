import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import '../../../data/providers.dart';

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
  bool _isRestarting = false;

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
        timeline: <PaymentStatus>[_snapshotStatus(initial)],
        hasStarted: true,
        requiresManualCompletion: session.requiresManualCompletion,
        confirmationReady: false,
        pendingReceipt: null,
      );

      _statusSubscription = _orchestrator.watch(session.sessionId).listen((status) {
        final previous = state;
        debugPrint('Payment status update: ${status.type} - ${status.message}');
        final timeline = List<PaymentStatus>.from(previous.timeline)..add(_snapshotStatus(status));
        final dialogUpdate = _cancelDialogStateForStatus(status, previous.cancelDialog);
          var confirmationReady = previous.confirmationReady;
          var pendingReceipt = previous.pendingReceipt;
          final stage = status.details?['stage'];
          if (stage == 'await_confirmation') {
            final receipt = status.details?['receipt'] as Map<String, dynamic>?;
            if (receipt != null) {
              pendingReceipt = Map<String, dynamic>.from(receipt);
            }
          } else if (stage == 'amount') {
            final amount = status.details?['amount'];
            final isFinal = status.details?['isFinal'] == true;
            if (amount is num) {
              final meetsRequirement = amount >= _expectedAmount;
              confirmationReady = isFinal && meetsRequirement;
              pendingReceipt = confirmationReady
                  ? _mergeReceiptAmount(pendingReceipt, amount)
                  : null;
            } else {
              confirmationReady = false;
              pendingReceipt = null;
            }
          }
          if (status.isTerminal || status.type == PaymentStatusType.failure) {
            confirmationReady = false;
            pendingReceipt = null;
          }
          state = previous.copyWith(
            currentStatus: status,
            timeline: timeline,
            cancelDialog: dialogUpdate ?? previous.cancelDialog,
            confirmationReady: confirmationReady,
            pendingReceipt: pendingReceipt,
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

  Future<void> retryPayment() async {
    if (_isRestarting || state.isCancelling) return;
    _isRestarting = true;
    try {
      await _teardownActiveSession(releaseQrScanner: true);
      state = const PaymentFlowState();
      await _start();
    } finally {
      _isRestarting = false;
    }
  }

  Map<String, dynamic>? _prepareChannelConfig() {
    final raw = _args.channelConfig;
    final config = <String, dynamic>{};
    if (raw != null) {
      raw.forEach((key, value) {
        if (value != null) config[key] = value;
      });
    }

    config.putIfAbsent('machineCode', () => _args.metadata?['machineCode']);

    final posInfo = _ref.read(appSettingsSnapshotProvider)?.posTerminal;
    final needsPos = _args.channelGroup == PaymentChannels.card || _args.channelGroup == PaymentChannels.qr;
    if (needsPos) {
      final ip = posInfo?.posIp?.toString();
      final dynamic portRaw = posInfo?.posPort;
      int? port;
      if (portRaw is int) {
        port = portRaw;
      } else if (portRaw is String) {
        port = int.tryParse(portRaw);
      }

      if (_args.channelGroup == PaymentChannels.card) {
        if (ip == null || ip.isEmpty) {
          throw StateError('POS终端 IP 未配置');
        }
        if (port == null) {
          throw StateError('POS终端端口未配置或格式错误');
        }
      }

      if (ip != null && ip.isNotEmpty) {
        config['posIp'] = ip;
      }
      if (port != null) {
        config['posPort'] = port;
      }
      config['paymentCode'] = (config['paymentCode'] ?? '3').toString();
      config.putIfAbsent('authCode', () => '0000000088888888');
    }

    return config.isEmpty ? null : config;
  }

  void cancelPayment() async {
    final ok = await _ref
        .read(dialogControllerProvider.notifier)
        .confirm(title: '注意', message: '确认要取消支付吗？', destructive: true);
    if (ok) {
      _cancelPayment();
    }
  }

  Future<void> confirmManualPayment() async {
    if (!state.requiresManualCompletion || !state.confirmationReady || state.isConfirming) return;
    final id = state.sessionId;
    if (id == null) return;
    state = state.copyWith(isConfirming: true);
    try {
      await _orchestrator.finalize(id);
    } catch (e, stack) {
      _logger.warning('Confirm payment failed', e, stack);
      SimpleToast.errorGlobal('确认现金支付失败: $e');
    } finally {
      state = state.copyWith(isConfirming: false);
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

  int get _expectedAmount => _args.order.total;

  Map<String, dynamic> _mergeReceiptAmount(
    Map<String, dynamic>? current,
    num amount,
  ) {
    final receipt = <String, dynamic>{
      'expectedAmount': _expectedAmount,
    };
    if (current != null) {
      receipt.addAll(current);
    }
    receipt['acceptedAmount'] = amount.toInt();
    return receipt;
  }

  PaymentStatus _snapshotStatus(PaymentStatus status) {
    final details = status.details;
    Map<String, dynamic>? clonedDetails;
    if (details != null) {
      clonedDetails = Map<String, dynamic>.from(details);
    }
    return PaymentStatus(
      type: status.type,
      message: status.message,
      details: clonedDetails,
    );
  }

  Future<void> _teardownActiveSession({bool releaseQrScanner = false}) async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    final sessionId = state.sessionId;
    final shouldReleaseScanner = releaseQrScanner && _args.channelGroup == PaymentChannels.qr;

    if (sessionId != null && !state.isFinished) {
      try {
        await _orchestrator.cancel(sessionId);
      } catch (error, stack) {
        _logger.fine('Teardown cancel failed: $error', error, stack);
      }
    }

    if (shouldReleaseScanner) {
      try {
        await _ref.read(dialogDrivenQrScannerProvider).cancelScan();
      } catch (error, stack) {
        _logger.fine('Scanner reset failed: $error', error, stack);
      }
    }

    _resultFuture = null;
  }

  @override
  void dispose() {
    unawaited(_teardownActiveSession(releaseQrScanner: true));
    super.dispose();
  }
}
