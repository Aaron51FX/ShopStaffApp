import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/application/cash_register_closure/cash_register_closure_usecases.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/datasources/local/cash_register_closure_local_data_source.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/presentations/printing/print_job_models.dart';
import 'package:shop_staff/presentations/printing/show_print_dialog.dart';

class CashRegisterClosurePage extends ConsumerStatefulWidget {
  const CashRegisterClosurePage({
    super.key,
    required this.machineCode,
    required this.shopName,
  });

  final String machineCode;
  final String shopName;

  @override
  ConsumerState<CashRegisterClosurePage> createState() =>
      _CashRegisterClosurePageState();
}

class _CashRegisterClosurePageState
    extends ConsumerState<CashRegisterClosurePage> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'ja_JP',
    symbol: '¥',
    decimalDigits: 0,
  );

  List<CashRegisterClosureHistoryRecord> _history = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final records = await ref
        .read(cashRegisterClosureUseCasesProvider)
        .loadHistory();
    if (!mounted) return;
    setState(() => _history = records);
  }

  Future<void> _startLatestFlow() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final mails = await ref
          .read(cashRegisterClosureUseCasesProvider)
          .fetchMailList(machineCode: widget.machineCode);
      if (!mounted) return;
      final selected = await _showMailDialog(mails);
      if (selected == null) return;
      await ref
          .read(cashRegisterClosureUseCasesProvider)
          .sendAdminVerify(
            machineCode: widget.machineCode,
            verifyEmail: selected.verifyEmail,
            verifyUserName: selected.verifyUserName,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CashRegisterClosureDetailPage.pending(
            machineCode: widget.machineCode,
            shopName: widget.shopName,
            mail: selected,
          ),
        ),
      );
      await _loadHistory();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<CashRegisterClosureMailAccount?> _showMailDialog(
    List<CashRegisterClosureMailAccount> mails,
  ) {
    return showDialog<CashRegisterClosureMailAccount>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('メールを選択'),
          content: SizedBox(
            width: 520,
            child: mails.isEmpty
                ? const Text('メールアドレスが登録されていません')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: mails.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final mail = mails[index];
                      return ListTile(
                        leading: const Icon(Icons.mail_outline_rounded),
                        title: Text(mail.verifyEmail),
                        subtitle: Text(mail.verifyUserName),
                        onTap: () => Navigator.of(dialogContext).pop(mail),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  void _showHistory(CashRegisterClosureHistoryRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CashRegisterClosureDetailPage(
          machineCode: widget.machineCode,
          shopName: widget.shopName,
          summary: record.summary,
          isHistory: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('レジ締め'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.stone500,
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _startLatestFlow,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('获取最新レジ締め'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
          children: [
            _Header(subtitle: widget.shopName),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),
            _HistoryList(
              records: _history,
              currency: _currency,
              onTap: _showHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class CashRegisterClosureDetailPage extends ConsumerStatefulWidget {
  const CashRegisterClosureDetailPage({
    super.key,
    required this.machineCode,
    required this.shopName,
    this.summary,
    this.input,
    this.mail,
    required this.isHistory,
  });

  const CashRegisterClosureDetailPage.pending({
    super.key,
    required this.machineCode,
    required this.shopName,
    required CashRegisterClosureMailAccount this.mail,
  }) : summary = null,
       input = null,
       isHistory = false;

  final String machineCode;
  final String shopName;
  final CashRegisterClosureSummary? summary;
  final CashRegisterClosureVerifyInput? input;
  final CashRegisterClosureMailAccount? mail;
  final bool isHistory;

  @override
  ConsumerState<CashRegisterClosureDetailPage> createState() =>
      _CashRegisterClosureDetailPageState();
}

class _CashRegisterClosureDetailPageState
    extends ConsumerState<CashRegisterClosureDetailPage> {
  final TextEditingController _codeController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'ja_JP',
    symbol: '¥',
    decimalDigits: 0,
  );

  CashRegisterClosureSummary? _summary;
  CashRegisterClosureVerifyInput? _input;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
    _input = widget.input;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    final mail = widget.mail;
    final code = _codeController.text.trim();
    if (mail == null || code.isEmpty || _loading) return;

    final input = CashRegisterClosureVerifyInput(
      machineCode: widget.machineCode,
      verifyCode: code,
      verifyEmail: mail.verifyEmail,
      verifyUserName: mail.verifyUserName,
    );

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await ref
          .read(cashRegisterClosureUseCasesProvider)
          .fetchStaffRejishime(input);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _input = input;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = _readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmClosure() async {
    final input = _input;
    final summary = _summary;
    if (input == null || summary == null || _loading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('销核確認'),
          content: const Text('現在のレジ締めを销核します。実行後は元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(cashRegisterClosureUseCasesProvider).confirm(input);
      await ref
          .read(cashRegisterClosureUseCasesProvider)
          .saveConfirmedHistory(summary);
      if (!mounted) return;
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('销核成功'),
            content: const Text('レジ締めを印刷しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('印刷しない'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('印刷'),
              ),
            ],
          );
        },
      );
      if (shouldPrint == true) {
        await _printSummary();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _printSummary() async {
    final summary = _summary;
    if (summary == null) return;
    final printers =
        ref.read(appSettingsSnapshotProvider)?.printers ??
        const <PrinterSettings>[];
    if (printers.where((printer) => printer.isOn).isEmpty) {
      _showSnack('有効なプリンターがありません');
      return;
    }
    await showPrintStatusDialog(
      context: context,
      ref: ref,
      request: PrintJobRequest(
        machineCode: widget.machineCode,
        printers: printers,
        document: _buildPrintDocument(summary, widget.shopName),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;
    final waitingForCode = summary == null && widget.mail != null;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(waitingForCode ? '確認コード' : 'レジ締め詳細'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.stone500,
        actions: [
          if (summary != null)
            IconButton(
              tooltip: '印刷',
              onPressed: _loading ? null : _printSummary,
              icon: const Icon(Icons.print_rounded),
            ),
        ],
      ),
      floatingActionButton:
          !widget.isHistory && _input != null && summary != null
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : _confirmClosure,
              icon: const Icon(Icons.verified_rounded),
              label: const Text('销核'),
            )
          : null,
      body: SafeArea(
        child: waitingForCode
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: _VerifyForm(
                    mail: widget.mail!,
                    controller: _codeController,
                    loading: _loading,
                    error: _error,
                    onSubmit: _fetchSummary,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 96),
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  if (summary != null)
                    _SummaryDetail(
                      summary: summary,
                      currency: _currency,
                      isHistory: widget.isHistory,
                    ),
                ],
              ),
      ),
    );
  }
}

PrintInfoDocument _buildPrintDocument(
  CashRegisterClosureSummary summary,
  String fallbackShopName,
) {
  final lines = [
    PrintOrderLine(name: '売上合計', price: summary.total, qty: 1),
    PrintOrderLine(name: '現金', price: summary.cashTotal, qty: 1),
    PrintOrderLine(name: 'クレジットカード', price: summary.creditCardTotal, qty: 1),
    PrintOrderLine(name: 'PayPay', price: summary.payPayTotal, qty: 1),
    PrintOrderLine(name: 'Alipay', price: summary.aliPayTotal, qty: 1),
    PrintOrderLine(name: 'WeChat', price: summary.wechatTotal, qty: 1),
    PrintOrderLine(name: '返金', price: summary.repaymentTotal, qty: 1),
  ].where((line) => line.price != 0).toList(growable: false);

  return PrintInfoDocument(
    shopName: summary.shopName.isNotEmpty ? summary.shopName : fallbackShopName,
    shopCode: summary.shopCode,
    address: '',
    telNo: '',
    orderDate: summary.printTime.isNotEmpty
        ? summary.printTime
        : DateTime.now().toString(),
    order: 'レジ締め',
    serialNumber: 'REGI',
    price: summary.total,
    payPrice: summary.total,
    payMethod: 'レジ締め',
    printInfo: PrintTicketInfo(
      orderTime: summary.printTime,
      fromPlate: 'Shop',
      orderSnCode: 'レジ締め',
      orderType: 'Shop_In',
      payType: 'レジ締め',
      orderLinesMap: {
        PrinterSettings.localType.toString(): lines.isEmpty
            ? [const PrintOrderLine(name: '売上合計', price: 0, qty: 1)]
            : lines,
      },
    ),
  );
}

String _readableError(Object error) {
  if (error is NoLatestCashRegisterClosureDataException) {
    return '没有最新的营业数据';
  }
  return error.toString();
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'レジ締め',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.stone500,
          ),
        ),
      ],
    );
  }
}

class _VerifyForm extends StatelessWidget {
  const _VerifyForm({
    required this.mail,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final CashRegisterClosureMailAccount mail;
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            '確認コード',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${mail.verifyEmail} に送信しました',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: '確認コード',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            child: const Text('获取'),
          ),
        ],
      ),
    );
  }
}

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail({
    required this.summary,
    required this.currency,
    required this.isHistory,
  });

  final CashRegisterClosureSummary summary;
  final NumberFormat currency;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClosureHeader(summary: summary),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final sales = _SalesOverview(summary: summary, currency: currency);
            final payments = _PaymentPiePanel(
              summary: summary,
              currency: currency,
            );
            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [sales, const SizedBox(height: 16), payments],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: sales),
                const SizedBox(width: 16),
                Expanded(flex: 10, child: payments),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ClosureHeader extends StatelessWidget {
  const _ClosureHeader({required this.summary});

  final CashRegisterClosureSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopName = summary.shopName.trim().isEmpty ? '-' : summary.shopName;
    final machineCode = summary.machineCode.trim().isEmpty
        ? '-'
        : summary.machineCode;
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.stone600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '機番 $machineCode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.stone500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TimePill(label: '開始', value: summary.startTime),
              const SizedBox(height: 8),
              _TimePill(label: '終了', value: summary.endTime),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.stone500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview({required this.summary, required this.currency});

  final CashRegisterClosureSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final grossBeforeAdjustment =
        summary.total + summary.discountTotal + summary.voucherAmountTotal;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '売上',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _BigAmount(
            label: '販売額',
            value: currency.format(summary.total),
            helper: '税込 / 税抜 / 税額を含む集計',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(label: '税抜', value: currency.format(summary.noTaxTotal)),
              _Metric(label: '税額', value: currency.format(summary.taxTotal)),
              _Metric(
                label: '税込前',
                value: currency.format(grossBeforeAdjustment),
              ),
              _Metric(
                label: '割引',
                value: currency.format(summary.discountTotal),
              ),
              _Metric(
                label: '代金券',
                value: currency.format(summary.voucherAmountTotal),
              ),
              _Metric(label: '販売数量', value: '${summary.qty} 点'),
              _Metric(
                label: '返金額',
                value: currency.format(summary.repaymentTotal),
              ),
              _Metric(label: '返金数量', value: '${summary.repaymentQty} 点'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigAmount extends StatelessWidget {
  const _BigAmount({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amberPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.stone500,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.stone600,
            ),
          ),
          const SizedBox(height: 6),
          Text(helper, style: const TextStyle(color: AppColors.stone500)),
        ],
      ),
    );
  }
}

class _PaymentPiePanel extends StatelessWidget {
  const _PaymentPiePanel({required this.summary, required this.currency});

  final CashRegisterClosureSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entries = _paymentEntries(summary);
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.amount);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '決済構成',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty || total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: Text('決済データがありません')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final pie = _PaymentPie(
                  entries: entries,
                  total: total,
                  currency: currency,
                );
                final legend = Column(
                  children: [
                    for (final entry in entries)
                      _PaymentLegendRow(
                        entry: entry,
                        total: total,
                        currency: currency,
                      ),
                  ],
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    children: [
                      Center(child: pie),
                      const SizedBox(height: 18),
                      legend,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    pie,
                    const SizedBox(width: 20),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PaymentPie extends StatelessWidget {
  const _PaymentPie({
    required this.entries,
    required this.total,
    required this.currency,
  });

  final List<_PaymentEntry> entries;
  final int total;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _PaymentPiePainter(entries: entries),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('合計', style: TextStyle(color: AppColors.stone500)),
              const SizedBox(height: 4),
              Text(
                currency.format(total),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentLegendRow extends StatelessWidget {
  const _PaymentLegendRow({
    required this.entry,
    required this.total,
    required this.currency,
  });

  final _PaymentEntry entry;
  final int total;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : entry.amount / total * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: entry.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency.format(entry.amount)),
              Text(
                '${ratio.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.stone500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentPiePainter extends CustomPainter {
  const _PaymentPiePainter({required this.entries});

  final List<_PaymentEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.amount);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = math.min(size.width, size.height) * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;
    for (final entry in entries) {
      final sweep = entry.amount / total * math.pi * 2;
      paint.color = entry.color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PaymentPiePainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

List<_PaymentEntry> _paymentEntries(CashRegisterClosureSummary summary) {
  final otherQr =
      summary.auPayTotal +
      summary.dPayTotal +
      summary.mPayTotal +
      summary.rPayTotal;
  final entries = [
    _PaymentEntry('現金', summary.cashTotal, AppColors.emerald600),
    _PaymentEntry('クレジット', summary.creditCardTotal, const Color(0xFF2563EB)),
    _PaymentEntry('PayPay', summary.payPayTotal, const Color(0xFFDC2626)),
    _PaymentEntry('Alipay', summary.aliPayTotal, const Color(0xFF0891B2)),
    _PaymentEntry('WeChat', summary.wechatTotal, const Color(0xFF16A34A)),
    _PaymentEntry('交通系', summary.trafficTotal, const Color(0xFF7C3AED)),
    _PaymentEntry('その他QR', otherQr, const Color(0xFFF97316)),
  ].where((entry) => entry.amount > 0).toList(growable: false);
  return entries..sort((a, b) => b.amount.compareTo(a.amount));
}

class _PaymentEntry {
  const _PaymentEntry(this.label, this.amount, this.color);

  final String label;
  final int amount;
  final Color color;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.stone500)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.records,
    required this.currency,
    required this.onTap,
  });

  final List<CashRegisterClosureHistoryRecord> records;
  final NumberFormat currency;
  final ValueChanged<CashRegisterClosureHistoryRecord> onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '履歴',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('最近一ヶ月の履歴はありません'),
            )
          else
            for (final record in records)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(
                  record.summary.printTime.isNotEmpty
                      ? record.summary.printTime
                      : record.savedAt.toString(),
                ),
                subtitle: Text(record.summary.shopName),
                trailing: Text(currency.format(record.summary.total)),
                onTap: () => onTap(record),
              ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}
