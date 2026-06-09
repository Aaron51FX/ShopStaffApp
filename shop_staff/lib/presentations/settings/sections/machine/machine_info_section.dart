part of '../../pages/settings_page.dart';

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
