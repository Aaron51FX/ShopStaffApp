import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/order_calling/order_calling_controller.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/services/order_calling_store.dart';
import 'package:shop_staff/data/services/order_calling_transport.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/settings/pages/order_calling_settings_page.dart';

class _SettingsStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<bool> contains(String key) async => values.containsKey(key);
  @override
  Future<void> clearAll() async {
    values.clear();
  }
}

class _Outbox implements OrderCallingStore {
  final records = <String, Map<String, dynamic>>{};
  bool fail = false;
  @override
  Future<List<Map<String, dynamic>>> load() async =>
      records.values.map((r) => {...r}).toList();
  @override
  Future<void> put(Map<String, dynamic> record) async {
    if (fail) throw StateError('disk full');
    records[record['id'] as String] = {...record};
  }

  @override
  Future<void> delete(String id) async {
    records.remove(id);
  }
}

class _Transport implements OrderCallingTransport {
  final calls = <Map<String, dynamic>>[];
  Completer<void>? blocked;
  bool fail = false;
  @override
  Future<void> send(Uri endpoint, Map<String, dynamic> payload) async {
    calls.add({'endpoint': endpoint.toString(), 'payload': payload});
    if (fail) throw TimeoutException('unknown result');
    if (blocked != null) await blocked!.future;
  }

  @override
  void close() {}
}

void main() {
  late _SettingsStore settings;
  late _Outbox outbox;
  late _Transport transport;
  late OrderCallingController controller;
  Future<void> settle() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> enqueue(String uuid) => controller.enqueueOrder({
    'uuid': uuid,
    'orderLinesMap': {},
  }, source: 'local');
  setUp(() async {
    settings = _SettingsStore();
    outbox = _Outbox();
    transport = _Transport();
    controller = OrderCallingController(
      settingsStore: settings,
      outbox: outbox,
      transport: transport,
    );
    await controller.initialize();
  });
  tearDown(() => controller.dispose());
  Future<void> enable() => controller
      .saveSettings(
        const OrderCallingSettings(enabled: true, ip: '192.168.1.20'),
      )
      .then((_) {});

  test('disabled service neither queues nor sends', () async {
    await enqueue('a');
    await settle();
    expect(outbox.records, isEmpty);
    expect(transport.calls, isEmpty);
  });
  test(
    'delivery persists payload and deduplicates UUID across restart',
    () async {
      await enable();
      await enqueue('a');
      await enqueue('a');
      await settle();
      expect(transport.calls, hasLength(1));
      expect(
        transport.calls.single['endpoint'],
        'http://192.168.1.20:3000/api/add/order',
      );
      expect(outbox.records.values.single['status'], 'sent');
      controller.dispose();
      controller = OrderCallingController(
        settingsStore: settings,
        outbox: outbox,
        transport: transport,
      );
      await controller.initialize();
      await enqueue('a');
      await settle();
      expect(transport.calls, hasLength(1));
    },
  );
  test(
    'enqueue does not wait for a blocked network; disabling stops subsequent delivery',
    () async {
      await enable();
      transport.blocked = Completer<void>();
      await enqueue('a');
      await settle();
      await enqueue('b'); // This must complete while a is still in-flight.
      await controller.saveSettings(
        const OrderCallingSettings(enabled: false, ip: '192.168.1.20'),
      );
      transport.blocked!.complete();
      await settle();
      expect(transport.calls, hasLength(1));
      expect(outbox.records['order:b']!['status'], 'pending');
    },
  );
  test(
    'one failed order does not block the next; manual retry retains UUID',
    () async {
      await enable();
      transport.fail = true;
      await enqueue('a');
      await settle();
      expect(outbox.records['order:a']!['status'], 'failed');
      transport.fail = false;
      await enqueue('b');
      await settle();
      expect(outbox.records['order:b']!['status'], 'sent');
      await controller.retry('order:a');
      await settle();
      expect(outbox.records['order:a']!['status'], 'sent');
      expect((transport.calls.last['payload'] as Map)['uuid'], 'a');
    },
  );
  test('storage failure is reported without throwing into checkout', () async {
    await enable();
    outbox.fail = true;
    await enqueue('a');
    await settle();
    expect(controller.state.error, contains('disk full'));
    expect(transport.calls, isEmpty);
  });
  test(
    'interrupted delivery becomes uncertain and is never automatically resent',
    () async {
      outbox.records['order:a'] = {
        'id': 'order:a',
        'uuid': 'a',
        'time': '2026-10-15',
        'status': 'sending',
        'attempts': 1,
        'payload': {'uuid': 'a'},
      };
      controller.dispose();
      controller = OrderCallingController(
        settingsStore: settings,
        outbox: outbox,
        transport: transport,
      );
      await controller.initialize();
      await enable();
      await settle();
      expect(controller.state.records.single['status'], 'uncertain');
      expect(transport.calls, isEmpty);
    },
  );
  test(
    'reprints, payment and cancellation notices are never queued or pushed',
    () async {
      await enable();
      await enqueue('a');
      await controller.enqueueOrder(
        {'uuid': 'a'},
        source: 'sse',
        event: 'item_cancel',
      );
      await controller.enqueueOrder(
        {'uuid': 'a'},
        source: 'sse',
        event: 'payment_Completed',
      );
      await settle();
      expect(transport.calls, hasLength(1));
      await controller.enqueueOrder(
        {'uuid': 'reprint-only'},
        source: 'sse',
        event: 'rePrint',
      );
      await settle();
      expect(transport.calls, hasLength(1));
      expect(outbox.records.keys, ['order:a']);
    },
  );
  test('invalid address cannot replace saved settings', () async {
    await enable();
    expect(
      await controller.saveSettings(
        const OrderCallingSettings(enabled: true, ip: 'invalid-ip'),
      ),
      isFalse,
    );
    expect(controller.state.settings.ip, '192.168.1.20');
  });
  testWidgets(
    'settings page separates IP and optional port, defaulting to 3000',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(settings),
          orderCallingStoreProvider.overrideWithValue(outbox),
          orderCallingTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OrderCallingSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('orderPushIp')),
        '192.168.1.30',
      );
      await tester.tap(find.byType(Switch));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      final saved = container.read(orderCallingControllerProvider).settings;
      expect(saved.enabled, isTrue);
      expect(
        saved.endpoint.toString(),
        'http://192.168.1.30:3000/api/add/order',
      );
      expect(find.text('订单推送'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('orderPushPort')))
            .controller!
            .text,
        '3000',
      );
      await tester.enterText(find.byKey(const ValueKey('orderPushPort')), '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(
        container.read(orderCallingControllerProvider).settings.port,
        3000,
      );
      await tester.enterText(
        find.byKey(const ValueKey('orderPushPort')),
        '3100',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(
        container.read(orderCallingControllerProvider).settings.port,
        3100,
      );
      final persisted = jsonDecode(
        settings.values[OrderCallingController.settingsKey]!,
      );
      expect(persisted['ip'], '192.168.1.30');
      expect(persisted['port'], 3100);
      expect(persisted.containsKey('address'), isFalse);
      expect(
        jsonDecode(
          settings.values[OrderCallingController.settingsKey]!,
        )['enabled'],
        isTrue,
      );
    },
  );
  test(
    'old queued notifications are ignored on restart and cannot be retried',
    () async {
      settings.values[OrderCallingController.settingsKey] = jsonEncode({
        'enabled': true,
        'ip': '192.168.1.20',
        'port': 3000,
      });
      for (final event in ['rePrint', 'item_cancel', 'payment_Completed']) {
        outbox.records[event] = {
          'id': event,
          'uuid': event,
          'event': event,
          'time': '2026-10-15',
          'status': 'pending',
          'attempts': 0,
          'endpoint': 'http://192.168.1.20:3000/api/add/order',
          'payload': {'uuid': event},
        };
      }
      outbox.records['order:normal'] = {
        'id': 'order:normal',
        'uuid': 'normal',
        'event': 'message',
        'time': '2026-10-15',
        'status': 'pending',
        'attempts': 0,
        'endpoint': 'http://192.168.1.20:3000/api/add/order',
        'payload': {'uuid': 'normal'},
      };
      controller.dispose();
      controller = OrderCallingController(
        settingsStore: settings,
        outbox: outbox,
        transport: transport,
      );
      await controller.initialize();
      await settle();
      expect(transport.calls, hasLength(1));
      expect((transport.calls.single['payload'] as Map)['uuid'], 'normal');
      for (final event in ['rePrint', 'item_cancel', 'payment_Completed']) {
        expect(outbox.records[event]!['status'], 'ignored');
        await controller.retry(event);
      }
      await settle();
      expect(transport.calls, hasLength(1));
    },
  );
  test(
    'an ignored old reprint cannot block a new order with the same UUID',
    () async {
      outbox.records['order:a'] = {
        'id': 'order:a',
        'uuid': 'a',
        'event': 'rePrint',
        'time': '2026-10-15',
        'status': 'pending',
        'attempts': 0,
        'endpoint': 'http://192.168.1.20:3000/api/add/order',
        'payload': {'uuid': 'a'},
      };
      controller.dispose();
      controller = OrderCallingController(
        settingsStore: settings,
        outbox: outbox,
        transport: transport,
      );
      await controller.initialize();
      await enable();
      await settle();
      expect(transport.calls, isEmpty);
      await enqueue('a');
      await settle();
      expect(transport.calls, hasLength(1));
      expect(controller.state.records, hasLength(1));
      expect(outbox.records['order:a']!['event'], 'message');
    },
  );
}
