import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/core/router/app_router.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';

class SuspendedOrdersPage extends ConsumerStatefulWidget {
  const SuspendedOrdersPage({super.key});

  @override
  ConsumerState<SuspendedOrdersPage> createState() =>
      _SuspendedOrdersPageState();
}

class _SuspendedOrdersPageState extends ConsumerState<SuspendedOrdersPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posViewModelProvider);
    final orders = [...state.suspended]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filtered = _query.trim().isEmpty
        ? orders
        : orders.where((o) => _match(o, _query)).toList();
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
      title: Text(t.suspendedOrdersTitle),
        backgroundColor: AppColors.amberPrimary,
        foregroundColor: Colors.white,
        leading:
            //back to pos
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                context.pop();
              },
            ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: t.suspendedOrdersSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.stone100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(t.suspendedOrdersEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _OrderTile(order: filtered[i], onResume: _resume),
                  ),
          ),
        ],
      ),
    );
  }

  bool _match(SuspendedOrder order, String q) {
    final qq = q.toLowerCase();
    if (order.id.toLowerCase().contains(qq)) return true;
    for (final item in order.items) {
      if (item.product.name.toLowerCase().contains(qq)) return true;
    }
    return false;
  }

  void _resume(String id) {
    ref.read(posViewModelProvider.notifier).resumeSuspended(id);
    ref.read(appRouterProvider).push('/pos');
  }
}

class _OrderTile extends StatelessWidget {
  final SuspendedOrder order;
  final void Function(String id) onResume;
  const _OrderTile({required this.order, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final formatter = intl.DateFormat(t.suspendedOrdersDatePattern, t.localeName);
    final when = formatter.format(order.createdAt.toLocal());
    final itemCount = order.items.fold<int>(
      0,
      (p, CartItem e) => p + e.quantity,
    );
    final preview = _buildPreview();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ),
              alignment: Alignment.center,
              child: Text(
                order.id,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        when,
                        style: const TextStyle(color: AppColors.stone600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${t.suspendedOrdersItemCountPrefix}$itemCount${t.suspendedOrdersItemCountSuffix}',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${order.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => onResume(order.id),
                  child: Text(t.suspendedOrdersResume),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreview() {
    final names = <String>[];
    for (final item in order.items) {
      final options = item.options.isEmpty
          ? ''
          : '（${item.options.map((o) => '${o.optionName}${o.quantity > 1 ? 'x${o.quantity}' : ''}').join('、')}）';
      names.add(
        '${item.product.name}$options${item.quantity > 1 ? ' x${item.quantity}' : ''}',
      );
      if (names.length >= 3) break; // 预览前三条
    }
    if (order.items.length > 3) names.add('...');
    return names.join('，');
  }
}
