import 'package:flutter/material.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/settings/viewmodels/settings_viewmodel.dart';

class ShopInfoDetailPage extends StatelessWidget {
  const ShopInfoDetailPage({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final basic = state.snapshot.basic;
    final shop = state.shopInfo;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(t.settingsBusinessInfoTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.stone500,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _InfoCard(
            title: t.settingsBusinessInfoTitle,
            children: [
              _InfoLine(
                label: t.settingsBusinessNameLabel,
                value: _displayValue(t, basic.shopName ?? shop?.shopName),
              ),
              _InfoLine(
                label: t.settingsBusinessCodeLabel,
                value: _displayValue(t, basic.shopCode ?? shop?.shopCode),
              ),
              _InfoLine(
                label: t.settingsBusinessPhoneLabel,
                value: _displayValue(
                  t,
                  basic.contactNumber ?? shop?.shopTelephone,
                ),
              ),
              _InfoLine(
                label: t.settingsBusinessAddressLabel,
                value: _displayValue(t, basic.address ?? shop?.shopAddress),
              ),
              _InfoLine(
                label: t.settingsMachineCodeLabel,
                value: _displayValue(t, shop?.machineCode ?? basic.machineCode),
              ),
              _InfoLine(
                label: t.settingsStationCodeLabel,
                value: _displayValue(t, shop?.stationMachineCode),
              ),
              _InfoLine(label: 'NTA No.', value: _displayValue(t, shop?.ntaNo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.stone500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayValue(AppLocalizations t, Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return t.settingsValueNotSet;
  return text;
}
