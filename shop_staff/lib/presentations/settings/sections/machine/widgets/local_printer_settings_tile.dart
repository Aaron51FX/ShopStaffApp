part of '../../../pages/settings_page.dart';

class _LocalPrinterTile extends ConsumerStatefulWidget {
  const _LocalPrinterTile({required this.printer});

  final PrinterSettings printer;

  @override
  ConsumerState<_LocalPrinterTile> createState() => _LocalPrinterTileState();
}

class _LocalPrinterTileState extends ConsumerState<_LocalPrinterTile> {
  bool _busy = false;

  bool get _isConfigured {
    final printer = widget.printer;
    return printer.usesNativeSdk &&
        ((printer.deviceIdentifier?.trim().isNotEmpty ?? false) ||
            (printer.printIp?.trim().isNotEmpty ?? false));
  }

  Future<void> _setPrinterEnabled(bool value) async {
    if (!_isConfigured) {
      return;
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .savePrinter(widget.printer.copyWith(isOn: value));
  }

  Future<void> _startAddFlow() async {
    if (_busy) {
      return;
    }

    final t = AppLocalizations.of(context);
    final brand = await _pickBrand();
    if (!mounted || brand != _LocalPrinterBrand.star) {
      return;
    }

    final discovery = ref.read(starXpandPrinterDiscoveryProvider);
    if (!discovery.isSupportedPlatform) {
      await _showMessageDialog(
        title: t.settingsLocalPrinterBrandDialogTitle,
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
        title: t.settingsLocalPrinterBrandDialogTitle,
        message: permissionMessage,
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    _showProgressDialog();

    try {
      final printers = await discovery.discoverLocalPrinters();
      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      if (printers.isEmpty) {
        await _showMessageDialog(
          title: AppLocalizations.of(context).settingsLocalPrinterResultsTitle,
          message: AppLocalizations.of(context).settingsLocalPrinterSearchEmpty,
        );
        return;
      }

      final selected = await _pickDiscoveredPrinter(printers);
      if (selected == null || !mounted) {
        return;
      }

      await ref
          .read(settingsControllerProvider.notifier)
          .savePrinter(_mapToLocalPrinter(widget.printer, selected));
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await _showMessageDialog(
          title: AppLocalizations.of(context).settingsLocalPrinterResultsTitle,
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

  Future<_LocalPrinterBrand?> _pickBrand() {
    final t = AppLocalizations.of(context);
    final supportsStar = ref
        .read(starXpandPrinterDiscoveryProvider)
        .isSupportedPlatform;

    return showDialog<_LocalPrinterBrand>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.settingsLocalPrinterBrandDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.print_rounded),
                title: Text(t.settingsLocalPrinterBrandStar),
                subtitle: Text(
                  supportsStar
                      ? t.settingsLocalPrinterSubtitle
                      : t.settingsLocalPrinterUnsupportedPlatform,
                ),
                enabled: supportsStar,
                onTap: supportsStar
                    ? () => Navigator.of(
                        dialogContext,
                      ).pop(_LocalPrinterBrand.star)
                    : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.desktop_windows_outlined),
                title: Text(t.settingsLocalPrinterBrandDefault),
                subtitle: Text(t.settingsLocalPrinterBrandDefaultHint),
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

  void _showProgressDialog() {
    final t = AppLocalizations.of(context);
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
              Expanded(child: Text(t.settingsLocalPrinterSearchProgress)),
            ],
          ),
        );
      },
    );
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

  PrinterSettings _mapToLocalPrinter(
    PrinterSettings current,
    StarXpandDiscoveredPrinter printer,
  ) {
    final connectionType = _connectionTypeFromTransport(printer.transport);
    return PrinterSettings(
      name: 'Star',
      type: PrinterSettings.localType,
      backend: PrinterBackend.starXpandNative,
      connectionType: connectionType,
      receipt: current.receipt,
      labelSize: current.labelSize,
      continuous: current.continuous,
      isOn: true,
      isDefault: true,
      printIp: printer.host,
      printPort: connectionType == PrinterConnectionType.network
          ? '9100'
          : null,
      deviceIdentifier: printer.identifier,
      modelName: printer.modelName ?? printer.displayName,
      option: current.option,
      direction: current.direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final printer = widget.printer;
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final brandLabel = printer.name.trim().isEmpty
        ? t.settingsValueNotSet
        : printer.name.trim();
    final modelLabel = _displayValue(t, printer.modelName);
    final identifierValue = _displayValue(
      t,
      (printer.deviceIdentifier?.trim().isNotEmpty ?? false)
          ? printer.deviceIdentifier
          : printer.printIp,
    );

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.settingsLocalPrinterTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.settingsLocalPrinterSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Tag(
                          icon: Icons.smartphone_rounded,
                          label: t.settingsPrinterTypeLocal,
                        ),
                        if (_isConfigured)
                          _Tag(icon: Icons.sell_outlined, label: brandLabel),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isConfigured && printer.isOn,
                onChanged: (!_isConfigured || _busy)
                    ? null
                    : (value) => _setPrinterEnabled(value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
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
              value: _connectionTypeLabel(t, printer.connectionType),
            ),
            _InfoRow(
              icon: Icons.pin_outlined,
              label: t.settingsLocalPrinterIdentifierLabel,
              value: identifierValue,
            ),
          ] else
            _EmptyPlaceholder(message: t.settingsValueNotSet),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _startAddFlow(),
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
                    ? t.settingsLocalPrinterReplaceAction
                    : t.settingsLocalPrinterAddAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
