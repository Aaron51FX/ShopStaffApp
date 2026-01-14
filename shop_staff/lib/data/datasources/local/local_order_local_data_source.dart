import 'package:hive_flutter/hive_flutter.dart';

import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';

class LocalOrderLocalDataSource {
  static const String boxName = 'local_orders';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<List<LocalOrderRecord>> loadAll() async {
    final box = await _getBox();
    final list = <LocalOrderRecord>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        list.add(_fromMap(Map<String, dynamic>.from(raw)));
      }
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<LocalOrderRecord?> getById(String orderId) async {
    final box = await _getBox();
    final raw = box.get(orderId);
    if (raw is Map) {
      return _fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> save(LocalOrderRecord record) async {
    final box = await _getBox();
    await box.put(record.orderId, _toMap(record));
  }

  Future<void> updatePaid(String orderId, bool isPaid) async {
    final existing = await getById(orderId);
    if (existing == null) return;
    await save(existing.copyWith(isPaid: isPaid));
  }

  Future<void> delete(String orderId) async {
    final box = await _getBox();
    await box.delete(orderId);
  }

  Map<String, dynamic> _toMap(LocalOrderRecord o) => {
        'orderId': o.orderId,
        'createdAt': o.createdAt.millisecondsSinceEpoch,
        'isPaid': o.isPaid,
        'machineCode': o.machineCode,
        'language': o.language,
        'takeout': o.takeout,
        'discount': o.discount,
        'clientTotal': o.clientTotal,
        'items': o.items.map(_cartItemToMap).toList(),
        'orderResult': _orderResultToMap(o.orderResult),
      };

  LocalOrderRecord _fromMap(Map<String, dynamic> m) {
    final orderResultRaw = m['orderResult'];
    final orderResultMap = orderResultRaw is Map
        ? Map<String, dynamic>.from(orderResultRaw)
        : <String, dynamic>{};

    return LocalOrderRecord(
      orderId: (m['orderId'] ?? '').toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as int?) ?? 0),
      isPaid: (m['isPaid'] as bool?) ?? false,
      machineCode: (m['machineCode'] ?? '').toString(),
      language: (m['language'] ?? '').toString(),
      takeout: (m['takeout'] as bool?) ?? false,
      discount: ((m['discount'] as num?) ?? 0).toDouble(),
      clientTotal: ((m['clientTotal'] as num?) ?? 0).toDouble(),
      items: (m['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => _cartItemFromMap(Map<String, dynamic>.from(e)))
          .toList(),
      orderResult: OrderSubmissionResult.fromJson(orderResultMap),
    );
  }

  Map<String, dynamic> _orderResultToMap(OrderSubmissionResult r) => {
        'orderId': r.orderId,
        'tax1': r.tax1,
        'baseTax1': r.baseTax1,
        'tax2': r.tax2,
        'baseTax2': r.baseTax2,
        'total': r.total,
        'message': r.message,
        'menuLackMap': r.menuLackMap,
      };

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
        id: (m['id'] ?? '').toString(),
        quantity: (m['quantity'] as int?) ?? 0,
        note: m['note'] as String?,
        product: Product(
          id: (m['product']['id'] as num).toInt(),
          name: (m['product']['name'] ?? '').toString(),
          categoryId: (m['product']['categoryId'] ?? '').toString(),
          price: (m['product']['price'] as num).toDouble(),
          originalPrice: (m['product']['originalPrice'] as num).toDouble(),
          tax: (m['product']['tax'] as num).toInt(),
          imageUrl: (m['product']['imageUrl'] ?? '').toString(),
          optionGroups: const [],
        ),
        options: (m['options'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => SelectedOption(
                  groupCode: (e['groupCode'] ?? '').toString(),
                  groupName: (e['groupName'] ?? '').toString(),
                  optionCode: (e['optionCode'] ?? '').toString(),
                  optionName: (e['optionName'] ?? '').toString(),
                  extraPrice: ((e['extraPrice'] as num?) ?? 0).toDouble(),
                  quantity: ((e['quantity'] as num?) ?? 1).toInt(),
                ))
            .toList(),
      );
}
