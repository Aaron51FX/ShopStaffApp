import 'package:shop_staff/application/order_calling/order_calling_controller.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';
import 'package:shop_staff/data/services/sse_print_journal.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/settings/pages/sse_settings_page.dart';
import 'package:shop_staff/presentations/printing/print_root_view.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/application/sse/sse_runtime.dart';
import 'package:shop_staff/application/sse/sse_print_dispatcher.dart';
import 'package:shop_staff/core/sse/sse_connection.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/presentations/printing/receipt_factory.dart';

class _Store implements KeyValueStore {
  final data = <String, String>{
    'sse_subscriptions_v1': jsonEncode([
      {'id': 'smartWe', 'kind': 'smartWe', 'identify': '', 'enabled': true},
    ]),
  };
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<bool> contains(String key) async => data.containsKey(key);
  @override
  Future<void> clearAll() async {
    data.clear();
  }
}

class _Journal implements SsePrintJournal {
  List<Map<String, dynamic>> records = [];
  @override
  Future<List<Map<String, dynamic>>> load() async =>
      (jsonDecode(jsonEncode(records)) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  @override
  Future<void> save(List<Map<String, dynamic>> next) async {
    records = (jsonDecode(jsonEncode(next)) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class _CallingService implements OrderCallingService {
  final messages = <Map<String, dynamic>>[];
  @override
  Future<void> enqueueOrder(
    Map<String, dynamic> payload, {
    required String source,
    String event = 'message',
  }) async {
    messages.add({...payload, '_event': event});
  }
}

class _Adapter implements HttpClientAdapter {
  int calls = 0;
  bool fail = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{"code":200,"data":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Ticket extends StatelessWidget with ATempWidget {
  const _Ticket();
  @override
  int get pixelPagerWidth => 300;
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Dispatcher extends SsePrintDispatcher {
  _Dispatcher() : super(const ReceiptRendererImpl());
  int sent = 0;
  bool invalid = false;
  bool failSend = false;
  @override
  List<SsePrintTask> prepare(
    String event,
    Map<String, dynamic> data,
    List<PrinterSettings> printers, {
    bool center = false,
    bool seat = false,
  }) {
    if (invalid) throw StateError('missing printer');
    return [
      SsePrintTask(
        const _Ticket(),
        const PrinterSettings(name: 'p', type: 10),
        PrintTypeEnum.label,
      ),
    ];
  }

  @override
  Future<void> submit(SsePrintTask task) async {
    if (failSend) throw StateError('transport interrupted');
    sent++;
  }
}

void main() {
  late _Store store;
  late _Journal journal;
  late _CallingService calling;
  late _Adapter adapter;
  late _Dispatcher dispatcher;
  late ProviderContainer container;
  late SseRuntime runtime;
  Future<void> settle() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> setup() async {
    final client = DioClient.create(AppConfig.forEnv(AppEnvironment.staging));
    client.dio.interceptors.clear();
    client.dio.httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        orderCallingServiceProvider.overrideWithValue(calling),
        ssePrintJournalProvider.overrideWithValue(journal),
        dioClientProvider.overrideWithValue(client),
        ssePrintDispatcherProvider.overrideWithValue(dispatcher),
      ],
    );
    runtime = container.read(sseRuntimeProvider.notifier);
    await settle();
    runtime.setHostReady(
      true,
    ); // No machine code: no real SSE HTTP connections in this test.
    await settle();
  }

  void receive(String uuid) => runtime.receive(
    'smartWe',
    SseEvent('message', jsonEncode({'uuid': uuid}), ''),
  );
  setUp(() async {
    store = _Store();
    journal = _Journal();
    calling = _CallingService();
    adapter = _Adapter();
    dispatcher = _Dispatcher();
    await setup();
  });
  tearDown(() {
    container.dispose();
  });

  test(
    'duplicate UUID is claimed and sent only once, including after restart',
    () async {
      receive('a');
      receive('a');
      await settle();
      expect(adapter.calls, 1);
      expect(dispatcher.sent, 1);
      expect(
        container.read(sseRuntimeProvider).records.single['status'],
        'sent',
      );
      container.dispose();
      await setup();
      receive('a');
      await settle();
      expect(adapter.calls, 1);
      expect(dispatcher.sent, 1);
    },
  );

  test(
    'validation failure never claims; fixed settings allow explicit retry',
    () async {
      dispatcher.invalid = true;
      receive('b');
      await settle();
      expect(adapter.calls, 0);
      expect(
        container.read(sseRuntimeProvider).records.single['status'],
        'invalid',
      );
      dispatcher.invalid = false;
      runtime.retryInvalid('b');
      await settle();
      expect(adapter.calls, 1);
      expect(dispatcher.sent, 1);
    },
  );

  test('ambiguous callback does not print or retry automatically', () async {
    adapter.fail = true;
    receive('c');
    await settle();
    receive('c');
    await settle();
    expect(adapter.calls, 1);
    expect(dispatcher.sent, 0);
    expect(
      container.read(sseRuntimeProvider).records.single['status'],
      'uncertain',
    );
  });

  test(
    'transport failure is durable and cannot be resent by duplicate delivery',
    () async {
      dispatcher.failSend = true;
      receive('d');
      await settle();
      expect(
        container.read(sseRuntimeProvider).records.single['status'],
        'uncertain',
      );
      dispatcher.failSend = false;
      receive('d');
      runtime.retryInvalid('d');
      await settle();
      expect(adapter.calls, 1);
      expect(dispatcher.sent, 0);
    },
  );
  testWidgets('settings page opens subscription editor and persists changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SseSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SSE 设置'), findsOneWidget);
    await tester.tap(find.text('smartWe · '));
    await tester.pumpAndSettle();
    expect(find.text('SmartWe SSE'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(container.read(sseRuntimeProvider).settings.single.enabled, isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'print host mounts and disconnects without lifecycle provider writes',
    (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PrintRootView(child: Scaffold(body: Text('print host'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('print host'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  test('SSE forwards even when printer validation fails', () async {
    dispatcher.invalid = true;
    receive('forward-without-printer');
    await settle();
    expect(calling.messages.single['uuid'], 'forward-without-printer');
    expect(adapter.calls, 0);
  });
  test(
    'SSE cancellation and payment notices neither push orders nor create print jobs',
    () async {
      runtime.receive(
        'smartWe',
        const SseEvent('item_cancel', '{"uuid":"cancel"}', ''),
      );
      runtime.receive(
        'smartWe',
        const SseEvent('payment_Completed', '{"uuid":"paid"}', ''),
      );
      await settle();
      expect(calling.messages, isEmpty);
      expect(adapter.calls, 0);
      expect(dispatcher.sent, 0);
    },
  );
  test(
    'SSE rePrint still prints but never pushes to the calling system',
    () async {
      runtime.receive(
        'smartWe',
        const SseEvent('rePrint', '{"uuid":"reprint"}', ''),
      );
      await settle();
      expect(calling.messages, isEmpty);
      expect(adapter.calls, 1);
      expect(dispatcher.sent, 1);
      expect(
        container.read(sseRuntimeProvider).records.single['status'],
        'sent',
      );
    },
  );
}
