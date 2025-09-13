

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/presentations/pos/viewmodels/pos_viewmodel.dart';
import 'package:shop_staff/presentations/pos/widgets/no_scrollbar_behavior.dart';

class ProductGrid extends ConsumerWidget {
  final void Function(Product) onTapProduct;
  const ProductGrid({super.key, required this.onTapProduct});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final products = ref.watch(posViewModelProvider.select((s) => s.products));
  final loading = ref.watch(posViewModelProvider.select((s) => s.loading));
    final favorites = ref.watch(posViewModelProvider.select((s) => s.favoriteProductIds));
    final vm = ref.read(posViewModelProvider.notifier);
    return Expanded(
      flex: 5,
      child: Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            int crossAxis = 3;
            final w = constraints.maxWidth;
            if (w >= 1800) {
              crossAxis = 6;
            } else if (w >= 1400) {
              crossAxis = 5;
            } else if (w >= 1100) {
              crossAxis = 4;
            } else if (w >= 820) {
              crossAxis = 3;
            }
            return RepaintBoundary(
              child: ScrollConfiguration(
                behavior: const NoScrollbarBehavior(),
                child: Stack(children: [
                  GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final fav = favorites.contains(p.id);
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onTapProduct(p),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image area
                            AspectRatio(
                              aspectRatio: 1.5,
                              child: _ProductImage(url: p.imageUrl),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => vm.toggleFavorite(p),
                                          child: Icon(
                                            fav ? Icons.favorite : Icons.favorite_border,
                                            color: fav ? Colors.redAccent : AppColors.stone400,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      '¥${p.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.amberPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                  if (loading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.white.withAlpha(153),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;
  const _ProductImage({required this.url});
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (c, e, st) => _placeholder(icon: Icons.broken_image_outlined),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            _placeholder(),
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placeholder({IconData icon = Icons.image_outlined}) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Icon(icon, size: 36, color: Colors.grey.shade400),
      );
}