import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

import '../viewmodels/payment_flow_viewmodel.dart';

class PaymentFlowPage extends ConsumerStatefulWidget {
  const PaymentFlowPage({super.key, required this.args});

  final PaymentFlowPageArgs args;

  @override
  ConsumerState<PaymentFlowPage> createState() => _PaymentFlowPageState();
}

class _PaymentFlowPageState extends ConsumerState<PaymentFlowPage> {
  late final provider = paymentFlowViewModelProvider(widget.args);
  ProviderSubscription<PaymentFlowState>? _stateSubscription;
  ProviderSubscription<CancelDialogState>? _cancelSubscription;
  ValueNotifier<CancelDialogState>? _cancelDialogNotifier;
  bool _isCancelDialogVisible = false;
  ProviderSubscription<QrScanUiState>? _qrScanSubscription;
  ValueNotifier<QrScanUiState>? _qrDialogNotifier;
  bool _isQrDialogVisible = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = ref.listenManual<PaymentFlowState>(provider, (previous, next) {
      if (previous?.result != next.result && next.result != null) {
        final result = next.result!;
        switch (result.status) {
          case PaymentStatusType.success:
            SimpleToast.successGlobal(result.message ?? '支付成功');
            _startPrintFlow();
            break;
          case PaymentStatusType.cancelled:
            //SimpleToast.successGlobal(result.message ?? '支付已取消');
            break;
          case PaymentStatusType.failure:
          default:
            SimpleToast.errorGlobal(result.message ?? '支付失败');
            break;
        }
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
    _stateSubscription?.close();
    _cancelSubscription?.close();
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
    _isCancelDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<CancelDialogState>(
          valueListenable: _cancelDialogNotifier!,
          builder: (context, state, _) {
            return CancelDialog(
              state: state,
              onClose: () {
                ref.read(provider.notifier).goEntryPage();
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _isCancelDialogVisible = false;
      _cancelDialogNotifier?.dispose();
      _cancelDialogNotifier = null;
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
                child: const Text('返回 POS', style: TextStyle(color: Colors.white)),
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