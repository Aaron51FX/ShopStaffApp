import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_state.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PosState pos = ref.watch(posViewModelProvider);
    final vm = ref.read(posViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('订单号 #${pos.orderNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.clearCart,
            tooltip: '清空',
          ),
          PopupMenuButton<String>(
            tooltip: '挂单/取单',
            onSelected: (val) {
              if (val == 'suspend') vm.suspendCurrentOrder();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'suspend', child: Text('挂单 (保存当前)')),
              if (pos.suspended.isNotEmpty) const PopupMenuDivider(),
              ...pos.suspended.map((o) => PopupMenuItem(
                    value: o.id,
                    child: Text('取单 ${o.id}  ¥${o.subtotal.toStringAsFixed(0)}'),
                    onTap: () => vm.resumeSuspended(o.id),
                  )),
            ],
          )
        ],
      ),
      body: pos.loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Categories
                SizedBox(
                  width: 140,
                  child: ListView(
                    children: pos.categories
                        .map((cat) => ListTile(
                              title: Text(cat.categoryName),
                              selected: cat.categoryCode == pos.currentCategory,
                              onTap: () => vm.selectCategory(cat.categoryCode),
                            ))
                        .toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Products
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '搜索商品'),
                          onChanged: vm.search,
                        ),
                      ),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          children: pos.products
                              .map((p) => Card(
                                    child: InkWell(
                                      onTap: () => _handleAddProduct(context, vm, p),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text('¥${p.price.toStringAsFixed(2)}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Cart
                Expanded(
                  child: Column(
                    children: [
                      const ListTile(title: Text('购物车')),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pos.cart.length,
                          itemBuilder: (context, index) {
                            final item = pos.cart[index];
                            return InkWell(
                              onLongPress: () => _showEditOptionsDialog(context, vm, item),
                              child: ListTile(
                                title: Text(item.product.name),
                                subtitle: Text('单价: ¥${item.unitPrice.toStringAsFixed(2)}'),
                                trailing: SizedBox(
                                  width: 176,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_outlined),
                                        tooltip: '编辑选项',
                                        onPressed: () => _showEditOptionsDialog(context, vm, item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => vm.changeQuantity(item.id, -1),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => vm.changeQuantity(item.id, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('小计: ¥${pos.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: pos.cart.isEmpty ? null : vm.checkout,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('结账'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: pos.cart.isEmpty ? null : vm.suspendCurrentOrder,
                              icon: const Icon(Icons.pause_circle_outline),
                              label: const Text('挂单'),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

void _handleAddProduct(BuildContext context, PosViewModel vm, Product p) {
  if (!p.isCustomizable) {
    vm.addProduct(p);
    return;
  }
  _showOptionSelectDialog(context, vm, p);
}

void _showEditOptionsDialog(BuildContext context, PosViewModel vm, CartItem item) {
  final product = item.product;
  if (!product.isCustomizable) return; // nothing to edit
  _showOptionSelectDialog(context, vm, product, existing: item);
}

void _showOptionSelectDialog(BuildContext context, PosViewModel vm, Product product, {CartItem? existing}) {
  final selected = <String, Set<String>>{}; // groupCode -> optionCodes
  if (existing != null) {
    for (final o in existing.options) {
      selected.putIfAbsent(o.groupCode, () => <String>{}).add(o.optionCode);
    }
  } else {
    // preselect defaults
    for (final g in product.optionGroups) {
      final defaults = g.options.where((o) => o.isDefault).toList();
      if (defaults.isNotEmpty) {
        selected[g.groupCode] = defaults.map((e) => e.code).toSet();
      }
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      for (final group in product.optionGroups) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final opt in group.options)
                              FilterChip(
                                label: Text('${opt.name}${opt.extraPrice > 0 ? ' +${opt.extraPrice}' : ''}'),
                                selected: selected[group.groupCode]?.contains(opt.code) ?? false,
                                onSelected: (sel) {
                                  setState(() {
                                    final set = selected.putIfAbsent(group.groupCode, () => <String>{});
                                    final multiple = group.multiple;
                                    if (!multiple) {
                                      set.clear();
                                      if (sel) {
                                        set.add(opt.code);
                                      } else {
                                        set.remove(opt.code);
                                      }
                                    } else {
                                      if (sel) {
                                        set.add(opt.code);
                                      } else {
                                        set.remove(opt.code);
                                      }
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
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
                        child: Text(existing == null ? '添加' : '更新'),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      });
    },
  );
}
