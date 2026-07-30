part of '../../pages/settings_page.dart';

class _SystemSettingsView extends ConsumerWidget {
  const _SystemSettingsView({
    required this.state,
    required this.onRefresh,
    required this.t,
  });

  final SettingsState state;
  final Future<void> Function() onRefresh;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = state.snapshot.posTerminal;
    final printers = state.snapshot.printers;
    final localPrinter = _resolveLocalPrinter(printers);
    final kitchenPrinters = printers
        .where((printer) => printer.type != PrinterSettings.localType)
        .toList(growable: false);
    final basic = state.snapshot.basic;
    final selectedLocale = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    final languageOverride = ref.read(languageOverrideProvider.notifier);
    final vm = ref.read(settingsControllerProvider.notifier);
    final cashCheckState = ref.watch(cashMachineCheckControllerProvider);
    final currentRole = ref.watch(appRoleProvider);
    final actuarialSupported = state.shopInfo?.actuarial ?? false;
    final availableModeCount =
        (basic.orderModes.dineIn ? 1 : 0) +
        (basic.orderModes.takeout ? 1 : 0) +
        (actuarialSupported && basic.orderModes.settlement ? 1 : 0);

    Future<void> updateOrderModes(OrderModeSettings orderModes) {
      return vm.saveBasicSettings(basic.copyWith(orderModes: orderModes));
    }

    Future<void> onRoleSelected(AppRole target) async {
      if (target == currentRole) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(t.settingsRoleSwitchTitle),
            content: Text(t.settingsRoleSwitchMessage(target.label)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(t.dialogCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(t.dialogConfirm),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
      if (!context.mounted) return;
      final container = ProviderScope.containerOf(context);
      await container.read(appRoleServiceProvider).saveRole(target);
      container.read(appRoleProvider.notifier).state = target;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.settingsRoleSwitchSuccess(target.label)),
          duration: const Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 200));
      final router = container.read(appRouterProvider);
      final targetPath = target == AppRole.customer ? '/customer' : '/entry';
      router.go(targetPath);
    }

    Future<void> onLocaleSelected(Locale? locale) async {
      final settingsCode = localeToSettingsCode(locale);
      if (locale == null) {
        controller.useSystemLocale();
      } else {
        controller.update(locale);
      }
      languageOverride.state = localeToShopLanguageOverride(locale);
      await vm.saveBasicSettings(
        basic.copyWith(displayLocaleCode: settingsCode),
      );
    }

    return _RefreshableScroll(
      onRefresh: onRefresh,
      children: [
        _SectionCard(
          title: t.settingsOrderModeSupportTitle,
          subtitle: t.settingsOrderModeSupportSubtitle,
          children: [
            _OrderModeSupportTile(
              icon: Icons.restaurant_menu_rounded,
              label: t.entryDineInTitle,
              selected: basic.orderModes.dineIn,
              canDisable: availableModeCount > 1,
              onChanged: (selected) =>
                  updateOrderModes(basic.orderModes.copyWith(dineIn: selected)),
            ),
            const SizedBox(height: 8),
            _OrderModeSupportTile(
              icon: Icons.shopping_bag_rounded,
              label: t.entryTakeoutTitle,
              selected: basic.orderModes.takeout,
              canDisable: availableModeCount > 1,
              onChanged: (selected) => updateOrderModes(
                basic.orderModes.copyWith(takeout: selected),
              ),
            ),
            if (actuarialSupported) ...[
              const SizedBox(height: 8),
              _OrderModeSupportTile(
                icon: Icons.point_of_sale_rounded,
                label: t.entrySettlementTitle,
                selected: basic.orderModes.settlement,
                canDisable: availableModeCount > 1,
                onChanged: (selected) => updateOrderModes(
                  basic.orderModes.copyWith(settlement: selected),
                ),
              ),
            ],
          ],
        ),
        _SectionCard(
          title: t.settingsRoleSelectionTitle,
          subtitle: t.settingsRoleSelectionSubtitle,
          trailing: Switch.adaptive(
            value: basic.peerLinkEnabled,
            onChanged: (enabled) =>
                vm.saveBasicSettings(basic.copyWith(peerLinkEnabled: enabled)),
          ),
          children: [
            _RoleSelector(current: currentRole, onSelect: onRoleSelected, t: t),
            const SizedBox(height: 10),
            Text(
              t.settingsRoleSelectionDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
        _SectionCard(
          title: t.settingsCashPaymentTitle,
          subtitle: t.settingsCashPaymentSubtitle,
          children: [
            _CashMachineTile(basic: basic, checkState: cashCheckState),
          ],
        ),

        _SectionCard(
          title: t.settingsPaymentModeTitle,
          subtitle: t.settingsPaymentModeSubtitle,
          children: [
            _PaymentModePreferenceTile(
              icon: Icons.attach_money_rounded,
              label: t.settingsPaymentModeCashLabel,
              helper: t.settingsPaymentModeCashHint,
              value: basic.paymentModes.resolveCash(basic.cashMachine),
              onChanged: (mode) => vm.saveBasicSettings(
                basic.copyWith(
                  paymentModes: basic.paymentModes.copyWith(cash: mode),
                ),
              ),
              t: t,
            ),
            const SizedBox(height: 12),
            _PaymentModePreferenceTile(
              icon: Icons.credit_card_rounded,
              label: t.settingsPaymentModeCardLabel,
              value: basic.paymentModes.resolveCard(),
              onChanged: (mode) => vm.saveBasicSettings(
                basic.copyWith(
                  paymentModes: basic.paymentModes.copyWith(card: mode),
                ),
              ),
              t: t,
            ),
            const SizedBox(height: 12),
            _PaymentModePreferenceTile(
              icon: Icons.qr_code_2_rounded,
              label: t.settingsPaymentModeQrLabel,
              value: basic.paymentModes.resolveQr(),
              onChanged: (mode) => vm.saveBasicSettings(
                basic.copyWith(
                  paymentModes: basic.paymentModes.copyWith(qr: mode),
                ),
              ),
              t: t,
            ),
          ],
        ),

        _SectionCard(
          title: t.settingsPosNetworkTitle,
          subtitle: t.settingsPosNetworkSubtitle,
          children: [
            _InfoRow(
              icon: Icons.language_rounded,
              label: t.settingsPosIpLabel,
              value: _displayValue(t, pos.posIp),
              editLabel: t.settingsEditAction,
              onEdit: () async {
                final input = await _promptForValue(
                  context,
                  t: t,
                  title: t.settingsNetworkEditIpTitle,
                  label: t.settingsNetworkEditIpLabel,
                  hint: t.settingsNetworkEditIpHint,
                  initialValue: pos.posIp ?? '',
                  keyboardType: TextInputType.text,
                  validator: (value) => _validateIp(t, value),
                );
                if (input == null) return;
                final trimmed = input.trim();
                await vm.savePosTerminal(
                  PosTerminalSettings(
                    posIp: trimmed.isEmpty ? null : trimmed,
                    posPort: pos.posPort,
                  ),
                );
              },
            ),
            _InfoRow(
              icon: Icons.settings_ethernet,
              label: t.settingsPosPortLabel,
              value: _displayValue(t, pos.posPort?.toString()),
              editLabel: t.settingsEditAction,
              onEdit: () async {
                final input = await _promptForValue(
                  context,
                  t: t,
                  title: t.settingsNetworkEditPortTitle,
                  label: t.settingsNetworkEditPortLabel,
                  hint: t.settingsNetworkEditPortHint,
                  initialValue: pos.posPort?.toString() ?? '',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                    signed: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _validatePort(t, value),
                );
                if (input == null) return;
                final trimmed = input.trim();
                final int? newPort = trimmed.isEmpty
                    ? null
                    : int.parse(trimmed);
                await vm.savePosTerminal(
                  PosTerminalSettings(posIp: pos.posIp, posPort: newPort),
                );
              },
            ),
          ],
        ),

        _SectionCard(
          title: t.settingsPrinterConfigTitle,
          subtitle: t.settingsPrinterConfigSubtitle,
          children: [
            _LocalPrinterTile(printer: localPrinter),
            const SizedBox(height: 16),
            if (kitchenPrinters.isEmpty)
              _EmptyPlaceholder(message: t.settingsPrinterKitchenEmpty)
            else
              _PrinterGrid(printers: kitchenPrinters),
          ],
        ),

        _SectionCard(
          title: t.settingsLanguageSectionTitle,
          subtitle: t.settingsLanguageSectionSubtitle,
          children: [
            RadioGroup<Locale?>(
              groupValue: selectedLocale,
              onChanged: onLocaleSelected,
              child: Column(
                children: [
                  _LanguageOptionTile(
                    label: t.settingsLanguageSystem,
                    value: null,
                  ),
                  const SizedBox(height: 8),
                  _LanguageOptionTile(
                    label: t.settingsLanguageChinese,
                    value: const Locale('zh'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageOptionTile(
                    label: t.settingsLanguageJapanese,
                    value: const Locale('ja'),
                  ),
                  const SizedBox(height: 8),
                  _LanguageOptionTile(
                    label: t.settingsLanguageEnglish,
                    value: const Locale('en'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderModeSupportTile extends StatelessWidget {
  const _OrderModeSupportTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.canDisable,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool canDisable;
  final Future<void> Function(bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLockedOn = selected && !canDisable;
    return SwitchListTile.adaptive(
      value: selected,
      onChanged: isLockedOn ? null : onChanged,
      secondary: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.current,
    required this.onSelect,
    required this.t,
  });

  final AppRole current;
  final Future<void> Function(AppRole role) onSelect;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: AppRole.values.map((role) {
        final active = role == current;
        final label = role == AppRole.staff
            ? t.peerLabelStaff
            : t.peerLabelCustomer;
        final icon = role == AppRole.staff
            ? Icons.badge_rounded
            : Icons.tv_rounded;
        final color = active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.64);
        return ChoiceChip(
          selected: active,
          onSelected: active ? null : (_) => onSelect(role),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.32,
          ),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

class _PaymentModePreferenceTile extends StatelessWidget {
  const _PaymentModePreferenceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.t,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String? helper;
  final PaymentFlowMode value;
  final Future<void> Function(PaymentFlowMode mode) onChanged;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ChoiceChip(
                selected: value == PaymentFlowMode.bookkeeping,
                onSelected: value == PaymentFlowMode.bookkeeping
                    ? null
                    : (_) => onChanged(PaymentFlowMode.bookkeeping),
                label: Text(t.settingsPaymentModeBookkeeping),
              ),
              ChoiceChip(
                selected: value == PaymentFlowMode.real,
                onSelected: value == PaymentFlowMode.real
                    ? null
                    : (_) => onChanged(PaymentFlowMode.real),
                label: Text(t.settingsPaymentModeReal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValuePromptDialog extends StatefulWidget {
  const _ValuePromptDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.validator,
    required this.t,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  final String title;
  final String label;
  final String initialValue;
  final String? hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value) validator;
  final AppLocalizations t;

  @override
  State<_ValuePromptDialog> createState() => _ValuePromptDialogState();
}

class _ValuePromptDialogState extends State<_ValuePromptDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.hint,
          ),
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: (raw) => widget.validator(raw?.trim() ?? ''),
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.t.dialogCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.t.dialogConfirm)),
      ],
    );
  }
}

Future<String?> _promptForValue(
  BuildContext context, {
  required AppLocalizations t,
  required String title,
  required String label,
  String? hint,
  required String initialValue,
  TextInputType keyboardType = TextInputType.text,
  List<TextInputFormatter>? inputFormatters,
  required String? Function(String value) validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _ValuePromptDialog(
      title: title,
      label: label,
      hint: hint,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      t: t,
    ),
  );
}

String? _validateIp(AppLocalizations t, String value) {
  if (value.isEmpty) {
    return null;
  }
  final segments = value.split('.');
  if (segments.length != 4) {
    return t.settingsNetworkEditInvalidIp;
  }
  for (final segment in segments) {
    final part = int.tryParse(segment);
    if (part == null || part < 0 || part > 255) {
      return t.settingsNetworkEditInvalidIp;
    }
  }
  return null;
}

String? _validatePort(AppLocalizations t, String value) {
  if (value.isEmpty) {
    return null;
  }
  final port = int.tryParse(value);
  if (port == null || port < 1 || port > 65535) {
    return t.settingsNetworkEditInvalidPort;
  }
  return null;
}
