import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:starxpand_flutter/starxpand_flutter.dart';
import '../../../core/app_role.dart';
import '../../../data/providers.dart';

import '../../../domain/settings/app_settings_models.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../../../core/localization/locale_providers.dart';
import '../../cash_machine/widgets/cash_machine_check_dialog.dart';
import '../../entry/viewmodels/entry_viewmodels.dart';
import 'cash_register_closure_page.dart';
import 'shop_info_detail_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsViewModelProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return CashMachineDialogPortal(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 64,
          elevation: 6, // stronger shadow
          shadowColor: Colors.grey.withAlpha(100),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.stone500,
          titleSpacing: 0,
          title: Text(t.settingsTitle),
        ),
        body: SafeArea(
          top: false,
          child: Row(
            children: [
              _SettingsSidebar(
                selected: state.selected,
                onSelect: vm.select,
                t: t,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: theme.colorScheme.surface),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsHeader(
                        section: state.selected,
                        loading: state.loading,
                        onRefresh: vm.refreshSettings,
                        t: t,
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: _ErrorBanner(
                            message: _localizeSettingsError(t, state),
                            onDismissed: vm.clearError,
                          ),
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _SettingsContent(
                            key: ValueKey(state.selected),
                            state: state,
                            onRefresh: vm.refreshSettings,
                            t: t,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizeSettingsError(AppLocalizations t, SettingsState state) {
    final detail = state.error ?? t.commonUnknownError;
    return switch (state.errorType) {
      SettingsErrorType.load => t.settingsErrorLoadFailed(detail),
      SettingsErrorType.saveBasic => t.settingsErrorSaveBasicFailed(detail),
      SettingsErrorType.saveNetwork => t.settingsErrorSaveNetworkFailed(detail),
      SettingsErrorType.savePrinter => t.settingsErrorSavePrinterFailed(detail),
      null => detail,
    };
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.selected,
    required this.onSelect,
    required this.t,
  });

  final SettingsSection selected;
  final void Function(SettingsSection) onSelect;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = SettingsSection.values;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.settingsShellTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.settingsShellSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final section = items[index];
                final active = section == selected;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelect(section),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sectionIcon(section),
                            size: 20,
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.localizedTitle(t),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: active
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  section.localizedSubtitle(t),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.section,
    required this.loading,
    required this.onRefresh,
    required this.t,
  });

  final SettingsSection section;
  final bool loading;
  final Future<void> Function() onRefresh;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.localizedTitle(t),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.localizedSubtitle(t),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: t.settingsRefreshTooltip,
            child: IconButton.filledTonal(
              icon: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              onPressed: loading ? null : () => onRefresh(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.t,
  });

  final SettingsState state;
  final Future<void> Function() onRefresh;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    switch (state.selected) {
      case SettingsSection.businessInfo:
        return _BusinessInfoView(state: state, onRefresh: onRefresh);
      case SettingsSection.systemSettings:
        return _SystemSettingsView(state: state, onRefresh: onRefresh, t: t);
      case SettingsSection.machineInfo:
        return _MachineInfoView(state: state, onRefresh: onRefresh);
    }
  }
}

class _BusinessInfoView extends ConsumerWidget {
  const _BusinessInfoView({required this.state, required this.onRefresh});

  final SettingsState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basic = state.snapshot.basic;
    final shop = state.shopInfo;
    final vm = ref.read(settingsViewModelProvider.notifier);
    final t = AppLocalizations.of(context);
    return _RefreshableScroll(
      onRefresh: onRefresh,
      children: [
        _NavigationRow(
          icon: Icons.storefront_rounded,
          title: t.settingsBusinessInfoTitle,
          subtitle:
              '${_displayValue(t, basic.shopName ?? shop?.shopName)} / '
              '${_displayValue(t, basic.shopCode ?? shop?.shopCode)}',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShopInfoDetailPage(state: state),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _NavigationRow(
          icon: Icons.phone_iphone,
          title: t.settingsBusinessPhoneLabel,
          subtitle: _displayValue(
            t,
            basic.contactNumber ?? shop?.shopTelephone,
          ),
        ),
        const SizedBox(height: 12),
        _NavigationRow(
          icon: Icons.place_rounded,
          title: t.settingsBusinessAddressLabel,
          subtitle: _displayValue(t, basic.address ?? shop?.shopAddress),
        ),
        const SizedBox(height: 12),
        _NavigationRow(
          icon: Icons.point_of_sale_rounded,
          title: 'レジ締め',
          subtitle: 'メール認証、集計確認、履歴、消込',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CashRegisterClosurePage(
                  machineCode:
                      shop?.machineCode ??
                      shop?.stationMachineCode ??
                      basic.machineCode ??
                      '',
                  shopName: _displayValue(t, basic.shopName ?? shop?.shopName),
                ),
              ),
            );
          },
        ),
        //log out button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ElevatedButton.icon(
            onPressed: () {
              vm.logout(
                title: t.settingsLogoutConfirmTitle,
                message: t.settingsLogoutConfirmMessage,
              );
            },
            icon: const Icon(Icons.exit_to_app_rounded),
            label: Text(t.settingsLogoutButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

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
    final vm = ref.read(settingsViewModelProvider.notifier);
    final cashCheckState = ref.watch(cashMachineCheckControllerProvider);
    final currentRole = ref.watch(appRoleProvider);

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

class _MachineInfoView extends StatelessWidget {
  const _MachineInfoView({required this.state, required this.onRefresh});

  final SettingsState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final shop = state.shopInfo;
    final basic = state.snapshot.basic;
    final languages =
        shop?.languages
            .map((e) => e.name)
            .where((e) => e.isNotEmpty)
            .toList() ??
        const [];
    final features = <_FeatureChipData>[
      _FeatureChipData(t.settingsFeatureOnlineCall, shop?.onlineCall ?? false),
      _FeatureChipData(t.settingsFeatureTaxSystem, shop?.taxSystem ?? false),
      _FeatureChipData(
        t.settingsFeatureDynamicCode,
        shop?.dynamicCode ?? false,
      ),
      _FeatureChipData(
        t.settingsFeatureMultiplayer,
        shop?.multiplayer ?? false,
      ),
    ];

    return _RefreshableScroll(
      onRefresh: onRefresh,
      children: [
        _SectionCard(
          title: t.settingsMachineInfoTitle,
          subtitle: t.settingsMachineInfoSubtitle,
          children: [
            _InfoRow(
              icon: Icons.confirmation_number,
              label: t.settingsMachineCodeLabel,
              value: _displayValue(t, shop?.machineCode ?? basic.machineCode),
            ),
            _InfoRow(
              icon: Icons.qr_code,
              label: t.settingsStationCodeLabel,
              value: _displayValue(t, shop?.stationMachineCode),
            ),
            _InfoRow(
              icon: Icons.lock_clock,
              label: t.settingsAuthorizedShopLabel,
              value: _displayValue(t, shop?.shopCode ?? basic.shopCode),
            ),
          ],
        ),
        _SectionCard(
          title: t.settingsLanguageFeatureTitle,
          subtitle: t.settingsLanguageFeatureSubtitle,
          children: [
            _InfoRow(
              icon: Icons.language,
              label: t.settingsSupportedLanguagesLabel,
              value: languages.isEmpty
                  ? t.settingsSupportedLanguagesEmpty
                  : languages.join(' / '),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final feature in features)
                  _FeatureChip(label: feature.label, enabled: feature.enabled),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _RefreshableScroll extends StatelessWidget {
  const _RefreshableScroll({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 24,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [const SizedBox(height: 8), ...children],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.colorScheme.surface.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

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

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

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
        .read(settingsViewModelProvider.notifier)
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
        .read(settingsViewModelProvider.notifier)
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
          .read(settingsViewModelProvider.notifier)
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
    final vm = ref.read(settingsViewModelProvider.notifier);
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
