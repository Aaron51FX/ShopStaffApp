import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_staff/application/cash_register_closure/cash_register_closure_usecases.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/datasources/local/cash_register_closure_local_data_source.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/cash_register_closure/widgets/cash_register_closure_common_widgets.dart';
import 'cash_register_closure_route_args.dart';

part '../widgets/cash_register_closure_history_list.dart';

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
      await ref
          .read(appRouterProvider)
          .push(
            '/cash-register-closure/detail',
            extra: CashRegisterClosureDetailPageArgs.pending(
              machineCode: widget.machineCode,
              shopName: widget.shopName,
              mail: selected,
            ),
          );
      await _loadHistory();
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

  Future<CashRegisterClosureMailAccount?> _showMailDialog(
    List<CashRegisterClosureMailAccount> mails,
  ) {
    return showDialog<CashRegisterClosureMailAccount>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context).cashRegisterClosureMailDialogTitle,
          ),
          content: SizedBox(
            width: 520,
            child: mails.isEmpty
                ? Text(
                    AppLocalizations.of(context).cashRegisterClosureMailEmpty,
                  )
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
              child: Text(AppLocalizations.of(context).dialogCancel),
            ),
          ],
        );
      },
    );
  }

  void _showHistory(CashRegisterClosureHistoryRecord record) {
    ref
        .read(appRouterProvider)
        .push(
          '/cash-register-closure/detail',
          extra: CashRegisterClosureDetailPageArgs(
            machineCode: widget.machineCode,
            shopName: widget.shopName,
            summary: record.summary,
            isHistory: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).cashRegisterClosureTitle),
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
            label: Text(
              AppLocalizations.of(context).cashRegisterClosureLatestAction,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
          children: [
            CashRegisterClosureHeader(subtitle: widget.shopName),
            if (_error != null) ...[
              const SizedBox(height: 16),
              CashRegisterClosureErrorBanner(message: _error!),
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

String _readableError(BuildContext context, Object error) {
  if (error is NoLatestCashRegisterClosureDataException) {
    return AppLocalizations.of(context).cashRegisterClosureNoLatestBusinessData;
  }
  return error.toString();
}
