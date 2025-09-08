import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/pos_viewmodel.dart';
import '../viewmodels/pos_state.dart';

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
                        .map((c) => ListTile(
                              title: Text(c),
                              selected: c == pos.currentCategory,
                              onTap: () => vm.selectCategory(c),
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
                                      onTap: () => vm.addProduct(p),
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
                            return ListTile(
                              title: Text(item.product.name),
                              subtitle: Text('单价: ¥${item.unitPrice.toStringAsFixed(2)}'),
                              trailing: SizedBox(
                                width: 140,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
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
