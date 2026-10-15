import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class SsePrintJournal {
  Future<List<Map<String, dynamic>>> load();
  Future<void> save(List<Map<String, dynamic>> records);
}

/// Orders belong in the local database, rather than a growing Keychain value.
class HiveSsePrintJournal implements SsePrintJournal {
  Future<Box<String>>? _opening;
  final Map<String, String> _encoded = {};
  Future<Box<String>> get _box => _opening ??= Hive.openBox<String>(
    'sse_print_journal_v1',
    compactionStrategy: (entries, deleted) =>
        deleted > 100 && deleted > entries,
  );

  @override
  Future<List<Map<String, dynamic>>> load() async {
    final box = await _box;
    _encoded.clear();
    final records = <Map<String, dynamic>>[];
    for (final key in box.keys.cast<String>()) {
      final value = box.get(key)!;
      _encoded[key] = value;
      records.add(Map<String, dynamic>.from(jsonDecode(value) as Map));
    }
    records.sort(
      (a, b) => (a['time'] as String).compareTo(b['time'] as String),
    );
    return records;
  }

  @override
  Future<void> save(List<Map<String, dynamic>> records) async {
    final box = await _box;
    final next = {
      for (final record in records)
        record['uuid'] as String: jsonEncode(record),
    };
    final changed = Map<String, String>.fromEntries(
      next.entries.where((e) => _encoded[e.key] != e.value),
    );
    // Write changed jobs first; only completed jobs are removed by the runtime.
    if (changed.isNotEmpty) await box.putAll(changed);
    final removed = _encoded.keys
        .where((key) => !next.containsKey(key))
        .toList();
    if (removed.isNotEmpty) await box.deleteAll(removed);
    await box.flush();
    _encoded
      ..clear()
      ..addAll(next);
  }
}

final ssePrintJournalProvider = Provider<SsePrintJournal>(
  (_) => HiveSsePrintJournal(),
);
