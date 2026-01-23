import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';

class PosAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PosAppBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final vm = ref.read(posViewModelProvider.notifier);
    final settings = ref.watch(appSettingsSnapshotProvider);
    final peerLinkEnabled = settings?.basic.peerLinkEnabled ?? true;
    return AppBar(
      toolbarHeight: 64,
      elevation: 6, // stronger shadow
      shadowColor: Colors.grey.withAlpha(100),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.stone500,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //const _LogoAvatar(),
            const SizedBox(width: 158),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: const _SearchBar(),
                ),
              ),
            ),
            if (peerLinkEnabled) ...[
              IconButton(
                tooltip: t.posClearCustomerDisplayTooltip,
                onPressed: vm.clearCustomerDisplay,
                icon: const Icon(Icons.close_fullscreen_rounded),
              ),
              IconButton(
                tooltip: t.posBroadcastCategoriesTooltip,
                onPressed: () => vm.broadcastCategories(),
                icon: const Icon(Icons.send_rounded, size: 20, color: AppColors.amberPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar();
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.amberPrimary,
      child: const Text(
        'C',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final vm = ref.read(posViewModelProvider.notifier);
    return TextField(
      decoration: InputDecoration(
        hintText: t.posSearchProductHint,
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.stone400,
        ),
        filled: true,
        fillColor: AppColors.stone100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: AppColors.stone200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: AppColors.stone200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: AppColors.amberPrimary, width: 2),
        ),
      ),
      onChanged: vm.search,
    );
  }
}
