import 'package:flutter/foundation.dart';

@immutable
class SettlementOrder {
  const SettlementOrder({
    required this.orderId,
    required this.totalPrice,
    required this.discount,
    required this.voucherAmount,
    required this.payableAmount,
    required this.tableNum,
    required this.tableNumText,
    required this.orderQty,
    required this.tax1,
    required this.tax2,
    required this.lines,
  });

  final String orderId;
  final int totalPrice;
  final int discount;
  final int voucherAmount;
  final int payableAmount;
  final String tableNum;
  final String tableNumText;
  final int orderQty;
  final int tax1;
  final int tax2;
  final List<SettlementOrderLine> lines;

  factory SettlementOrder.fromJson(Map<String, dynamic> json) {
    return SettlementOrder(
      orderId: (json['orderId'] ?? '').toString(),
      totalPrice: _readInt(json['totalPrice']),
      discount: _readInt(json['discount']),
      voucherAmount: _readInt(json['voucherAmount']),
      payableAmount: _readInt(json['payableAmount']),
      tableNum: (json['tableNum'] ?? '').toString(),
      tableNumText: (json['tableNumText'] ?? '').toString(),
      orderQty: _readInt(json['orderQty']),
      tax1: _readInt(json['tax1']),
      tax2: _readInt(json['tax2']),
      lines:
          (json['orderLines'] as List?)
              ?.whereType<Map>()
              .map(
                (line) => SettlementOrderLine.fromJson(
                  Map<String, dynamic>.from(line),
                ),
              )
              .toList(growable: false) ??
          const [],
    );
  }
}

@immutable
class SettlementOrderLine {
  const SettlementOrderLine({
    required this.categoryName,
    required this.name,
    required this.initialPrice,
    required this.price,
    required this.qty,
    required this.options,
  });

  final String? categoryName;
  final String name;
  final int? initialPrice;
  final int price;
  final int qty;
  final Map<String, List<SettlementOrderOption>> options;

  Iterable<MapEntry<String, SettlementOrderOption>> get flattenedOptions sync* {
    for (final group in options.entries) {
      for (final option in group.value) {
        yield MapEntry(group.key, option);
      }
    }
  }

  factory SettlementOrderLine.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String, List<SettlementOrderOption>>{};
    if (rawOptions is Map) {
      for (final group in rawOptions.entries) {
        final rawItems = group.value;
        if (rawItems is! List) continue;
        options[group.key.toString()] = rawItems
            .whereType<Map>()
            .map(
              (item) => SettlementOrderOption.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      }
    }
    return SettlementOrderLine(
      categoryName: _readOptionalString(json['categoryName']),
      name: (json['name'] ?? '').toString(),
      initialPrice: _readNullableInt(json['initialPrice']),
      price: _readInt(json['price']),
      qty: _readInt(json['qty']),
      options: Map.unmodifiable(options),
    );
  }
}

@immutable
class SettlementOrderOption {
  const SettlementOrderOption({
    required this.name,
    required this.price,
    required this.qty,
    required this.totalPrice,
  });

  final String name;
  final int price;
  final int qty;
  final int? totalPrice;

  int get displayTotal => totalPrice ?? price * qty;

  factory SettlementOrderOption.fromJson(Map<String, dynamic> json) {
    return SettlementOrderOption(
      name: (json['name'] ?? '').toString(),
      price: _readInt(json['price']),
      qty: _readInt(json['qty']),
      totalPrice: _readNullableInt(json['totalPrice']),
    );
  }
}

int _readInt(Object? value) => _readNullableInt(value) ?? 0;

int? _readNullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _readOptionalString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
