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
    final staffEmail = ref.watch(currentStaffEmailProvider);
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
          icon: Icons.person_outline_rounded,
          title: t.settingsCurrentStaffLabel,
          subtitle: staffEmail.when(
            data: (email) => _displayValue(t, email),
            loading: () => t.splashInitializing,
            error: (_, _) => t.commonUnknownError,
          ),
        ),
        const SizedBox(height: 12),
        _NavigationRow(
          icon: Icons.qr_code_rounded,
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
