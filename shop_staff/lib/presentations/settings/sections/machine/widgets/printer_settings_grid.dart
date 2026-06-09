part of '../../../pages/settings_page.dart';

class _PrinterGrid extends StatelessWidget {
  const _PrinterGrid({required this.printers});

  final List<PrinterSettings> printers;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: printers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _PrinterTile(printer: printers[index]);
      },
    );
  }
}

class _PrinterTile extends ConsumerWidget {
  const _PrinterTile({required this.printer});

  final PrinterSettings printer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final vm = ref.read(settingsControllerProvider.notifier);
    final receiptLabel = printer.receipt
        ? t.settingsPrinterReceiptTicket
        : t.settingsPrinterReceiptLabel;
    final typeLabel = _printerType(t, printer.type);
    String? selectedLabelKey;
    for (final entry in _labelPrintSize.entries) {
      if (entry.value == printer.labelSize || entry.key == printer.labelSize) {
        selectedLabelKey = entry.key;
        break;
      }
    }
    final fallbackLabel = selectedLabelKey == null ? printer.labelSize : null;
    final dropdownValue =
        selectedLabelKey ??
        (fallbackLabel?.isNotEmpty == true ? fallbackLabel : null);

    Future<void> updatePrinter(PrinterSettings updated) async {
      await vm.savePrinter(updated);
    }

    Future<void> editIp() async {
      final input = await _promptForValue(
        context,
        t: t,
        title: t.settingsPrinterEditIpTitle,
        label: t.settingsPrinterEditIpLabel,
        hint: t.settingsNetworkEditIpHint,
        initialValue: printer.printIp ?? '',
        keyboardType: TextInputType.text,
        validator: (value) => _validateIp(t, value),
      );
      if (input == null) return;
      final trimmed = input.trim();
      await updatePrinter(
        printer.copyWith(printIp: trimmed.isEmpty ? null : trimmed),
      );
    }

    Future<void> editPort() async {
      final input = await _promptForValue(
        context,
        t: t,
        title: t.settingsPrinterEditPortTitle,
        label: t.settingsPrinterEditPortLabel,
        hint: t.settingsNetworkEditPortHint,
        initialValue: printer.printPort ?? '',
        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) => _validatePort(t, value),
      );
      if (input == null) return;
      final trimmed = input.trim();
      await updatePrinter(
        printer.copyWith(printPort: trimmed.isEmpty ? null : trimmed),
      );
    }

    Future<void> selectLabelSize(String? key) async {
      final newValue = key == null ? '' : _labelPrintSize[key] ?? key;
      if (newValue == printer.labelSize) {
        return;
      }
      await updatePrinter(printer.copyWith(labelSize: newValue));
    }

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
                      printer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Tag(icon: Icons.print_rounded, label: typeLabel),
                        _Tag(icon: Icons.receipt_long, label: receiptLabel),
                        if (printer.isDefault)
                          _Tag(
                            icon: Icons.star_rounded,
                            label: t.settingsPrinterDefaultTag,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: printer.isOn,
                onChanged: (value) =>
                    updatePrinter(printer.copyWith(isOn: value)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.language, color: theme.colorScheme.primary),
            title: Text(t.settingsPrinterIpTitle),
            subtitle: Text(_displayValue(t, printer.printIp)),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: editIp,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.settings_ethernet,
              color: theme.colorScheme.primary,
            ),
            title: Text(t.settingsPrinterPortTitle),
            subtitle: Text(_displayValue(t, printer.printPort)),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: editPort,
          ),
          if (printer.receipt == false)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t.settingsPrinterLabelSizeTitle,
                  prefixIcon: Icon(
                    Icons.view_week,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: dropdownValue,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(t.settingsPrinterLabelSizeNone),
                      ),
                      for (final entry in _labelPrintSize.entries)
                        DropdownMenuItem<String?>(
                          value: entry.key,
                          child: Text('${entry.key} (${entry.value})'),
                        ),
                      if (fallbackLabel != null && fallbackLabel.isNotEmpty)
                        DropdownMenuItem<String?>(
                          value: fallbackLabel,
                          child: Text(fallbackLabel),
                        ),
                    ],
                    onChanged: (value) => selectLabelSize(value),
                  ),
                ),
              ),
            ),
          if (printer.type != 11)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: printer.continuous,
              onChanged: (value) =>
                  updatePrinter(printer.copyWith(continuous: value)),
              title: Text(t.settingsPrinterToggleContinuous),
              secondary: Icon(Icons.repeat, color: theme.colorScheme.primary),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: printer.option,
            onChanged: (value) =>
                updatePrinter(printer.copyWith(option: value)),
            title: Text(t.settingsPrinterToggleOption),
            secondary: Icon(
              Icons.rule_folder_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: printer.direction,
            onChanged: (value) =>
                updatePrinter(printer.copyWith(direction: value)),
            title: Text(t.settingsPrinterToggleDirection),
            secondary: Icon(Icons.swap_vert, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
