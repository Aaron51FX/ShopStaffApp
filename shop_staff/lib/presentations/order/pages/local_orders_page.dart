import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:shop_staff/application/order/usecases/order_reprint_usecase.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/presentations/order/viewmodels/local_orders_viewmodel.dart';

class LocalOrdersPage extends ConsumerWidget {
  const LocalOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(localOrdersViewModelProvider.notifier);
    final state = ref.watch(localOrdersViewModelProvider);
    final orders = vm.filtered;

    final selected = vm.selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史订单'),
        backgroundColor: AppColors.amberPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => vm.load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索 按编号或商品名',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.stone100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: vm.setQuery,
            ),
          ),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(child: Text(state.error!)),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hasSelection = selected != null;
                  final panelWidth = hasSelection ? constraints.maxWidth * 0.30 : 0.0;
                  return Row(
                    children: [
                      Expanded(
                        child: orders.isEmpty
                            ? const Center(child: Text('暂无历史订单'))
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                itemCount: orders.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final order = orders[i];
                                  final isSelected = order.orderId == state.selectedOrderId;
                                  return _OrderTile(
                                    order: order,
                                    selected: isSelected,
                                    preview: vm.preview(order),
                                    itemCount: vm.itemCount(order),
                                    onTap: () => vm.selectOrder(order.orderId),
                                  );
                                },
                              ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: panelWidth,
                        child: panelWidth <= 0
                            ? const SizedBox.shrink()
                            : _OrderDetailsPanel(
                                order: selected!,
                                onClose: () => vm.selectOrder(null),
                                onPrintReceipt: () => _printReceipt(context, ref, selected),
                                onPrintKitchenTickets: () =>
                                    _printKitchenTickets(context, ref, selected),
                                onReorder: () => _reorder(context, ref, selected),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.selected,
    required this.preview,
    required this.itemCount,
    required this.onTap,
  });

  final LocalOrderRecord order;
  final bool selected;
  final String preview;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = intl.DateFormat('MM-dd HH:mm');
    final when = formatter.format(order.createdAt.toLocal());

    return Card(
      elevation: selected ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? Border.all(color: AppColors.amberPrimary, width: 2)
                      : Border.all(color: AppColors.stone200),
                ),
                alignment: Alignment.center,
                child: Text(
                  //orderId 取后6位
                  order.orderId.length <= 6
                      ? order.orderId
                      : order.orderId.substring(order.orderId.length - 6),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          when,
                          style: const TextStyle(color: AppColors.stone600),
                        ),
                        Text(
                          '共$itemCount件',
                          style: const TextStyle(color: AppColors.stone600),
                        ),
                        Text(
                          order.isPaid ? '已支付' : '未支付',
                          style: TextStyle(
                            color: order.isPaid ? AppColors.emerald600 : AppColors.stone600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (order.payMethod.isNotEmpty)
                          Text(
                            order.payMethod,
                            style: const TextStyle(color: AppColors.stone600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '¥${order.clientTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsPanel extends StatelessWidget {
  const _OrderDetailsPanel({
    required this.order,
    required this.onClose,
    required this.onPrintReceipt,
    required this.onPrintKitchenTickets,
    required this.onReorder,
  });

  final LocalOrderRecord order;
  final VoidCallback onClose;
  final Future<void> Function() onPrintReceipt;
  final Future<void> Function() onPrintKitchenTickets;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final formatter = intl.DateFormat('yyyy-MM-dd HH:mm:ss');
    final when = formatter.format(order.createdAt.toLocal());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.stone200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '订单详情',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _kv('订单号', order.orderId),
                _kv('时间', when),
                _kv('状态', order.isPaid ? '已支付' : '未支付'),
                _kv('支付方式', order.payMethod.isNotEmpty ? order.payMethod : '未知'),
                _kv('金额', '¥${order.clientTotal.toStringAsFixed(2)}'),
                _kv('模式', order.takeout ? '外带' : '堂食'),
                _kv('商品数', order.items.length.toString()),
                const SizedBox(height: 12),
                const Text(
                  '商品',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${e.product.name}  x${e.quantity}',
                      style: const TextStyle(color: AppColors.stone600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onReorder,
                  child: const Text('再次下单(取单)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onPrintReceipt,
                  child: const Text('打印 receipt'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onPrintKitchenTickets,
                  child: const Text('打印厨房票'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: const TextStyle(color: AppColors.stone600),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _printReceipt(
  BuildContext context,
  WidgetRef ref,
  LocalOrderRecord order,
) async {
  final useCase = ref.read(orderReprintUseCaseProvider);
  final result = await useCase.reprintReceipt(order);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.message)),
  );
}

void _reorder(
  BuildContext context,
  WidgetRef ref,
  LocalOrderRecord order,
) {
  // Populate POS cart and navigate back to POS page.
  final posVm = ref.read(posViewModelProvider.notifier);
  posVm.loadFromLocalOrder(order);
  context.push('/pos');
}

Future<void> _printKitchenTickets(
  BuildContext context,
  WidgetRef ref,
  LocalOrderRecord order,
) async {
  final useCase = ref.read(orderReprintUseCaseProvider);
  final result = await useCase.reprintKitchenTickets(order);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.message)),
  );
}
