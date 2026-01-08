import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import '../../../core/app_role.dart';
import '../../../data/providers.dart';
import '../../../main.dart';

import '../../../domain/settings/app_settings_models.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../../../core/localization/locale_providers.dart';
import '../../cash_machine/widgets/cash_machine_check_dialog.dart';
import '../../entry/viewmodels/entry_viewmodels.dart';

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
          title: Text('設置'),
        ),
        body: SafeArea(
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
                          message: state.error!,
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
    ));
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

class _BusinessInfoView extends StatelessWidget {
  const _BusinessInfoView({required this.state, required this.onRefresh});

  final SettingsState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final basic = state.snapshot.basic;
    final shop = state.shopInfo;
    return _RefreshableScroll(
      onRefresh: onRefresh,
      children: [
        _SectionCard(
          title: '店铺基本信息',
          subtitle: '这些信息将展示在前台与票据上',
          children: [
            _InfoRow(
              icon: Icons.storefront_rounded,
              label: '店铺名称',
              value: _displayValue(basic.shopName ?? shop?.shopName),
            ),
            _InfoRow(
              icon: Icons.qr_code_2_rounded,
              label: '店铺编号',
              value: _displayValue(basic.shopCode ?? shop?.shopCode),
            ),
            _InfoRow(
              icon: Icons.phone_iphone,
              label: '联系电话',
              value: _displayValue(basic.contactNumber ?? shop?.shopTelephone),
            ),
            _InfoRow(
              icon: Icons.place_rounded,
              label: '店铺地址',
              value: _displayValue(basic.address ?? shop?.shopAddress),
            ),
          ],
        ),
        _SectionCard(
          title: '营业时间 & 座位',
          subtitle: '来自门店主数据，可在后台系统维护',
          children: [
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: '营业时间',
              value: _displayValue(shop?.businessTime),
            ),
            _InfoRow(
              icon: Icons.event_seat_rounded,
              label: '座位数',
              value: _displayValue(shop?.seatNumber),
            ),
          ],
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
    final selectedLocale = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    final vm = ref.read(settingsViewModelProvider.notifier);
    final cashCheckState = ref.watch(cashMachineCheckControllerProvider);
    final cashCheckController = ref.read(cashMachineCheckControllerProvider.notifier);
    final currentRole = ref.watch(appRoleProvider);

    Future<void> onRoleSelected(AppRole target) async {
      if (target == currentRole) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('切换角色'),
            content: Text('切换到“${target.label}”需要重启应用以加载对应界面，是否立即重启？'),
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
          content: Text('已切换为${target.label}，即将跳转...'),
          duration: const Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 200));
      final router = container.read(appRouterProvider);
      final targetPath = target == AppRole.customer ? '/customer' : '/entry';
      router.go(targetPath);
    }

    return _RefreshableScroll(
      onRefresh: onRefresh,
      children: [
        _SectionCard(
          title: '角色选择',
          subtitle: '选择设备扮演的端，保存后会重启并进入对应界面',
          children: [
            _RoleSelector(
              current: currentRole,
              onSelect: onRoleSelected,
            ),
            const SizedBox(height: 10),
            Text(
              '店员端用于收银与管理；顾客端用于商品展示与下单。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68),
                  ),
            ),
          ],
        ),
        _SectionCard(
          title: '现金支付',
          subtitle: '检测现金机以启用或验证现金支付能力',
          children: [
            _InfoRow(
              icon: Icons.payments_rounded,
              label: '当前状态',
              value: cashCheckState.isSupported
                  ? (cashCheckState.isEnabled ? '已启用' : '未启用')
                  : '未授权或不支持现金支付',
            ),
            if (cashCheckState.lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                '最近一次检测失败: ${cashCheckState.lastError}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: (!cashCheckState.isSupported || cashCheckState.isChecking)
                      ? null
                      : () => cashCheckController.start(auto: false),
                  icon: cashCheckState.isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_rounded),
                  label: Text(cashCheckState.isChecking ? '检测中…' : '立即检测'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: cashCheckState.isChecking
                      ? null
                      : () => cashCheckController.skip(),
                  child: const Text('跳过本次'),
                ),
              ],
            ),
          ],
        ),

                _SectionCard(
          title: 'POS终端网络',
          subtitle: '确保终端与刷卡设备保持在同一网络',
          children: [
            _InfoRow(
              icon: Icons.language_rounded,
              label: '终端 IP',
              value: _displayValue(pos.posIp),
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
              label: '终端端口',
              value: _displayValue(pos.posPort?.toString()),
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
          title: '打印机配置',
          subtitle: '控制小票、标签及厨房打印',
          children: printers.isEmpty
              ? const [_EmptyPlaceholder(message: '暂无打印机配置，可在后台新增')]
              : [_PrinterGrid(printers: printers)],
        ),

                _SectionCard(
          title: t.settingsLanguageSectionTitle,
          subtitle: t.settingsLanguageSectionSubtitle,
          children: [
            _LanguageOptionTile(
              label: t.settingsLanguageSystem,
              value: null,
              groupValue: selectedLocale,
              onSelect: (_) => controller.useSystemLocale(),
            ),
            const SizedBox(height: 8),
            _LanguageOptionTile(
              label: t.settingsLanguageChinese,
              value: const Locale('zh'),
              groupValue: selectedLocale,
              onSelect: (_) => controller.update(const Locale('zh')),
            ),
            const SizedBox(height: 8),
            _LanguageOptionTile(
              label: t.settingsLanguageJapanese,
              value: const Locale('ja'),
              groupValue: selectedLocale,
              onSelect: (_) => controller.update(const Locale('ja')),
            ),
            const SizedBox(height: 8),
            _LanguageOptionTile(
              label: t.settingsLanguageEnglish,
              value: const Locale('en'),
              groupValue: selectedLocale,
              onSelect: (_) => controller.update(const Locale('en')),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.current, required this.onSelect});

  final AppRole current;
  final Future<void> Function(AppRole role) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: AppRole.values.map((role) {
        final active = role == current;
        final label = role == AppRole.staff ? '店员端' : '顾客端';
        final icon = role == AppRole.staff ? Icons.badge_rounded : Icons.tv_rounded;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor:
              theme.colorScheme.surfaceVariant.withValues(alpha: 0.32),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.16),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
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
    final shop = state.shopInfo;
    final basic = state.snapshot.basic;
    final languages =
        shop?.languages
            .map((e) => e.name)
            .where((e) => e.isNotEmpty)
            .toList() ??
        const [];
    final features = <_FeatureChipData>[
      _FeatureChipData('线上叫号', shop?.onlineCall ?? false),
      _FeatureChipData('税制', shop?.taxSystem ?? false),
      _FeatureChipData('动态取票', shop?.dynamicCode ?? false),
      _FeatureChipData('多人协同', shop?.multiplayer ?? false),
    ];

    return _RefreshableScroll(
      onRefresh: onRefresh,
      children: [
        _SectionCard(
          title: '设备标识',
          subtitle: '当前终端与激活信息',
          children: [
            _InfoRow(
              icon: Icons.confirmation_number,
              label: '机器码',
              value: _displayValue(shop?.machineCode ?? basic.machineCode),
            ),
            _InfoRow(
              icon: Icons.qr_code,
              label: '工作站编码',
              value: _displayValue(shop?.stationMachineCode),
            ),
            _InfoRow(
              icon: Icons.lock_clock,
              label: '授权门店号',
              value: _displayValue(shop?.shopCode ?? basic.shopCode),
            ),
          ],
        ),
        _SectionCard(
          title: '语言与功能',
          subtitle: '根据门店授权调整显示语言与能力',
          children: [
            _InfoRow(
              icon: Icons.language,
              label: '支持语言',
              value: languages.isEmpty ? '未配置' : languages.join(' / '),
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
    required this.children,
  });

  final String title;
  final String? subtitle;
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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
              label: Text(editLabel ?? '编辑'),
            ),
          ],
        ],
      ),
    );
  }
}

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
    final typeLabel = _printerType(printer.type);
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
                          const _Tag(icon: Icons.star_rounded, label: '默认'),
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
            subtitle: Text(_displayValue(printer.printIp)),
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
            subtitle: Text(_displayValue(printer.printPort)),
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
  const _LanguageOptionTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelect,
  });

  final String label;
  final Locale? value;
  final Locale? groupValue;
  final void Function(Locale? locale) onSelect;

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
        groupValue: groupValue,
        onChanged: onSelect,
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

String _displayValue(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '未设置';
  }
  return value.trim();
}

String _printerType(int type) {
  switch (type) {
    case 10:
      return '厨房打印';
    case 11:
      return '中心打印';
    case 12:
      return '前台打印';
    default:
      return '打印类型 $type';
  }
}
