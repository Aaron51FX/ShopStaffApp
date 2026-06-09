import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/application/cash_register_closure/cash_register_closure_usecases.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/presentations/printing/print_job_models.dart';
import 'package:shop_staff/presentations/printing/show_print_dialog.dart';
import 'package:shop_staff/presentations/cash_register_closure/widgets/cash_register_closure_common_widgets.dart';

part '../widgets/cash_register_closure_verify_form.dart';
part '../widgets/cash_register_closure_summary_detail.dart';
part '../widgets/cash_register_closure_payment_pie.dart';

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
                    CashRegisterClosureErrorBanner(message: _error!),
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
