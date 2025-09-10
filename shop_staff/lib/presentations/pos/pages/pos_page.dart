import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_state.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/presentations/pos/widgets/primary_button.dart';
import '../widgets/cart_panel.dart';
import '../widgets/pos_app_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/side_bar.dart';

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PosState pos = ref.watch(posViewModelProvider);
    final vm = ref.read(posViewModelProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.stone100,
      appBar: const PosAppBar(),
      body: pos.loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CategorySidebar(),
                ProductGrid(onTapProduct: (p) => _handleAddProduct(context, vm, p)),
                CartPanel(
                  onEdit: (item) => _showEditOptionsDialog(context, vm, item),
                  onCheckout: vm.checkout,
                  onSuspend: vm.suspendCurrentOrder,
                  onClear: vm.clearCart,
                  onDiscount: () async {
                    final v = await showDialog<double>(
                      context: context,
                      builder: (ctx) {
                        final controller = TextEditingController(text: pos.discount.toString());
                        return AlertDialog(
                          title: const Text('输入折扣金额'),
                          content: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                            ElevatedButton(
                              onPressed: () {
                                final parsed = double.tryParse(controller.text) ?? 0;
                                Navigator.pop(ctx, parsed);
                              },
                              child: const Text('确定'),
                            )
                          ],
                        );
                      },
                    );
                    if (v != null) vm.applyDiscount(v);
                  },
                ),
              ],
            ),
    );
  }
}

// === Option Dialog Logic ===
void _handleAddProduct(BuildContext context, PosViewModel vm, Product p) {
  if (!p.isCustomizable) {
    vm.addProduct(p);
    return;
  }
  _showOptionSelectDialog(context, vm, p);
}

void _showEditOptionsDialog(BuildContext context, PosViewModel vm, CartItem item) {
  final product = item.product;
  if (!product.isCustomizable) return;
  _showOptionSelectDialog(context, vm, product, existing: item);
}

void _showOptionSelectDialog(BuildContext context, PosViewModel vm, Product product, {CartItem? existing}) {
  final selected = <String, Set<String>>{}; // groupCode -> optionCodes
  if (existing != null) {
    for (final o in existing.options) {
      selected.putIfAbsent(o.groupCode, () => <String>{}).add(o.optionCode);
    }
  } else {
    for (final g in product.optionGroups) {
      final defaults = g.options.where((o) => o.isDefault).toList();
      if (defaults.isNotEmpty) {
        selected[g.groupCode] = defaults.map((e) => e.code).toSet();
      }
    }
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'options',
    barrierColor: Colors.black.withAlpha(115),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: Center(
            child: StatefulBuilder(builder: (ctx, setState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(color: AppColors.amberPrimary),
                        child: Row(children: [
                          Expanded(
                            child: Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(ctx).pop())
                        ]),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            for (final group in product.optionGroups) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4),
                                child: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final opt in group.options)
                                    _OptionChip(
                                      label: opt.name,
                                      extra: opt.extraPrice,
                                      selected: selected[group.groupCode]?.contains(opt.code) ?? false,
                                      onTap: () {
                                        setState(() {
                                          final set = selected.putIfAbsent(group.groupCode, () => <String>{});
                                          if (!group.multiple) {
                                            set.clear();
                                            set.add(opt.code);
                                          } else {
                                            if (!set.add(opt.code)) set.remove(opt.code);
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const Divider(height: 28),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: const BoxDecoration(color: AppColors.stone100),
                        child: Row(children: [
                          Expanded(
                            child: PrimaryButton(
                              label: existing == null ? '确认添加' : '更新',
                              onTap: () {
                                final selectedOptions = <SelectedOption>[];
                                for (final g in product.optionGroups) {
                                  final codes = selected[g.groupCode] ?? {};
                                  for (final code in codes) {
                                    final opt = g.options.firstWhere((o) => o.code == code);
                                    selectedOptions.add(SelectedOption(
                                      groupCode: g.groupCode,
                                      groupName: g.groupName,
                                      optionCode: opt.code,
                                      optionName: opt.name,
                                      extraPrice: opt.extraPrice,
                                    ));
                                  }
                                }
                                if (existing != null) {
                                  vm.updateCartItemOptions(oldId: existing.id, product: product, newOptions: selectedOptions);
                                } else {
                                  vm.addProduct(product, options: selectedOptions);
                                }
                                Navigator.of(ctx).pop();
                              },
                              color: AppColors.amberPrimary,
                              textColor: Colors.white,
                              height: 48,
                            ),
                          ),
                        ]),
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      );
    },
  );
}

class _OptionChip extends StatelessWidget {
  final String label; final double extra; final bool selected; final VoidCallback onTap;
  const _OptionChip({required this.label, required this.extra, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.amberPrimary : AppColors.stone100;
    final fg = selected ? Colors.white : AppColors.stone600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColors.amberPrimary : AppColors.stone300),
        ),
        child: Text(
          extra > 0 ? '$label +${extra.toStringAsFixed(0)}' : label,
          style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}


