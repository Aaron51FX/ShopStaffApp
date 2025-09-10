

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';

import 'no_scrollbar_behavior.dart';

class CategorySidebar extends ConsumerWidget {
  const CategorySidebar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(posViewModelProvider.select((s) => s.categories));
    final current = ref.watch(posViewModelProvider.select((s) => s.currentCategory));
    final vm = ref.read(posViewModelProvider.notifier);
    return Container(
      width: 200,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
      ]),
      child: ScrollConfiguration(
        behavior: const NoScrollbarBehavior(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          children: [
            for (final cat in categories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: GestureDetector(
                  onTap: () => vm.selectCategory(cat.categoryCode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: cat.categoryCode == current ? AppColors.amberPrimary : AppColors.stone100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cat.categoryName,
                      style: TextStyle(
                        color: cat.categoryCode == current ? Colors.white : AppColors.stone600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

