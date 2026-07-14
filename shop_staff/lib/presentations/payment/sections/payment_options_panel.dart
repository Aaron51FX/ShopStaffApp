part of '../pages/payment_selection_page.dart';

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({
    required this.options,
    required this.args,
    required this.basic,
    required this.formatter,
    required this.submittedOrder,
    required this.submittedTotal,
    required this.busy,
    required this.selectedOption,
    required this.onSelect,
    required this.onSubmit,
  });

  final List<PaymentSelectionOption> options;
  final PaymentSelectionPageArgs args;
  final BasicSettings basic;
  final NumberFormat formatter;
  final OrderSubmissionResult? submittedOrder;
  final double? submittedTotal;
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
                          amount:
                              submittedTotal ??
                              submittedOrder?.total.toDouble() ??
                              args.total,
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
            amount:
                submittedTotal ??
                submittedOrder?.total.toDouble() ??
                args.total,
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
                  _localizedPaymentOptionLabel(t, option),
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
                  selectedOption == null
                      ? t.optionGroupNotSelected
                      : _localizedPaymentOptionLabel(t, selectedOption!),
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
