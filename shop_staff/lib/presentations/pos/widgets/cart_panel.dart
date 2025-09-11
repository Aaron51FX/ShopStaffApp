

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/presentations/pos/widgets/no_scrollbar_behavior.dart';

import 'primary_button.dart';

class CartPanel extends ConsumerWidget {
  final void Function(CartItem) onEdit; 
  final VoidCallback onCheckout;
  final VoidCallback onSuspend;
  final VoidCallback onClear;
  final Future<void> Function() onDiscount;
  const CartPanel({super.key, required this.onEdit, required this.onCheckout, required this.onSuspend, required this.onClear, required this.onDiscount});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final orderNumber = ref.watch(posViewModelProvider.select((s) => s.orderNumber));
  final orderMode = ref.watch(posViewModelProvider.select((s) => s.orderMode));
  final cart = ref.watch(posViewModelProvider.select((s) => s.cart));
  final subtotal = ref.watch(posViewModelProvider.select((s) => s.subtotal));
  final discount = ref.watch(posViewModelProvider.select((s) => s.discount));
  final total = ref.watch(posViewModelProvider.select((s) => s.total));
    final vm = ref.read(posViewModelProvider.notifier);
    return Container(
      width: 360,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
      ]),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Text('订单号:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('#$orderNumber', style: const TextStyle(color: AppColors.amberPrimary, fontWeight: FontWeight.bold)),
            const Spacer(),
            ToggleButtons(
              constraints: const BoxConstraints(minHeight: 32, minWidth: 54),
              borderRadius: BorderRadius.circular(10),
              isSelected: [orderMode == 'dine_in', orderMode == 'take_out'],
              selectedColor: Colors.white,
              fillColor: AppColors.amberPrimary,
              color: AppColors.stone500,
              onPressed: (i) {
                final target = i == 0 ? 'dine_in' : 'take_out';
                if (target != orderMode) vm.switchOrderMode();
              },
              children: const [Text('堂食'), Text('外带')],
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: RepaintBoundary(
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: cart.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('购物车是空的\n请从左侧选择商品', textAlign: TextAlign.center, style: TextStyle(color: AppColors.stone400)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        final optionText = item.options.isNotEmpty ? item.options.map((o) => o.optionName).join(', ') : '';
                        return KeyedSubtree(
                          key: ValueKey(item.id),
                          child: InkWell(
                            onLongPress: () => onEdit(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (optionText.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(optionText, style: const TextStyle(fontSize: 11, color: AppColors.stone500)),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text('¥${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.amberPrimary)),
                                    ),
                                  ]),
                                ),
                                Column(children: [
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    _QtyBtn(icon: Icons.remove, onTap: () => vm.changeQuantity(item.id, -1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    _QtyBtn(icon: Icons.add, onTap: () => vm.changeQuantity(item.id, 1)),
                                  ]),
                                  GestureDetector(
                                    onTap: () => onEdit(item),
                                    child: const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Icon(Icons.edit_note_outlined, size: 18, color: AppColors.stone400),
                                    ),
                                  ),
                                ]),
                                SizedBox(
                                  width: 60,
                                  child: Text('¥${item.lineTotal.toStringAsFixed(2)}', textAlign: TextAlign.end, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            _SummaryRow(label: '小计', value: '¥${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _SummaryRow(label: '折扣', value: '-¥${discount.toStringAsFixed(2)}', onTap: cart.isEmpty ? null : onDiscount),
            const Divider(height: 24),
            _SummaryRow(label: '应付总额', value: '¥${total.toStringAsFixed(2)}', emphasized: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PrimaryButton(label: '挂单', onTap: cart.isEmpty ? null : onSuspend, color: AppColors.stone200, textColor: AppColors.stone600)),
              const SizedBox(width: 8),
              Expanded(child: PrimaryButton(label: '折扣', onTap: cart.isEmpty ? null : () => onDiscount(), color: AppColors.stone200, textColor: AppColors.stone600)),
              const SizedBox(width: 8),
              Expanded(child: PrimaryButton(label: '清空', onTap: cart.isEmpty ? null : onClear, color: Colors.red.shade100, textColor: Colors.red.shade700)),
            ]),
            const SizedBox(height: 8),
            PrimaryButton(label: '结 账', onTap: cart.isEmpty ? null : onCheckout, color: AppColors.emerald600, textColor: Colors.white, height: 52),
          ]),
        )
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label; final String value; final bool emphasized; final Future<void> Function()? onTap;
  const _SummaryRow({required this.label, required this.value, this.emphasized = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final style = emphasized ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold) : const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final row = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style.copyWith(color: emphasized ? AppColors.amberPrimary : null))]);
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: AppColors.stone600),
      ),
    );
  }
}

