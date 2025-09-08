import 'package:equatable/equatable.dart';

class ProductOptionItem extends Equatable {
  final String name;
  final double extraPrice;
  const ProductOptionItem({required this.name, required this.extraPrice});
  @override
  List<Object?> get props => [name, extraPrice];
}

enum ProductOptionType { radio, checkbox }

class ProductOptionGroup extends Equatable {
  final String groupName;
  final ProductOptionType type;
  final List<ProductOptionItem> items;
  const ProductOptionGroup({
    required this.groupName,
    required this.type,
    required this.items,
  });
  @override
  List<Object?> get props => [groupName, type, items];
}

class Product extends Equatable {
  final int id;
  final String name;
  final String categoryId;
  final double price;
  final String imageUrl;
  final List<ProductOptionGroup> optionGroups;
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.imageUrl,
    this.optionGroups = const [],
  });
  bool get isCustomizable => optionGroups.isNotEmpty;
  @override
  List<Object?> get props => [id, name, categoryId, price, imageUrl, optionGroups];
}
