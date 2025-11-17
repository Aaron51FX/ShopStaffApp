
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';

final timeProvider = StreamProvider<DateTime>((ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()));

class PosAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PosAppBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(posViewModelProvider.notifier);
    final now = ref.watch(timeProvider).maybeWhen(data: (d) => d, orElse: () => DateTime.now());
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return AppBar(
      toolbarHeight: 64,
      elevation: 6, // stronger shadow
      shadowColor: Colors.grey.withAlpha(100),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.stone500,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          const _LogoAvatar(),
          const Spacer(),
          const SizedBox(width: 14),
          const SizedBox(width: 300,child: _SearchBar(),),
          const SizedBox(width: 16),
          const Spacer(),
          Text(timeStr, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(width: 12),
          IconButton(tooltip: '设置', onPressed: vm.navToSettings, icon: const Icon(Icons.settings_outlined)),
          IconButton(tooltip: '取单', onPressed: vm.navToSuspendedOrder, icon: const Icon(Icons.history_sharp)),
          IconButton(tooltip: '退出', onPressed: vm.logout, icon: const Icon(Icons.exit_to_app)),
        ]),
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
      child: const Text('C', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(posViewModelProvider.notifier);
    return TextField(
      decoration: InputDecoration(
        hintText: "搜索商品 (例如: '拿铁' 或 'nt')",
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.stone400),
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

