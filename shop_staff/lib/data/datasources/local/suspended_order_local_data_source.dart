import 'package:hive_flutter/hive_flutter.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';

class SuspendedOrderLocalDataSource {
  static const String boxName = 'suspended_orders';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<List<SuspendedOrder>> loadAll() async {
    final box = await _getBox();
    final list = <SuspendedOrder>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        list.add(_fromMap(Map<String, dynamic>.from(raw)));
      }
    }
    // sort by createdAt asc
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> save(SuspendedOrder order) async {
    final box = await _getBox();
    await box.put(order.id, _toMap(order));
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Map<String, dynamic> _toMap(SuspendedOrder o) => {
        'id': o.id,
        'subtotal': o.subtotal,
        'createdAt': o.createdAt.millisecondsSinceEpoch,
        'items': o.items.map(_cartItemToMap).toList(),
      };

  SuspendedOrder _fromMap(Map<String, dynamic> m) => SuspendedOrder(
        id: m['id'] as String,
        subtotal: (m['subtotal'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        items: (m['items'] as List)
            .whereType<Map>()
            .map((e) => _cartItemFromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> _cartItemToMap(CartItem c) => {
        'id': c.id,
        'quantity': c.quantity,
        'note': c.note,
        'product': {
          'id': c.product.id,
          'name': c.product.name,
          'categoryId': c.product.categoryId,
          'price': c.product.price,
          'originalPrice': c.product.originalPrice,
          'tax': c.product.tax,
          'imageUrl': c.product.imageUrl,
        },
        'options': c.options
            .map((o) => {
                  'groupCode': o.groupCode,
                  'groupName': o.groupName,
                  'optionCode': o.optionCode,
                  'optionName': o.optionName,
                  'extraPrice': o.extraPrice,
                  'quantity': o.quantity,
                })
            .toList(),
      };

  CartItem _cartItemFromMap(Map<String, dynamic> m) => CartItem(
        id: m['id'] as String,
        quantity: m['quantity'] as int,
        note: m['note'] as String?,
        product: Product(
          id: m['product']['id'] as int,
          name: m['product']['name'] as String,
          categoryId: m['product']['categoryId'] as String,
          price: (m['product']['price'] as num).toDouble(),
          originalPrice: (m['product']['originalPrice'] as num).toDouble(),
          tax: m['product']['tax'] as int,
          imageUrl: m['product']['imageUrl'] as String,
          optionGroups: const [],
        ),
        options: (m['options'] as List)
            .whereType<Map>()
            .map((e) => SelectedOption(
                  groupCode: e['groupCode'] as String,
                  groupName: e['groupName'] as String,
                  optionCode: e['optionCode'] as String,
                  optionName: e['optionName'] as String,
                  extraPrice: (e['extraPrice'] as num).toDouble(),
                  quantity: (e['quantity'] as num).toInt(),
                ))
            .toList(),
      );
}