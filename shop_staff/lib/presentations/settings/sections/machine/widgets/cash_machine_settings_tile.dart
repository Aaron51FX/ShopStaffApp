part of '../../../pages/settings_page.dart';

enum _CashMachineBrandOption { glory, star, conlux }

const Map<String, String> _labelPrintSize = {
  '60x30': '450x225',
  '50x30': '375x225',
  '40x30': '300x225',
  '60x40': '450x300',
  '50x40': '375x300',
  '40x40': '300x300',
  '60x50': '450x375',
  '50x50': '375x375',
  '40x50': '300x375',
};

enum _LocalPrinterBrand { star }

class _CashMachineTile extends ConsumerStatefulWidget {
  const _CashMachineTile({required this.basic, required this.checkState});

  final BasicSettings basic;
  final CashMachineCheckState checkState;

  @override
  ConsumerState<_CashMachineTile> createState() => _CashMachineTileState();
}

class _CashMachineTileState extends ConsumerState<_CashMachineTile> {
  bool _busy = false;
  bool _progressVisible = false;

  CashMachineSettings get _cashMachine => widget.basic.cashMachine;

  bool get _isConfigured =>
      _cashMachine.brand != null && _cashMachine.isConfigured;

  Future<void> _setEnabled(bool value) async {
    if (!_isConfigured) {
      return;
    }

    await _saveCashMachine(_cashMachine.copyWith(enabled: value));
  }

  Future<void> _saveCashMachine(CashMachineSettings settings) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .saveBasicSettings(
          widget.basic.copyWith(
            cashMachineEnabled: settings.enabled,
            cashMachine: settings,
          ),
        );
  }

  Future<void> _startAddFlow() async {
    if (_busy) {
      return;
    }

    final t = AppLocalizations.of(context);
    final brand = await _pickBrand();
    if (!mounted || brand == null) {
      return;
    }

    switch (brand) {
      case _CashMachineBrandOption.glory:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
          await _saveCashMachine(
            const CashMachineSettings(
              enabled: true,
              brand: CashMachineBrand.glory,
            ),
          );
          return;
        }
        await _showMessageDialog(
          title: t.settingsCashMachineBrandDialogTitle,
          message: t.settingsCashMachineBrandGloryHint,
        );
        return;
      case _CashMachineBrandOption.conlux:
        await _showMessageDialog(
          title: t.settingsCashMachineBrandDialogTitle,
          message: t.settingsCashMachineBrandConluxHint,
        );
        return;
      case _CashMachineBrandOption.star:
        await _configureStarDrawer();
        return;
    }
  }

  Future<void> _configureStarDrawer() async {
    final t = AppLocalizations.of(context);
    final discovery = ref.read(starXpandPrinterDiscoveryProvider);
    if (!discovery.isSupportedPlatform) {
      await _showMessageDialog(
        title: t.settingsCashMachineBrandDialogTitle,
        message: t.settingsLocalPrinterUnsupportedPlatform,
      );
      return;
    }

    final permissionMessage = await _ensureDiscoveryPermissions(t);
    if (!mounted) {
      return;
    }
    if (permissionMessage != null) {
      await _showMessageDialog(
        title: t.settingsCashMachineBrandDialogTitle,
        message: permissionMessage,
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    _showProgressDialog(t.settingsCashMachineSearchProgress);

    try {
      final printers = await discovery.discoverLocalPrinters();
      if (!mounted) {
        return;
      }

      _dismissProgressDialog();

      if (printers.isEmpty) {
        await _showMessageDialog(
          title: t.settingsLocalPrinterResultsTitle,
          message: t.settingsLocalPrinterSearchEmpty,
        );
        return;
      }

      final selected = await _pickDiscoveredPrinter(printers);
      if (selected == null || !mounted) {
        return;
      }

      final candidate = _mapToStarCashMachine(selected);
      _showProgressDialog(t.settingsCashMachineValidatingProgress);
      final status = await ref
          .read(starXpandCashDrawerServiceProvider)
          .getStatus(settings: candidate);
      if (!mounted) {
        return;
      }

      _dismissProgressDialog();

      if (status.drawerOpenCloseSignal) {
        await _showMessageDialog(
          title: t.settingsCashMachineBrandDialogTitle,
          message: t.settingsCashMachineDrawerOpenError,
        );
        return;
      }

      if (status.hasError) {
        await _showMessageDialog(
          title: t.settingsCashMachineBrandDialogTitle,
          message: t.settingsCashMachineStatusError,
        );
        return;
      }

      await _saveCashMachine(candidate.copyWith(enabled: true));
    } catch (error) {
      if (mounted) {
        _dismissProgressDialog();
        await _showMessageDialog(
          title: t.settingsCashMachineBrandDialogTitle,
          message: error.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<_CashMachineBrandOption?> _pickBrand() {
    final t = AppLocalizations.of(context);
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final supportsStar = ref
        .read(starXpandPrinterDiscoveryProvider)
        .isSupportedPlatform;

    return showDialog<_CashMachineBrandOption>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.settingsCashMachineBrandDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Glory'),
                subtitle: Text(t.settingsCashMachineBrandGloryHint),
                enabled: isWindows,
                onTap: isWindows
                    ? () => Navigator.of(
                        dialogContext,
                      ).pop(_CashMachineBrandOption.glory)
                    : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.point_of_sale_rounded),
                title: const Text('Star'),
                subtitle: Text(
                  supportsStar
                      ? t.settingsCashMachineBrandStarHint
                      : t.settingsLocalPrinterUnsupportedPlatform,
                ),
                enabled: supportsStar,
                onTap: supportsStar
                    ? () => Navigator.of(
                        dialogContext,
                      ).pop(_CashMachineBrandOption.star)
                    : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Conlux'),
                subtitle: Text(t.settingsCashMachineBrandConluxHint),
                enabled: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.dialogCancel),
            ),
          ],
        );
      },
    );
  }

  Future<StarXpandDiscoveredPrinter?> _pickDiscoveredPrinter(
    List<StarXpandDiscoveredPrinter> printers,
  ) {
    final t = AppLocalizations.of(context);
    StarXpandDiscoveredPrinter? selected = printers.first;

    return showDialog<StarXpandDiscoveredPrinter>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(t.settingsLocalPrinterResultsTitle),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final printer in printers)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            selected == printer
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          onTap: () {
                            setState(() {
                              selected = printer;
                            });
                          },
                          title: Text(
                            printer.displayName ??
                                printer.modelName ??
                                printer.identifier,
                          ),
                          subtitle: Text(
                            [
                              _connectionTypeLabel(
                                t,
                                _connectionTypeFromTransport(printer.transport),
                              ),
                              if ((printer.connectionInfo ?? '')
                                  .trim()
                                  .isNotEmpty)
                                printer.connectionInfo!.trim(),
                              printer.identifier,
                            ].join(' · '),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t.dialogCancel),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(selected),
                  child: Text(t.dialogConfirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProgressDialog(String message) {
    _progressVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _progressVisible = false;
    });
  }

  void _dismissProgressDialog() {
    if (!_progressVisible || !mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) {
    final t = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t.dialogConfirm),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _ensureDiscoveryPermissions(AppLocalizations t) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final statuses = await <Permission>[
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    final denied = statuses.values
        .where((status) => !status.isGranted)
        .toList();

    if (denied.isEmpty) {
      return null;
    }

    return t.settingsLocalPrinterPermissionDenied;
  }

  CashMachineSettings _mapToStarCashMachine(
    StarXpandDiscoveredPrinter printer,
  ) {
    return CashMachineSettings(
      enabled: true,
      brand: CashMachineBrand.star,
      connectionType: _connectionTypeFromTransport(printer.transport),
      deviceIdentifier: printer.identifier,
      host: printer.host,
      modelName: printer.modelName ?? printer.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashMachine = _cashMachine;
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final brandLabel = _displayValue(
      t,
      _cashMachineBrandLabel(cashMachine.brand),
    );
    final modelLabel = _displayValue(t, cashMachine.modelName);
    final identifierValue = _displayValue(
      t,
      (cashMachine.deviceIdentifier?.trim().isNotEmpty ?? false)
          ? cashMachine.deviceIdentifier
          : cashMachine.host,
    );

    final statusLabel = !widget.checkState.isSupported
        ? t.settingsCashNotSupported
        : !_isConfigured
        ? t.settingsValueNotSet
        : (cashMachine.enabled
              ? t.settingsCashEnabled
              : t.settingsCashDisabled);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _Tag(
                      icon: Icons.payments_rounded,
                      label: t.settingsCashPaymentTitle,
                    ),
                    if (_isConfigured)
                      _Tag(icon: Icons.sell_outlined, label: brandLabel),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isConfigured && cashMachine.enabled,
                onChanged: (!_isConfigured || _busy) ? null : _setEnabled,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
          _InfoRow(
            icon: Icons.payments_rounded,
            label: t.settingsCashStatusLabel,
            value: statusLabel,
          ),
          if (_isConfigured) ...[
            _InfoRow(
              icon: Icons.sell_outlined,
              label: t.settingsLocalPrinterBrandLabel,
              value: brandLabel,
            ),
            _InfoRow(
              icon: Icons.print_rounded,
              label: t.settingsLocalPrinterModelLabel,
              value: modelLabel,
            ),
            _InfoRow(
              icon: Icons.usb_rounded,
              label: t.settingsLocalPrinterTransportLabel,
              value: _cashMachineTransportLabel(t, cashMachine),
            ),
            _InfoRow(
              icon: Icons.pin_outlined,
              label: t.settingsLocalPrinterIdentifierLabel,
              value: identifierValue,
            ),
          ] else
            _EmptyPlaceholder(message: t.settingsValueNotSet),
          if (widget.checkState.lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              t.settingsCashLastCheckFailed(widget.checkState.lastError!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.redAccent,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _startAddFlow,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isConfigured ? Icons.sync_rounded : Icons.add_rounded,
                      ),
                label: Text(
                  _isConfigured
                      ? t.settingsCashMachineReplaceAction
                      : t.settingsCashMachineAddAction,
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    (!_isConfigured ||
                        !_cashMachine.enabled ||
                        widget.checkState.isChecking)
                    ? null
                    : () => ref
                          .read(cashMachineCheckControllerProvider.notifier)
                          .start(auto: false),
                icon: widget.checkState.isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_rounded),
                label: Text(
                  widget.checkState.isChecking
                      ? t.settingsCashChecking
                      : t.settingsCashCheckNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
