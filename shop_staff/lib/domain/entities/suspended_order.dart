import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class SuspendedOrder extends Equatable {
  final String id; // e.g. S0001
  final List<CartItem> items;
  final double subtotal;
  final DateTime createdAt;
  const SuspendedOrder({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, items, subtotal, createdAt];
}