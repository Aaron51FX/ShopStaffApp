import 'package:hive_flutter/hive_flutter.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';

class CashRegisterClosureHistoryRecord {
  const CashRegisterClosureHistoryRecord({
    required this.id,
    required this.savedAt,
    required this.summary,
  });

  final String id;
  final DateTime savedAt;
  final CashRegisterClosureSummary summary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'summary': summary.toJson(),
  };

  factory CashRegisterClosureHistoryRecord.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['summary'];
    return CashRegisterClosureHistoryRecord(
      id: (json['id'] ?? '').toString(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['savedAt'] as int?) ?? 0,
      ),
      summary: CashRegisterClosureSummary.fromJson(
        summaryRaw is Map ? Map<String, dynamic>.from(summaryRaw) : const {},
      ),
    );
  }
}

class CashRegisterClosureLocalDataSource {
  static const String boxName = 'cash_register_closure_history';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<List<CashRegisterClosureHistoryRecord>> loadRecent({
    required Duration maxAge,
  }) async {
    final box = await _getBox();
    final cutoff = DateTime.now().subtract(maxAge);
    final records = <CashRegisterClosureHistoryRecord>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) continue;
      final record = CashRegisterClosureHistoryRecord.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (record.savedAt.isBefore(cutoff)) {
        await box.delete(key);
        continue;
      }
      records.add(record);
    }

    records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return records;
  }

  Future<CashRegisterClosureHistoryRecord> save(
    CashRegisterClosureSummary summary,
  ) async {
    final box = await _getBox();
    final savedAt = DateTime.now();
    final id = [
      summary.machineCode,
      summary.startTime,
      summary.endTime,
      savedAt.millisecondsSinceEpoch,
    ].where((part) => part.toString().trim().isNotEmpty).join('|');
    final record = CashRegisterClosureHistoryRecord(
      id: id,
      savedAt: savedAt,
      summary: summary,
    );
    await box.put(id, record.toJson());
    return record;
  }
}
