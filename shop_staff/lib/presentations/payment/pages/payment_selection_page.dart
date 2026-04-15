import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:shop_staff/application/pos/usecases/build_payment_flow_args_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/prepare_payment_selection_usecase.dart';
import 'package:shop_staff/core/toast/simple_toast.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/entry/viewmodels/peer_link_controller.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_selection_page_args.dart';

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

    final payload = PreparePaymentSelectionOutput(options: _options())
        .toPayload(
          orderNumber: widget.args.orderNumber,
          total: widget.args.order.total.toDouble(),
        );
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
    final snapshot = ref.read(appSettingsSnapshotProvider);
    final basic = snapshot?.basic ?? const BasicSettings();
    final paymentMode = basic.paymentModes.resolveForGroup(
      option.group,
      cashMachine: basic.cashMachine,
    );

    setState(() => _submitting = true);
    try {
      final localOrders = ref.read(localOrdersUseCasesProvider);
      await localOrders.updatePaymentMode(
        widget.args.order.orderId,
        paymentMode,
      );
      await localOrders.updatePayMethod(
        widget.args.order.orderId,
        option.label,
      );

      final args = ref
          .read(buildPaymentFlowArgsUseCaseProvider)
          .execute(
            order: widget.args.order,
            shop: widget.args.shop,
            machineCode: widget.args.machineCode,
            group: option.group,
            code: option.code,
            paymentMode: paymentMode,
            label: option.label,
            items: widget.args.items,
            language: widget.args.language,
            takeout: widget.args.takeout,
            basic: basic,
            posInfo: snapshot?.posTerminal,
          );
      if (!mounted) return;
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
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final options = _options();
    final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final summary = _PaymentSummaryData.fromArgs(widget.args);
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
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _OptionsPanel(
                          options: options,
                          args: widget.args,
                          basic: basic,
                          formatter: formatter,
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
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _OptionsPanel(
                          options: options,
                          args: widget.args,
                          basic: basic,
                          formatter: formatter,
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.args,
    required this.summary,
    required this.formatter,
  });

  final PaymentSelectionPageArgs args;
  final _PaymentSummaryData summary;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stone200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.paymentSelectionSummaryTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(args.order.total),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.stone600,
            ),
          ),
          Text(
            t.paymentSelectionAmountDue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 20),
          _SummaryRow(label: t.paymentOrderIdLabel, value: args.order.orderId),
          _SummaryRow(
            label: t.paymentSelectionOrderNumberLabel,
            value: '#${args.orderNumber}',
          ),
          _SummaryRow(
            label: t.posSubtotalLabel,
            value: formatter.format(summary.subtotal),
          ),
          if (summary.discount > 0)
            _SummaryRow(
              label: t.paymentSelectionDiscountLabel,
              value: '-${formatter.format(summary.discount)}',
            ),
          if (summary.tax10 > 0)
            _SummaryRow(
              label: t.paymentSelectionTax10Label,
              value: formatter.format(summary.tax10),
            ),
          if (summary.tax8 > 0)
            _SummaryRow(
              label: t.paymentSelectionTax8Label,
              value: formatter.format(summary.tax8),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  t.paymentSelectionAmountDue,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stone600,
                  ),
                ),
                const Spacer(),
                Text(
                  formatter.format(args.order.total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({
    required this.options,
    required this.args,
    required this.basic,
    required this.formatter,
    required this.busy,
    required this.selectedOption,
    required this.onSelect,
    required this.onSubmit,
  });

  final List<PaymentSelectionOption> options;
  final PaymentSelectionPageArgs args;
  final BasicSettings basic;
  final NumberFormat formatter;
  final bool busy;
  final PaymentSelectionOption? selectedOption;
  final ValueChanged<PaymentSelectionOption> onSelect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stone200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.paymentSelectionHint,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 920
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                final spacing = 16.0;
                final totalSpacing = spacing * (columns - 1);
                final rawWidth =
                    (constraints.maxWidth - totalSpacing) / columns;
                final itemWidth = rawWidth.clamp(220.0, 340.0);

                return SingleChildScrollView(
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: options.map((option) {
                      return SizedBox(
                        width: itemWidth,
                        height: 178,
                        child: _PaymentMethodCard(
                          option: option,
                          mode: basic.paymentModes.resolveForGroup(
                            option.group,
                            cashMachine: basic.cashMachine,
                          ),
                          amount: args.order.total.toDouble(),
                          formatter: formatter,
                          busy: busy,
                          selected: selectedOption?.group == option.group,
                          onTap: option.enabled ? () => onSelect(option) : null,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _SelectionActionBar(
            selectedOption: selectedOption,
            selectedMode: selectedOption == null
                ? null
                : basic.paymentModes.resolveForGroup(
                    selectedOption!.group,
                    cashMachine: basic.cashMachine,
                  ),
            amount: args.order.total.toDouble(),
            busy: busy,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.option,
    required this.mode,
    required this.amount,
    required this.formatter,
    required this.busy,
    required this.selected,
    required this.onTap,
  });

  final PaymentSelectionOption option;
  final PaymentFlowMode mode;
  final double amount;
  final NumberFormat formatter;
  final bool busy;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final enabled = option.enabled && onTap != null;
    final modeLabel = mode == PaymentFlowMode.bookkeeping
        ? t.settingsPaymentModeBookkeeping
        : t.settingsPaymentModeReal;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: _gradientForGroup(option.group),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.22),
                width: selected ? 2.4 : 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.4,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: _accentForGroup(option.group),
                            )
                          : null,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        modeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.stone600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: switch (option.group) {
                      PaymentChannels.cash => const _CashIllustration(),
                      PaymentChannels.qr => const _QrIllustration(),
                      _ => const _CardIllustration(),
                    },
                  ),
                ),
                Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enabled
                      ? formatter.format(amount)
                      : t.paymentSelectionNotConfigured,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _gradientForGroup(String group) {
    switch (group) {
      case PaymentChannels.cash:
        return const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PaymentChannels.qr:
        return const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case PaymentChannels.card:
      default:
        return const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _accentForGroup(String group) {
    switch (group) {
      case PaymentChannels.cash:
        return const Color(0xFF0F766E);
      case PaymentChannels.qr:
        return const Color(0xFF111827);
      case PaymentChannels.card:
      default:
        return const Color(0xFF1D4ED8);
    }
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.selectedOption,
    required this.selectedMode,
    required this.amount,
    required this.busy,
    required this.onSubmit,
  });

  final PaymentSelectionOption? selectedOption;
  final PaymentFlowMode? selectedMode;
  final double amount;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final modeLabel = selectedMode == PaymentFlowMode.bookkeeping
        ? t.settingsPaymentModeBookkeeping
        : selectedMode == PaymentFlowMode.real
        ? t.settingsPaymentModeReal
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.paymentChannelLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stone500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedOption?.label ?? t.optionGroupNotSelected,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.stone600,
                  ),
                ),
                if (modeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    modeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stone500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: busy || selectedOption == null ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amberPrimary,
              disabledBackgroundColor: AppColors.stone300,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              busy
                  ? t.paymentActionConfirming
                  : t.paymentActionConfirmAmount(amount.round()),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.stone500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.stone600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashIllustration extends StatelessWidget {
  const _CashIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 112,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        Positioned(
          left: 16,
          top: 13,
          child: Container(
            width: 80,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.payments_rounded,
                size: 28,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrIllustration extends StatelessWidget {
  const _QrIllustration();

  @override
  Widget build(BuildContext context) {
    Widget qrCell({bool filled = true}) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white, width: 1.0),
        ),
      );
    }

    return Container(
      width: 92,
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              qrCell(),
              qrCell(filled: false),
              qrCell(),
              qrCell(),
              qrCell(filled: false),
              qrCell(),
              qrCell(filled: false),
              qrCell(),
              qrCell(),
            ],
          ),
          const Spacer(),
          Column(
            children: List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: index.isEven ? 0.92 : 0.52,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardIllustration extends StatelessWidget {
  const _CardIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 118,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        Positioned(
          left: 18,
          child: Container(
            width: 86,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 22,
                  color: Color(0xFF1D4ED8),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.contactless_rounded,
                  size: 20,
                  color: Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentSummaryData {
  const _PaymentSummaryData({
    required this.subtotal,
    required this.discount,
    required this.tax10,
    required this.tax8,
  });

  final double subtotal;
  final double discount;
  final double tax10;
  final double tax8;

  factory _PaymentSummaryData.fromArgs(PaymentSelectionPageArgs args) {
    return _PaymentSummaryData(
      subtotal: args.subtotal,
      discount: args.discount,
      tax10: args.order.tax1.toDouble(),
      tax8: args.order.tax2.toDouble(),
    );
  }
}
