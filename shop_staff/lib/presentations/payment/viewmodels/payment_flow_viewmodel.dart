import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/application/payments/payment_flow_usecase.dart';
import 'package:shop_staff/application/payments/usecases/start_payment_usecase.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import '../../../data/providers.dart';

abstract class PaymentFlowEffect {
  const PaymentFlowEffect();
}

class PaymentFlowToastEffect extends PaymentFlowEffect {
  const PaymentFlowToastEffect({required this.message, this.isError = false});

  final String message;
  final bool isError;
}

class PaymentFlowRequestCancelConfirmEffect extends PaymentFlowEffect {
  const PaymentFlowRequestCancelConfirmEffect({
    required this.title,
    required this.message,
    this.destructive = true,
  });

  final String title;
  final String message;
  final bool destructive;
}

class PaymentFlowStartPrintEffect extends PaymentFlowEffect {
  const PaymentFlowStartPrintEffect();
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
  bool _isRestarting = false;
  final StreamController<PaymentFlowEffect> _effects =
      StreamController<PaymentFlowEffect>.broadcast();

  Stream<PaymentFlowEffect> get effects => _effects.stream;

  void _emit(PaymentFlowEffect effect) {
    if (_effects.isClosed) return;
    _effects.add(effect);
  }

  PaymentFlowUseCase get _useCase => _ref.read(paymentFlowUseCaseProvider);

  Future<void> _start() async {
    try {
      final run = _useCase.start(_args);
      _bindRun(run);
    } catch (e, stack) {
      _handleError(e, stack);
    }
  }

  void _bindRun(PaymentFlowStartResult run) {
    final session = run.session;
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

    _statusSubscription = run.statuses.listen((status) {
      final previous = state;
      debugPrint('Payment status update: ${status.type} - ${status.message}');
      final timeline = List<PaymentStatus>.from(previous.timeline)
        ..add(_snapshotStatus(status));
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

    _resultFuture = run.result;
    _resultFuture
        ?.then((result) {
          state = state.copyWith(result: result);
          switch (result.status) {
            case PaymentStatusType.success:
              _emit(PaymentFlowToastEffect(message: result.message ?? '支付成功'));
              _emit(const PaymentFlowStartPrintEffect());
              break;
            case PaymentStatusType.failure:
              _emit(PaymentFlowToastEffect(message: result.message ?? '支付失败', isError: true));
              break;
            case PaymentStatusType.cancelled:
            default:
              break;
          }
        })
        .catchError((error, stack) {
          _handleError(
            error,
            stack is StackTrace ? stack : StackTrace.current,
          );
        });
  }

  Future<void> retryPayment() async {
    if (_isRestarting || state.isCancelling) return;
    _isRestarting = true;
    final previousSessionId = state.sessionId;
    try {
      await _teardownActiveSession(releaseQrScanner: true, cancelSession: false);
      state = const PaymentFlowState();
      final run = await _useCase.retry(args: _args, previousSessionId: previousSessionId);
      _bindRun(run);
    } finally {
      _isRestarting = false;
    }
  }

  void cancelPayment() {
    _emit(
      const PaymentFlowRequestCancelConfirmEffect(
        title: '注意',
        message: '确认要取消支付吗？',
        destructive: true,
      ),
    );
  }

  Future<void> confirmCancelPayment() async {
    await _cancelPayment();
  }

  Future<void> confirmManualPayment() async {
    if (!state.requiresManualCompletion || !state.confirmationReady || state.isConfirming) return;
    final id = state.sessionId;
    if (id == null) return;
    state = state.copyWith(isConfirming: true);
    try {
      await _useCase.finalize(id);
    } catch (e, stack) {
      _logger.warning('Confirm payment failed', e, stack);
      _emit(PaymentFlowToastEffect(message: '确认现金支付失败: $e', isError: true));
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
      await _useCase.cancel(id);
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
      _emit(PaymentFlowToastEffect(message: message, isError: true));
    }
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

  Future<void> _teardownActiveSession({
    bool releaseQrScanner = false,
    bool cancelSession = true,
    PaymentFlowState? snapshot,
  }) async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    final current = snapshot ?? state;
    final sessionId = current.sessionId;
    final shouldReleaseScanner = releaseQrScanner && _args.channelGroup == PaymentChannels.qr;

    if (cancelSession && sessionId != null && !current.isFinished) {
      try {
        await _useCase.cancel(sessionId);
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
    final snapshot = state;
    unawaited(_teardownActiveSession(releaseQrScanner: true, snapshot: snapshot));
    unawaited(_effects.close());
    super.dispose();
  }
}
