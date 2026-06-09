part of '../pages/settings_page.dart';

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.editLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final String? editLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(editLabel ?? t.settingsEditAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChipData {
  const _FeatureChipData(this.label, this.enabled);

  final String label;
  final bool enabled;
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return Chip(
      avatar: Icon(
        enabled ? Icons.check_circle : Icons.remove_circle_outline,
        size: 18,
        color: color,
      ),
      label: Text(label),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismissed});

  final String message;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.error.withValues(alpha: 0.12),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: theme.colorScheme.error,
              onPressed: onDismissed,
              tooltip: AppLocalizations.of(context).settingsErrorDismissTooltip,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({required this.label, required this.value});

  final String label;
  final Locale? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: RadioListTile<Locale?>(
        value: value,
        dense: true,
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

extension SettingsSectionLocalization on SettingsSection {
  String localizedTitle(AppLocalizations t) {
    switch (this) {
      case SettingsSection.businessInfo:
        return t.settingsSectionBusinessTitle;
      case SettingsSection.systemSettings:
        return t.settingsSectionSystemTitle;
      case SettingsSection.machineInfo:
        return t.settingsSectionMachineTitle;
    }
  }

  String localizedSubtitle(AppLocalizations t) {
    switch (this) {
      case SettingsSection.businessInfo:
        return t.settingsSectionBusinessSubtitle;
      case SettingsSection.systemSettings:
        return t.settingsSectionSystemSubtitle;
      case SettingsSection.machineInfo:
        return t.settingsSectionMachineSubtitle;
    }
  }
}

IconData _sectionIcon(SettingsSection section) {
  switch (section) {
    case SettingsSection.businessInfo:
      return Icons.storefront_rounded;
    case SettingsSection.systemSettings:
      return Icons.settings_applications_rounded;
    case SettingsSection.machineInfo:
      return Icons.memory_rounded;
  }
}

String _displayValue(AppLocalizations t, String? value) {
  if (value == null || value.trim().isEmpty) {
    return t.settingsValueNotSet;
  }
  return value.trim();
}

String _printerType(AppLocalizations t, int type) {
  switch (type) {
    case PrinterSettings.localType:
      return t.settingsPrinterTypeLocal;
    case PrinterSettings.kitchenType:
      return t.settingsPrinterTypeKitchen;
    case PrinterSettings.centerType:
      return t.settingsPrinterTypeCenter;
    case PrinterSettings.counterType:
      return t.settingsPrinterTypeFront;
    default:
      return t.settingsPrinterTypeUnknown(type.toString());
  }
}

String _connectionTypeLabel(
  AppLocalizations t,
  PrinterConnectionType connectionType,
) {
  switch (connectionType) {
    case PrinterConnectionType.network:
      return 'Wi-Fi';
    case PrinterConnectionType.bluetoothClassic:
      return 'Bluetooth';
    case PrinterConnectionType.bluetoothLe:
      return 'Bluetooth LE';
    case PrinterConnectionType.usb:
      return 'USB';
    case PrinterConnectionType.usbC:
      return 'USB-C';
    case PrinterConnectionType.lightningUsb:
      return 'Lightning USB';
    case PrinterConnectionType.unknown:
      return t.settingsValueNotSet;
  }
}

String _cashMachineBrandLabel(CashMachineBrand? brand) {
  switch (brand) {
    case CashMachineBrand.glory:
      return 'Glory';
    case CashMachineBrand.star:
      return 'Star';
    case CashMachineBrand.conlux:
      return 'Conlux';
    case null:
      return '';
  }
}

String _cashMachineTransportLabel(
  AppLocalizations t,
  CashMachineSettings cashMachine,
) {
  switch (cashMachine.brand) {
    case CashMachineBrand.glory:
      return 'Windows';
    case CashMachineBrand.star:
      return _connectionTypeLabel(t, cashMachine.connectionType);
    case CashMachineBrand.conlux:
      return cashMachine.connectionType == PrinterConnectionType.unknown
          ? t.settingsValueNotSet
          : _connectionTypeLabel(t, cashMachine.connectionType);
    case null:
      return t.settingsValueNotSet;
  }
}

PrinterConnectionType _connectionTypeFromTransport(
  StarXpandTransport transport,
) {
  switch (transport) {
    case StarXpandTransport.network:
      return PrinterConnectionType.network;
    case StarXpandTransport.bluetoothClassic:
      return PrinterConnectionType.bluetoothClassic;
    case StarXpandTransport.bluetoothLe:
      return PrinterConnectionType.bluetoothLe;
    case StarXpandTransport.usb:
      return PrinterConnectionType.usb;
    case StarXpandTransport.usbC:
      return PrinterConnectionType.usbC;
    case StarXpandTransport.lightningUsb:
      return PrinterConnectionType.lightningUsb;
  }
}

PrinterSettings _resolveLocalPrinter(List<PrinterSettings> printers) {
  for (final printer in printers) {
    if (printer.type == PrinterSettings.localType && printer.receipt) {
      return printer;
    }
  }

  return PrinterSettings.defaultProfiles().firstWhere(
    (printer) => printer.type == PrinterSettings.localType && printer.receipt,
  );
}
