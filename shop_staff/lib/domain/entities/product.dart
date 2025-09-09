import 'package:equatable/equatable.dart';

class OptionChoiceEntity extends Equatable {
  final String code;
  final String name;
  final double extraPrice;
  final bool isDefault;
  const OptionChoiceEntity({
    required this.code,
    required this.name,
    required this.extraPrice,
    required this.isDefault,
  });
  @override
  List<Object?> get props => [code, name, extraPrice, isDefault];
}

class OptionGroupEntity extends Equatable {
  final String groupCode;
  final String groupName;
  final bool multiple; // true => multi select
  final int minSelect;
  final int? maxSelect; // reserve for future (not provided yet)
  final List<OptionChoiceEntity> options;
  const OptionGroupEntity({
    required this.groupCode,
    required this.groupName,
    required this.multiple,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });
  @override
  List<Object?> get props => [groupCode, groupName, multiple, minSelect, maxSelect, options];
}

class Product extends Equatable {
  final int id;
  final String name;
  final String categoryId;
  final double price; // current (effective) price
  final double originalPrice; // original list price
  final int tax; // tax code or percentage basis depending on backend semantics
  final String imageUrl;
  final List<OptionGroupEntity> optionGroups;
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.originalPrice,
    required this.tax,
    required this.imageUrl,
    this.optionGroups = const [],
  });
  bool get isCustomizable => optionGroups.isNotEmpty;
  @override
  List<Object?> get props => [id, name, categoryId, price, originalPrice, tax, imageUrl, optionGroups];
}
