part of '../../pages/settings_page.dart';

class _BusinessInfoView extends ConsumerWidget {
  const _BusinessInfoView({required this.state, required this.onRefresh});

  final SettingsState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basic = state.snapshot.basic;
    final shop = state.shopInfo;
    final vm = ref.read(settingsControllerProvider.notifier);
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
            ref.read(appRouterProvider).push('/settings/shop-info');
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
          title: t.cashRegisterClosureTitle,
          subtitle: t.cashRegisterClosureSettingsSubtitle,
          onTap: () {
            ref
                .read(appRouterProvider)
                .push(
                  '/cash-register-closure',
                  extra: CashRegisterClosurePageArgs(
                    machineCode:
                        shop?.machineCode ??
                        shop?.stationMachineCode ??
                        basic.machineCode ??
                        '',
                    shopName: _displayValue(
                      t,
                      basic.shopName ?? shop?.shopName,
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
