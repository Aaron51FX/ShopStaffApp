

import 'package:flutter/material.dart';
import 'package:shop_staff/core/ui/app_colors.dart';

class ProductPreviewContent extends StatelessWidget {
  const ProductPreviewContent({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final name = (payload['name'] ?? '') as String? ?? '';
    final price = (payload['price'] as num?)?.toDouble() ?? 0;
    final image = (payload['image'] ?? '') as String? ?? '';
    final quantity = (payload['quantity'] as num?)?.toInt() ?? 1;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          //border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: image.isEmpty
                    ? _placeholder()
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(icon: Icons.broken_image_outlined),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        '¥${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amberPrimary,
                        ),
                      ),
                      
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.amberPrimary.withValues(alpha: 0.12),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Text(
                      //     '数量: $quantity',
                      //     style: const TextStyle(
                      //       fontWeight: FontWeight.w700,
                      //       color: AppColors.amberPrimary,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder({IconData icon = Icons.fastfood_outlined}) => Container(
        color: Colors.grey.shade100,
        child: Icon(icon, size: 48, color: Colors.grey.shade400),
      );
}
