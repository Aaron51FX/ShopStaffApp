import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shop_staff/data/services/sse_print_journal.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'shop-staff-sse-journal-',
    );
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('journal persists updates and pruning across reopen', () async {
    final journal = HiveSsePrintJournal();
    await journal.load();
    await journal.save([
      {
        'uuid': 'a',
        'time': '2026-10-15T10:00:00',
        'status': 'sending',
        'data': {'name': '日本語'},
      },
      {'uuid': 'b', 'time': '2026-10-15T11:00:00', 'status': 'sent'},
    ]);
    await journal.save([
      {
        'uuid': 'a',
        'time': '2026-10-15T10:00:00',
        'status': 'uncertain',
        'data': {'name': '日本語'},
      },
    ]);
    await Hive.close();
    final restored = await HiveSsePrintJournal().load();
    expect(restored, hasLength(1));
    expect(restored.single['status'], 'uncertain');
    expect(restored.single['data'], {'name': '日本語'});
  });

  test(
    'corrupt journal fails explicitly instead of clearing deduplication',
    () async {
      final box = await Hive.openBox<String>('sse_print_journal_v1');
      await box.put('broken', 'not JSON');
      expect(HiveSsePrintJournal().load(), throwsFormatException);
    },
  );
}
