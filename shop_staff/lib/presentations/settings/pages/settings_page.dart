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
import '../providers/settings_providers.dart';
import '../state/settings_state.dart';
import '../../../core/localization/locale_providers.dart';
import '../../cash_machine/widgets/cash_machine_check_dialog.dart';
import '../../entry/viewmodels/entry_viewmodels.dart';
import 'package:shop_staff/presentations/cash_register_closure/pages/cash_register_closure_route_args.dart';

part '../sections/business_info/business_info_section.dart';
part '../sections/system/system_settings_section.dart';
part '../sections/machine/machine_info_section.dart';
part '../widgets/settings_section_card.dart';
part '../widgets/settings_info_row.dart';
part '../widgets/settings_navigation_row.dart';
part '../sections/machine/widgets/cash_machine_settings_tile.dart';
part '../sections/machine/widgets/local_printer_settings_tile.dart';
part '../sections/machine/widgets/printer_settings_grid.dart';

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
      ref.read(settingsControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final vm = ref.read(settingsControllerProvider.notifier);
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
