import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class OrderCallingStore {
  Future<List<Map<String, dynamic>>> load();
  Future<void> put(Map<String, dynamic> record);
  Future<void> delete(String id);
}

class HiveOrderCallingStore implements OrderCallingStore {
  Future<Box<String>>? _opening;
  Future<Box<String>> get _box => _opening ??= Hive.openBox<String>(
    'order_calling_outbox_v1',
    compactionStrategy: (entries, deleted) =>
        deleted > 100 && deleted > entries,
  );
  @override
  Future<List<Map<String, dynamic>>> load() async {
    final box = await _box;
    final records = box.values
        .map((raw) => Map<String, dynamic>.from(jsonDecode(raw) as Map))
        .toList();
    records.sort(
      (a, b) => (a['time'] as String).compareTo(b['time'] as String),
    );
    return records;
  }

  @override
  Future<void> put(Map<String, dynamic> record) async {
    final box = await _box;
    await box.put(record['id'] as String, jsonEncode(record));
    await box.flush();
  }

  @override
  Future<void> delete(String id) async {
    final box = await _box;
    await box.delete(id);
    await box.flush();
  }
}

final orderCallingStoreProvider = Provider<OrderCallingStore>(
  (_) => HiveOrderCallingStore(),
);
