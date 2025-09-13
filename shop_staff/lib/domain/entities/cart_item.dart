import 'package:equatable/equatable.dart';
import 'product.dart';

class SelectedOption extends Equatable {
  final String groupCode;
  final String groupName;
  final String optionCode;
  final String optionName;
  final double extraPrice;
  final int quantity; // 新增: 该附加项的数量 (>=1)
  const SelectedOption({
    required this.groupCode,
    required this.groupName,
    required this.optionCode,
    required this.optionName,
    required this.extraPrice,
    this.quantity = 1,
  });
  @override
  List<Object?> get props => [groupCode, groupName, optionCode, optionName, extraPrice, quantity];
}

class CartItem extends Equatable {
  final String id; // productId + sorted options key
  final Product product;
  final List<SelectedOption> options;
  final int quantity;
  final String? note; // custom remark

  const CartItem({
    required this.id,
    required this.product,
    required this.options,
    required this.quantity,
    this.note,
  });

  double get unitPrice => product.price + options.fold(0, (p, e) => p + e.extraPrice * e.quantity);
  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({List<SelectedOption>? options, int? quantity, String? id, String? note}) => CartItem(
        id: id ?? this.id,
        product: product,
        options: options ?? this.options,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [id, product, options, quantity, note];
}
