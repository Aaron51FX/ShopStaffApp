import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import '../widgets/cart_panel.dart';
import '../widgets/pos_app_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/side_bar.dart';

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(posViewModelProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.stone100,
      appBar: const PosAppBar(),
      body: Container(
        margin: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CategorySidebar(),
            ProductGrid(onTapProduct: (p) => vm.addProductWithOptions(context, p)),
            CartPanel(
              onEdit: (item) => vm.editCartItemOptions(context, item),
              onCheckout: vm.checkout,
              onSuspend: vm.suspendCurrentOrder,
              onClear: vm.clearCart,
              onDiscount: () async {
                final discount = ref.read(posViewModelProvider.select((s) => s.discount));
                final v = await showDialog<double>(
                  context: context,
                  builder: (ctx) {
                    final controller = TextEditingController(text: discount.toString());
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
      ),
    );
  }
  

  
}



