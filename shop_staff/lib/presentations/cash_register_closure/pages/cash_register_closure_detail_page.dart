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
import 'package:shop_staff/l10n/app_localizations.dart';
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
        setState(() => _error = _readableError(context, error));
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
          title: Text(
            AppLocalizations.of(context).cashRegisterClosureConfirmTitle,
          ),
          content: Text(
            AppLocalizations.of(context).cashRegisterClosureConfirmMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context).dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context).dialogConfirm),
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
            title: Text(
              AppLocalizations.of(
                context,
              ).cashRegisterClosureConfirmSuccessTitle,
            ),
            content: Text(
              AppLocalizations.of(context).cashRegisterClosurePrintPrompt,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  AppLocalizations.of(context).cashRegisterClosurePrintSkip,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  AppLocalizations.of(context).cashRegisterClosurePrintAction,
                ),
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
        setState(() => _error = _readableError(context, error));
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
      _showSnack(
        AppLocalizations.of(context).cashRegisterClosureNoActivePrinter,
      );
      return;
    }
    await showPrintStatusDialog(
      context: context,
      ref: ref,
      request: PrintJobRequest(
        machineCode: widget.machineCode,
        printers: printers,
        document: _buildPrintDocument(
          summary,
          widget.shopName,
          AppLocalizations.of(context),
        ),
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
        title: Text(
          waitingForCode
              ? AppLocalizations.of(context).cashRegisterClosureVerifyCodeTitle
              : AppLocalizations.of(context).cashRegisterClosureDetailTitle,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.stone500,
        actions: [
          if (summary != null)
            IconButton(
              tooltip: AppLocalizations.of(
                context,
              ).cashRegisterClosurePrintAction,
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
              label: Text(
                AppLocalizations.of(context).cashRegisterClosureConfirmAction,
              ),
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
  AppLocalizations t,
) {
  final lines = [
    PrintOrderLine(
      name: t.cashRegisterClosureSalesTotal,
      price: summary.total,
      qty: 1,
    ),
    PrintOrderLine(
      name: t.cashRegisterClosurePaymentCash,
      price: summary.cashTotal,
      qty: 1,
    ),
    PrintOrderLine(
      name: t.cashRegisterClosurePaymentCredit,
      price: summary.creditCardTotal,
      qty: 1,
    ),
    PrintOrderLine(name: 'PayPay', price: summary.payPayTotal, qty: 1),
    PrintOrderLine(name: 'Alipay', price: summary.aliPayTotal, qty: 1),
    PrintOrderLine(name: 'WeChat', price: summary.wechatTotal, qty: 1),
    PrintOrderLine(
      name: t.cashRegisterClosureRefundAmount,
      price: summary.repaymentTotal,
      qty: 1,
    ),
  ].where((line) => line.price != 0).toList(growable: false);

  return PrintInfoDocument(
    shopName: summary.shopName.isNotEmpty ? summary.shopName : fallbackShopName,
    shopCode: summary.shopCode,
    address: '',
    telNo: '',
    orderDate: summary.printTime.isNotEmpty
        ? summary.printTime
        : DateTime.now().toString(),
    order: t.cashRegisterClosureTitle,
    serialNumber: 'REGI',
    price: summary.total,
    payPrice: summary.total,
    payMethod: t.cashRegisterClosureTitle,
    language: t.localeName,
    details: [
      {
        'documentType': 'cash_register_closure',
        'summary': _cashRegisterClosurePrintSummaryJson(summary),
      },
    ],
    printInfo: PrintTicketInfo(
      orderTime: summary.printTime,
      fromPlate: 'Shop',
      orderSnCode: t.cashRegisterClosureTitle,
      orderType: 'Shop_In',
      payType: t.cashRegisterClosureTitle,
      orderLinesMap: {
        PrinterSettings.localType.toString(): lines.isEmpty
            ? [
                PrintOrderLine(
                  name: t.cashRegisterClosureSalesTotal,
                  price: 0,
                  qty: 1,
                ),
              ]
            : lines,
      },
    ),
  );
}

Map<String, dynamic> _cashRegisterClosurePrintSummaryJson(
  CashRegisterClosureSummary summary,
) {
  final json = summary.toJson();
  json.remove('cashInfo');
  json.remove('cashInfoGlory');
  return json;
}

String _readableError(BuildContext context, Object error) {
  if (error is NoLatestCashRegisterClosureDataException) {
    return AppLocalizations.of(context).cashRegisterClosureNoLatestBusinessData;
  }
  return error.toString();
}
