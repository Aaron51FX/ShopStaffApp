import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../application/checkout/checkout_providers.dart';
import '../../../application/settlement/settlement_checkout_adapter.dart';
import '../../../core/ui/app_colors.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/settlement_order.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/code_scan_dialog.dart';
import '../providers/settlement_order_providers.dart';

class SettlementOrderPage extends ConsumerStatefulWidget {
  const SettlementOrderPage({super.key, this.hardwareInputEnabled = false});

  final bool hardwareInputEnabled;

  @override
  ConsumerState<SettlementOrderPage> createState() =>
      _SettlementOrderPageState();
}

class _SettlementOrderPageState extends ConsumerState<SettlementOrderPage> {
  bool _openingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showScanner());
  }

  Future<void> _showScanner() async {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CodeScanDialog(
        title: t.settlementScanDialogTitle,
        cameraHint: t.settlementScanCameraHint,
        cameraUnavailableHint: t.scanCameraUnavailableHint,
        inputHint: t.settlementScanInputHint,
        cancelLabel: t.dialogCancel,
        submitLabel: t.settlementScanSubmit,
        hardwareInputEnabled: widget.hardwareInputEnabled,
      ),
    );
    if (result == null || !mounted) return;
    await ref.read(settlementOrderControllerProvider.notifier).fetch(result);
  }

  Future<void> _openPayment(SettlementOrder order) async {
    if (_openingPayment) return;
    final t = AppLocalizations.of(context);
    final shop = ref.read(shopInfoProvider);
    final machineCode = ref.read(machineCodeProvider)?.trim() ?? '';
    if (shop == null || machineCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.settlementPaymentContextMissingError)),
      );
      return;
    }

    setState(() => _openingPayment = true);
    try {
      final confirmedTotal = await ref
          .read(settlementOrderRepositoryProvider)
          .confirmOrderTotal(order.orderId);
      if (!mounted) return;
      if (confirmedTotal != order.payableAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.settlementOrderAmountChangedError)),
        );
        return;
      }
      final checkout = buildSettlementCheckoutData(
        settlement: order,
        shop: shop,
        machineCode: machineCode,
        language: ref.read(shopLanguageProvider),
      );
      await ref
          .read(checkoutCoordinatorProvider.notifier)
          .beginExistingOrder(draft: checkout.draft, order: checkout.order);
      if (!mounted) return;
      context.push('/payment-selection', extra: checkout.draft);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.settlementPaymentPrepareError)));
    } finally {
      if (mounted) setState(() => _openingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(settlementOrderControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.stone100,
      appBar: AppBar(
        title: Text(t.settlementOrderPageTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: state.loading ? null : _showScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(t.settlementRescanAction),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch ((state.loading, state.order)) {
          (true, _) => const Center(child: CircularProgressIndicator()),
          (false, final order?) => _SettlementOrderDetails(
            order: order,
            openingPayment: _openingPayment,
            onPay: () => _openPayment(order),
          ),
          _ => _SettlementEmptyState(
            errorMessage: _errorMessage(t, state.errorCode),
            onScan: _showScanner,
          ),
        },
      ),
    );
  }

  String? _errorMessage(AppLocalizations t, String? code) {
    return switch (code) {
      'invalid_code' => t.settlementInvalidCodeError,
      'machine_code_missing' => t.settlementMachineCodeMissingError,
      'request_failed' => t.settlementOrderFetchError,
      _ => null,
    };
  }
}

class _SettlementEmptyState extends StatelessWidget {
  const _SettlementEmptyState({
    required this.errorMessage,
    required this.onScan,
  });

  final String? errorMessage;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  errorMessage == null
                      ? Icons.qr_code_scanner_rounded
                      : Icons.error_outline_rounded,
                  size: 72,
                  color: errorMessage == null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  errorMessage ?? t.settlementScanEmptyTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  t.settlementScanEmptySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(t.settlementScanAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettlementOrderDetails extends StatelessWidget {
  const _SettlementOrderDetails({
    required this.order,
    required this.openingPayment,
    required this.onPay,
  });

  final SettlementOrder order;
  final bool openingPayment;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (!wide) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _OrderSummaryPanel(
                order: order,
                fillHeight: false,
                openingPayment: openingPayment,
                onPay: onPay,
              ),
              const SizedBox(height: 20),
              _OrderLinesPanel(order: order, fillHeight: false),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: _OrderLinesPanel(order: order, fillHeight: true),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 340,
                child: _OrderSummaryPanel(
                  order: order,
                  fillHeight: true,
                  openingPayment: openingPayment,
                  onPay: onPay,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderLinesPanel extends StatelessWidget {
  const _OrderLinesPanel({required this.order, required this.fillHeight});

  final SettlementOrder order;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.settlementOrderDetailsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    order.tableNum.trim().isEmpty
                        ? ''
                        : '${order.tableNumText.trim()}${order.tableNum.trim()}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    t.settlementOrderQuantity(order.orderQty),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text(t.settlementOrderLinesEmpty)),
              )
            else if (fillHeight)
              Flexible(
                child: ListView.separated(
                  itemCount: order.lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) =>
                      _OrderLineTile(line: order.lines[index]),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.lines.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) =>
                    _OrderLineTile(line: order.lines[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({required this.line});

  final SettlementOrderLine line;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '¥',
      decimalDigits: 0,
    );
    final theme = Theme.of(context);
    final options = line.flattenedOptions.toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '×${line.qty}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line.categoryName != null)
                  Text(
                    line.categoryName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                Text(
                  line.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${option.key} · ${option.value.name}'
                            ' ×${option.value.qty}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '+${formatter.format(option.value.displayTotal)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(line.price),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (line.initialPrice != null && line.initialPrice! != line.price)
                Text(
                  formatter.format(line.initialPrice),
                  style: theme.textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryPanel extends StatelessWidget {
  const _OrderSummaryPanel({
    required this.order,
    required this.fillHeight,
    required this.openingPayment,
    required this.onPay,
  });

  final SettlementOrder order;
  final bool fillHeight;
  final bool openingPayment;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final formatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '¥',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.settlementAmountSummaryTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            _SummaryRow(label: t.paymentOrderIdLabel, value: order.orderId),
            const Divider(height: 28),
            _SummaryRow(
              label: t.posSubtotalLabel,
              value: formatter.format(order.totalPrice),
            ),
            _SummaryRow(
              label: t.paymentSelectionTax10Label,
              value: formatter.format(order.tax1),
            ),
            _SummaryRow(
              label: t.paymentSelectionTax8Label,
              value: formatter.format(order.tax2),
            ),
            if (order.discount != 0)
              _SummaryRow(
                label: t.paymentSelectionDiscountLabel,
                value: '-${formatter.format(order.discount)}',
              ),
            if (order.voucherAmount != 0)
              _SummaryRow(
                label: t.settlementVoucherLabel,
                value: '-${formatter.format(order.voucherAmount)}',
              ),
            if (fillHeight) const Spacer() else const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.paymentSelectionAmountDue,
                    style: const TextStyle(
                      color: AppColors.emerald700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(order.payableAmount),
                    style: const TextStyle(
                      color: AppColors.emerald700,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: openingPayment ? null : onPay,
              icon: openingPayment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(t.settlementPayAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
