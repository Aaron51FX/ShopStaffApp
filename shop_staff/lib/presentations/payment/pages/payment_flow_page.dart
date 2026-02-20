import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/data/services/payment_channel_support.dart';
import 'package:shop_staff/presentations/printing/show_print_dialog.dart';
import 'package:shop_staff/presentations/printing/print_job_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cash_amount_snapshot.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import 'package:shop_staff/presentations/payment/widgets/bottom_action_bar.dart';
import 'package:shop_staff/presentations/payment/widgets/cancel_dialog.dart';
import 'package:shop_staff/presentations/payment/widgets/cash_amount_card.dart';
import 'package:shop_staff/presentations/payment/widgets/order_summary.dart';
import 'package:shop_staff/presentations/payment/widgets/qr_scan_dialog.dart';
import 'package:shop_staff/presentations/payment/widgets/status_hero.dart';
import 'package:shop_staff/presentations/payment/widgets/status_time_line.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

import '../viewmodels/payment_flow_viewmodel.dart';

class PaymentFlowPage extends ConsumerStatefulWidget {
  const PaymentFlowPage({super.key, required this.args});

  final PaymentFlowPageArgs args;

  @override
  ConsumerState<PaymentFlowPage> createState() => _PaymentFlowPageState();
}

class _PaymentFlowPageState extends ConsumerState<PaymentFlowPage> {
  late final provider = paymentFlowViewModelProvider(widget.args);
  ProviderSubscription<CancelDialogState>? _cancelSubscription;
  StreamSubscription<PaymentFlowEffect>? _effectSubscription;
  ValueNotifier<CancelDialogState>? _cancelDialogNotifier;
  bool _isCancelDialogVisible = false;
  ProviderSubscription<QrScanUiState>? _qrScanSubscription;
  ValueNotifier<QrScanUiState>? _qrDialogNotifier;
  bool _isQrDialogVisible = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _effectSubscription = ref
        .read(provider.notifier)
        .effects
        .listen((effect) async {
      if (!mounted) return;
      if (effect is PaymentFlowToastEffect) {
        final t = AppLocalizations.of(context);
        final message = StatusHero.resolveMessage(
          t,
          key: effect.messageKey,
          args: effect.messageArgs,
          fallback: effect.message ?? '',
        );
        if (effect.isError) {
          SimpleToast.errorGlobal(message);
        } else {
          SimpleToast.successGlobal(message);
        }
        return;
      }
      if (effect is PaymentFlowRequestCancelConfirmEffect) {
        final ok = await ref.read(dialogControllerProvider.notifier).confirm(
              title: effect.title,
              message: effect.message,
              destructive: effect.destructive,
            );
        if (!mounted) return;
        if (ok) {
          await ref.read(provider.notifier).confirmCancelPayment();
        }
        return;
      }
      if (effect is PaymentFlowStartPrintEffect) {
        await _startPrintFlow();
        return;
      }
    });

    _cancelSubscription = ref.listenManual<CancelDialogState>(
      provider.select((state) => state.cancelDialog),
      (previous, next) {
        if (!mounted) return;
        if (previous?.status == next.status && previous?.message == next.message) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleCancelDialogChange(next);
        });
      },
    );

    _qrScanSubscription = ref.listenManual<QrScanUiState>(
      qrScanUiStateProvider,
      (previous, next) {
        if (!mounted) return;
        if (widget.args.channelGroup != PaymentChannels.qr) return;
        if (previous == next) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleQrDialogChange(next);
        });
      },
    );

    if (widget.args.channelGroup == PaymentChannels.qr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final current = ref.read(qrScanUiStateProvider);
        _handleQrDialogChange(current);
      });
    }
  }

  @override
  void dispose() {
    _cancelSubscription?.close();
    _effectSubscription?.cancel();
    _cancelDialogNotifier?.dispose();
    _qrScanSubscription?.close();
    _qrDialogNotifier?.dispose();
    super.dispose();
  }

  void _handleCancelDialogChange(CancelDialogState dialogState) {
    if (!mounted) return;
    if (dialogState.status == CancelDialogStatus.hidden) {
      if (_isCancelDialogVisible) {
        _isCancelDialogVisible = false;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      return;
    }

    if (_isCancelDialogVisible) {
      _cancelDialogNotifier?.value = dialogState;
      return;
    }

    _cancelDialogNotifier = ValueNotifier<CancelDialogState>(dialogState);
    final notifier = _cancelDialogNotifier!;
    _isCancelDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<CancelDialogState>(
          valueListenable: notifier,
          builder: (context, state, _) {
            return CancelDialog(
              state: state,
              onClose: () {
                final navigator = Navigator.of(context, rootNavigator: true);
                if (navigator.canPop()) {
                  navigator.pop();
                }
                if (!mounted) return;
                // Use the page context to navigate; the dialog context may be unmounted.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  this.context.go('/entry');
                });
              },
              onRetryCancel: () => ref.read(provider.notifier).retryCancelAfterFailure(),
              onForceExit: () => ref.read(provider.notifier).forceExitAfterCancelFailure(),
            );
          },
        );
      },
    ).whenComplete(() {
      _isCancelDialogVisible = false;
      if (identical(_cancelDialogNotifier, notifier)) {
        _cancelDialogNotifier?.dispose();
        _cancelDialogNotifier = null;
      }
      if (mounted) {
        ref.read(provider.notifier).dismissCancelDialog();
      }
    });
  }

  void _handleQrDialogChange(QrScanUiState dialogState) {
    if (!mounted) return;
    if (widget.args.channelGroup != PaymentChannels.qr) return;
    if (dialogState.status == QrScanDialogStatus.hidden) {
      if (_isQrDialogVisible) {
        _isQrDialogVisible = false;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      return;
    }

    if (_isQrDialogVisible) {
      _qrDialogNotifier?.value = dialogState;
      return;
    }

    _qrDialogNotifier = ValueNotifier<QrScanUiState>(dialogState);
    _isQrDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<QrScanUiState>(
          valueListenable: _qrDialogNotifier!,
          builder: (context, state, _) {
            return QrScanDialog(
              state: state,
              onSubmitted: (value) => ref.read(dialogDrivenQrScannerProvider).submitCode(value),
              onCancel: () => ref.read(dialogDrivenQrScannerProvider).cancelScan(),
            );
          },
        );
      },
    ).whenComplete(() {
      _isQrDialogVisible = false;
      _qrDialogNotifier?.dispose();
      _qrDialogNotifier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    final args = widget.args;
    final amountInfo = args.channelGroup == PaymentChannels.cash
      ? _extractCashAmount(state)
      : null;

    return PopScope(
      canPop: state.canExit,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_titleForGroup(args)),
          actions: [
            if (state.canExit)
              TextButton(
                onPressed: () => context.go('/pos'),
                child: Text(
                  AppLocalizations.of(context).paymentActionReturnPos,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderSummary(args: args),
              const SizedBox(height: 16),
              if (amountInfo != null) ...[
                CashAmountCard(state: state, expectedTotal: args.order.total),
                const SizedBox(height: 16),
              ],
              StatusHero(
                state: state,
                args: args,
                onRetry: () => ref.read(provider.notifier).retryPayment(),
                onOpenSettings: () => context.go('/settings'),
                onNetworkHelp: () {
                  ref.read(dialogControllerProvider.notifier).show<void>(
                        const DialogRequest<void>(
                          title: '网络异常',
                          message: '请检查网线或Wi-Fi连接，确认路由器与终端在同一网络后重试。',
                          actions: [
                            DialogAction(label: '知道了', value: null, isPrimary: true),
                          ],
                        ),
                      );
                },
              ),
              const SizedBox(height: 24),
              Expanded(child: StatusTimeline(state: state)),
            ],
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          state: state,
          args: args,
          cancel: () => ref.read(provider.notifier).cancelPayment(),
          confirm: () => ref.read(provider.notifier).confirmManualPayment(),
        ),
      ),
    );
  }

  String _titleForGroup(PaymentFlowPageArgs args) {
    final name = args.channelDisplayName;
    switch (args.channelGroup) {
      case PaymentChannels.card:
        return '信用卡支付${name != null ? ' - $name' : ''}';
      case PaymentChannels.cash:
        return '现金支付';
      case PaymentChannels.qr:
        return '扫码支付${name != null ? ' - $name' : ''}';
      default:
        return '支付流程';
    }
  }

  Future<void> _startPrintFlow() async {
    if (_printing) return;
    _printing = true;
    final machineCode = widget.args.metadata?['machineCode'] as String? ??
        ref.read(machineCodeProvider) ?? '';
    final printers = ref.read(appSettingsSnapshotProvider)?.printers ?? const <PrinterSettings>[];

    String printType = '';
    final labelPrinter = printers.firstWhere(
      (printer) => printer.type == 10 && !printer.receipt,
      orElse: () => PrinterSettings(name: '', printIp: '', receipt: false, labelSize: '', type: 0, isOn: false),
    );

    if (labelPrinter.isOn) {
      printType = 'Label';
    }
    
    final request = PrintJobRequest(
      machineCode: machineCode,
      printers: printers,
      orderId: widget.args.order.orderId,
      payAmount: widget.args.order.total.toString(),
      printType: printType,
    );

    try {
      await showPrintStatusDialog(
        context: context,
        ref: ref,
        request: request,
        onCompleted: () => context.go('/entry'),
      );
    } finally {
      _printing = false;
    }
  }

  CashAmountSnapshot? _extractCashAmount(PaymentFlowState state) {
    final receiptAmount = state.pendingReceipt?['acceptedAmount'];
    if (receiptAmount is num) {
      return CashAmountSnapshot(amount: receiptAmount, isFinal: false);
    }
    //for (final status in state.timeline.reversed) {
      final details = state.currentStatus?.details ?? {};
      //if (details == null) continue;
      if (details['stage'] == 'amount') {
        final amount = details['amount'];
        if (amount is num) {
          final isFinal = details['isFinal'] == true;
          return CashAmountSnapshot(amount: amount, isFinal: isFinal);
        }
      }
    //}
    return null;
  }
}
