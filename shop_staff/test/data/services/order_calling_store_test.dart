import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shop_staff/data/services/order_calling_store.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('shopstaff-calling-');
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'calling outbox preserves UUID, target, Unicode and status across restart',
    () async {
      final store = HiveOrderCallingStore();
      await store.put({
        'id': 'order:a',
        'uuid': 'a',
        'time': '2026-10-15T10:00:00',
        'status': 'pending',
        'endpoint': 'http://192.168.1.20:3000/api/add/order',
        'payload': {'name': '奶茶 日本語'},
      });
      await Hive.close();
      final restored = HiveOrderCallingStore();
      final record = (await restored.load()).single;
      expect(record['uuid'], 'a');
      expect(record['payload'], {'name': '奶茶 日本語'});
      await restored.put({...record, 'status': 'sent'});
      expect((await restored.load()).single['status'], 'sent');
      await restored.delete('order:a');
      expect(await restored.load(), isEmpty);
    },
  );
  test(
    'corrupt storage cannot silently reset delivery deduplication',
    () async {
      final box = await Hive.openBox<String>('order_calling_outbox_v1');
      await box.put('broken', 'not json');
      await expectLater(HiveOrderCallingStore().load(), throwsFormatException);
    },
  );
}
