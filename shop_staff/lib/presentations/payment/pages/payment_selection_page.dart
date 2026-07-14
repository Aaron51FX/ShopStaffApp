import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/application/checkout/checkout_providers.dart';
import 'package:shop_staff/application/payments/selection/prepare_payment_selection_usecase.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/peer_link/peer_link.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_selection_page_args.dart';
import 'package:shop_staff/presentations/payment/providers/payment_providers.dart';

part '../models/payment_summary_data.dart';
part '../sections/payment_options_panel.dart';
part '../sections/payment_summary_panel.dart';
part '../widgets/selection/payment_method_illustrations.dart';

String _localizedPaymentOptionLabel(
  AppLocalizations t,
  PaymentSelectionOption option,
) {
  return switch (option.group) {
    PaymentChannels.cash => t.paymentGroupCashTitle,
    PaymentChannels.qr => t.paymentGroupQrTitle,
    PaymentChannels.card => t.paymentGroupCardTitle,
    _ => option.code,
  };
}

class PaymentSelectionPage extends ConsumerStatefulWidget {
  const PaymentSelectionPage({super.key, required this.args});

  final PaymentSelectionPageArgs args;

  @override
  ConsumerState<PaymentSelectionPage> createState() =>
      _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends ConsumerState<PaymentSelectionPage> {
  ProviderSubscription<PeerLinkState>? _peerSub;
  late int _lastPeerMessageSeq;
  bool _submitting = false;
  PaymentSelectionOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    if (ref.read(checkoutCoordinatorProvider).draft == null) {
      ref.read(checkoutCoordinatorProvider.notifier).begin(widget.args);
    }
    _lastPeerMessageSeq = ref.read(peerLinkControllerProvider).messageSeq;
    _peerSub = ref.listenManual<PeerLinkState>(peerLinkControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next.messageSeq == _lastPeerMessageSeq) return;
      _lastPeerMessageSeq = next.messageSeq;
      final message = next.lastMessage;
      if (message == null || message.type != 'payment_choice') return;
      final option = _findOptionForPayload(message.payload);
      if (option == null || !option.enabled) return;
      _selectOption(option);
    });
  }

  @override
  void dispose() {
    _peerSub?.close();
    super.dispose();
  }

  List<PaymentSelectionOption> _options() {
    final useCase = ref.read(preparePaymentSelectionUseCaseProvider);
    return useCase.execute(shop: widget.args.shop).options;
  }

  PaymentSelectionOption? _findOptionForPayload(Map<String, dynamic> payload) {
    final group = (payload['group'] ?? '').toString();
    final code = (payload['code'] ?? '').toString();
    for (final option in _options()) {
      if (option.group != group) continue;
      if (code.isEmpty || option.code == code || code == group) {
        return option;
      }
    }
    return null;
  }

  Future<void> _pushToCustomer() async {
    final t = AppLocalizations.of(context);
    final snapshot = ref.read(appSettingsSnapshotProvider);
    final basic = snapshot?.basic ?? const BasicSettings();
    if (!(basic.peerLinkEnabled)) {
      SimpleToast.errorGlobal(t.posToastPeerSyncDisabled);
      return;
    }

    final controller = ref.read(peerLinkControllerProvider.notifier);
    final state = ref.read(peerLinkControllerProvider);
    if (!state.isConnected) {
      SimpleToast.errorGlobal(t.posToastPeerNotConnected);
      return;
    }

    final payload = PreparePaymentSelectionOutput(
      options: _options(),
    ).toPayload(orderNumber: widget.args.orderNumber, total: widget.args.total);
    await controller.sendMessage(
      PeerMessage(type: 'payment_selection', payload: payload),
    );
    if (!mounted) return;
    SimpleToast.successGlobal(t.posToastPushedToCustomer);
  }

  void _selectOption(PaymentSelectionOption option) {
    if (_submitting || !option.enabled) return;
    setState(() {
      _selectedOption = option;
    });
  }

  Future<void> _submitSelectedOption() async {
    final option = _selectedOption;
    if (option == null || _submitting) return;
    await _startPayment(option);
  }

  Future<void> _startPayment(PaymentSelectionOption option) async {
    if (_submitting) return;
    final t = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final args = await ref
          .read(checkoutCoordinatorProvider.notifier)
          .preparePayment(
            group: option.group,
            code: option.code,
            label: _localizedPaymentOptionLabel(t, option),
          );
      if (!mounted) return;
      if (ref.read(checkoutCoordinatorProvider).warning != null) {
        SimpleToast.errorGlobal(t.posToastLocalOrderSaveFailed);
      }
      context.pushReplacement('/payment', extra: args);
    } catch (error) {
      if (!mounted) return;
      SimpleToast.errorGlobal(_resolveSelectionError(t, error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _resolveSelectionError(AppLocalizations t, Object error) {
    final raw = error.toString();
    if (raw.contains('POS_IP_MISSING')) {
      return t.paymentErrorPosIpMissing;
    }
    if (raw.contains('POS_PORT_INVALID')) {
      return t.paymentErrorPosPortInvalid;
    }
    if (raw.contains('POS_CONFIG_MISSING')) {
      return t.paymentErrorPosConfigMissing;
    }
    return t.posToastOrderSubmitFailed;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final options = _options();
    final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final checkout = ref.watch(checkoutCoordinatorProvider);
    final submittedOrder = checkout.order;
    final submittedTotal = checkout.submittedTotal;
    final summary = _PaymentSummaryData.fromArgs(
      widget.args,
      order: submittedOrder,
    );
    final snapshot = ref.watch(appSettingsSnapshotProvider);
    final basic = snapshot?.basic ?? const BasicSettings();
    final peerEnabled = basic.peerLinkEnabled;
    final peerConnected = ref.watch(
      peerLinkControllerProvider.select((state) => state.isConnected),
    );

    return Scaffold(
      backgroundColor: AppColors.stone100,
      appBar: AppBar(
        title: Text(t.paymentSelectionTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (peerEnabled)
            IconButton(
              tooltip: t.paymentSelectionPushTooltip,
              onPressed: _submitting ? null : _pushToCustomer,
              icon: Icon(
                peerConnected ? Icons.send_rounded : Icons.link_off_rounded,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final content = wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _SummaryPanel(
                          args: widget.args,
                          summary: summary,
                          formatter: formatter,
                          submittedOrder: submittedOrder,
                          submittedTotal: submittedTotal,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _OptionsPanel(
                          options: options,
                          args: widget.args,
                          basic: basic,
                          formatter: formatter,
                          submittedOrder: submittedOrder,
                          submittedTotal: submittedTotal,
                          busy: _submitting,
                          selectedOption: _selectedOption,
                          onSelect: _selectOption,
                          onSubmit: _submitSelectedOption,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryPanel(
                        args: widget.args,
                        summary: summary,
                        formatter: formatter,
                        submittedOrder: submittedOrder,
                        submittedTotal: submittedTotal,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _OptionsPanel(
                          options: options,
                          args: widget.args,
                          basic: basic,
                          formatter: formatter,
                          submittedOrder: submittedOrder,
                          submittedTotal: submittedTotal,
                          busy: _submitting,
                          selectedOption: _selectedOption,
                          onSelect: _selectOption,
                          onSubmit: _submitSelectedOption,
                        ),
                      ),
                    ],
                  );

            return Padding(padding: const EdgeInsets.all(20), child: content);
          },
        ),
      ),
    );
  }
}
