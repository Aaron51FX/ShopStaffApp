import 'dart:convert';

import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/domain/entities/product.dart';

abstract class PosFavoritesStore {
  Future<List<Product>> load();

  Future<void> save(Iterable<Product> products);
}

class KeyValuePosFavoritesStore implements PosFavoritesStore {
  const KeyValuePosFavoritesStore(this._store);

  final KeyValueStore _store;

  @override
  Future<List<Product>> load() async {
    final raw = await _store.read(AppStorageKeys.posFavoriteProducts);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => _productFromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(Iterable<Product> products) {
    final payload = jsonEncode(products.map(_productToJson).toList());
    return _store.write(AppStorageKeys.posFavoriteProducts, payload);
  }

  Map<String, dynamic> _productToJson(Product product) {
    return <String, dynamic>{
      'id': product.id,
      'name': product.name,
      'categoryId': product.categoryId,
      'price': product.price,
      'originalPrice': product.originalPrice,
      'tax': product.tax,
      'imageUrl': product.imageUrl,
      'optionGroups': product.optionGroups.map(_optionGroupToJson).toList(),
    };
  }

  Map<String, dynamic> _optionGroupToJson(OptionGroupEntity group) {
    return <String, dynamic>{
      'groupCode': group.groupCode,
      'groupName': group.groupName,
      'multiple': group.multiple,
      'minSelect': group.minSelect,
      'maxSelect': group.maxSelect,
      'options': group.options.map(_optionToJson).toList(),
    };
  }

  Map<String, dynamic> _optionToJson(OptionChoiceEntity option) {
    return <String, dynamic>{
      'code': option.code,
      'name': option.name,
      'extraPrice': option.extraPrice,
      'isDefault': option.isDefault,
    };
  }

  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      tax: (json['tax'] as num).toInt(),
      imageUrl: json['imageUrl'] as String,
      optionGroups: (json['optionGroups'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _optionGroupFromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  OptionGroupEntity _optionGroupFromJson(Map<String, dynamic> json) {
    return OptionGroupEntity(
      groupCode: json['groupCode'] as String,
      groupName: json['groupName'] as String,
      multiple: json['multiple'] as bool,
      minSelect: (json['minSelect'] as num).toInt(),
      maxSelect: (json['maxSelect'] as num?)?.toInt(),
      options: (json['options'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _optionFromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  OptionChoiceEntity _optionFromJson(Map<String, dynamic> json) {
    return OptionChoiceEntity(
      code: json['code'] as String,
      name: json['name'] as String,
      extraPrice: (json['extraPrice'] as num).toDouble(),
      isDefault: json['isDefault'] as bool,
    );
  }
}
