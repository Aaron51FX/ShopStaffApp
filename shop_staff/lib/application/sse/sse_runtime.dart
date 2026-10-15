import 'package:shop_staff/application/order_calling/order_calling_controller.dart';
import 'package:shop_staff/data/services/sse_print_journal.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/sse/sse_connection.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/presentations/printing/printing_providers.dart';
import 'sse_print_dispatcher.dart';

class SseSubscriptionSettings {
  const SseSubscriptionSettings({
    required this.id,
    required this.kind,
    required this.identify,
    this.enabled = false,
    this.center = false,
    this.seat = false,
  });
  final String id, kind, identify;
  final bool enabled, center, seat;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'identify': identify,
    'enabled': enabled,
    'center': center,
    'seat': seat,
  };
  factory SseSubscriptionSettings.fromJson(Map<String, dynamic> json) =>
      SseSubscriptionSettings(
        id: json['id'] as String,
        kind: json['kind'] as String,
        identify: json['identify'] as String,
        enabled: json['enabled'] == true,
        center: json['center'] == true,
        seat: json['seat'] == true,
      );
}

class SseRuntimeState {
  const SseRuntimeState({
    this.settings = const [],
    this.statuses = const {},
    this.records = const [],
    this.loading = true,
    this.error,
  });
  final List<SseSubscriptionSettings> settings;
  final Map<String, String> statuses;
  final List<Map<String, dynamic>> records;
  final bool loading;
  final String? error;
}

final sseMachineCodeProvider = Provider<String>((ref) {
  final activated = ref.watch(machineCodeProvider)?.trim() ?? '';
  return activated.isNotEmpty
      ? activated
      : (ref.watch(appSettingsSnapshotProvider)?.basic.machineCode?.trim() ??
            '');
});

final ssePrintDispatcherProvider = Provider<SsePrintDispatcher>(
  (ref) => SsePrintDispatcher(ref.watch(receiptRendererProvider)),
);

final sseRuntimeProvider = StateNotifierProvider<SseRuntime, SseRuntimeState>((
  ref,
) {
  final runtime = SseRuntime(ref);
  ref.listen<AppSettingsSnapshot?>(appSettingsSnapshotProvider, (_, next) {
    runtime.reconcile();
  });
  ref.listen<String>(sseMachineCodeProvider, (_, next) => runtime.reconcile());
  // Defer initial state mutations until provider construction has finished.
  scheduleMicrotask(runtime.initialize);
  return runtime;
});

class SseRuntime extends StateNotifier<SseRuntimeState> {
  SseRuntime(this.ref) : super(const SseRuntimeState());
  final Ref ref;
  static const _settingsKey = 'sse_subscriptions_v1';
  final Map<String, SseConnection> _connections = {};
  final Map<String, String> _urls = {};
  final Set<String> _pending = {};
  Future<void> _queue = Future.value();
  bool _disposed = false;
  bool _saving = false;
  bool _hostReady = false;

  void setHostReady(bool ready) {
    _hostReady = ready;
    scheduleMicrotask(() {
      if (!_disposed) reconcile();
    });
  }

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  Future<void> initialize() async {
    try {
      final raw = await _store.read(_settingsKey);
      final journal = await ref.read(ssePrintJournalProvider).load();
      if (_disposed) return;
      state = SseRuntimeState(
        settings: raw == null
            ? const [
                SseSubscriptionSettings(
                  id: 'smartWe',
                  kind: 'smartWe',
                  identify: '',
                ),
              ]
            : (jsonDecode(raw) as List)
                  .map(
                    (v) => SseSubscriptionSettings.fromJson(
                      Map<String, dynamic>.from(v),
                    ),
                  )
                  .toList(),
        records: journal,
        loading: false,
      );
      final recovered = state.records.map((entry) {
        final record = Map<String, dynamic>.from(entry);
        if (record['status'] == 'preparing') record['status'] = 'invalid';
        if (record['status'] == 'claiming' || record['status'] == 'sending') {
          record['status'] = 'uncertain';
          record['error'] = '应用在确认或发送期间中断，请核对出纸';
        }
        return record;
      }).toList();
      await ref.read(ssePrintJournalProvider).save(recovered);
      if (_disposed) return;
      _publish(records: recovered);
      reconcile();
    } catch (_) {
      if (!_disposed) {
        state = const SseRuntimeState(
          loading: false,
          error: 'SSE 配置或打印记录读取失败，请检查本机存储',
        );
      }
    }
  }

  void _publish({
    List<SseSubscriptionSettings>? settings,
    Map<String, String>? statuses,
    List<Map<String, dynamic>>? records,
    String? error,
  }) {
    if (_disposed) return;
    state = SseRuntimeState(
      settings: settings ?? state.settings,
      statuses: statuses ?? state.statuses,
      records: records ?? state.records,
      loading: state.loading,
      error: error,
    );
  }

  Future<void> save(List<SseSubscriptionSettings> settings) async {
    if (_saving || state.loading) return;
    _saving = true;
    try {
      final keys = <String>{};
      for (final config in settings) {
        if (!{'smartWe', 'panda'}.contains(config.kind)) {
          throw StateError('无效订阅类型');
        }
        if (config.kind == 'panda' && config.identify.trim().isEmpty) {
          throw StateError('请输入 Panda 标识');
        }
        if (!keys.add('${config.kind}:${config.identify.trim()}')) {
          throw StateError('订阅重复');
        }
      }
      await _store.write(
        _settingsKey,
        jsonEncode(settings.map((e) => e.toJson()).toList()),
      );
      if (_disposed) return;
      _publish(settings: settings);
      reconcile();
    } catch (error) {
      _publish(error: error.toString());
    } finally {
      _saving = false;
    }
  }

  void reconcile({bool force = false}) {
    if (_disposed || state.loading) return;
    final machineCode = ref.read(sseMachineCodeProvider);
    final desired = <String, Uri>{};
    for (final config in state.settings.where((e) => e.enabled)) {
      final identify = config.kind == 'smartWe'
          ? machineCode
          : config.identify.trim();
      if (!_hostReady || machineCode.isEmpty || identify.isEmpty) continue;
      final endpoints = ref.read(dioClientProvider).endpoints;
      desired[config.id] = Uri.parse(
        config.kind == 'smartWe'
            ? endpoints.sseSubscribeSmartWe(identify)
            : endpoints.sseSubscribePanda(identify),
      );
    }
    for (final id in _connections.keys.toList()) {
      if (force || _urls[id] != desired[id]?.toString()) {
        _connections.remove(id)?.close();
        _urls.remove(id);
      }
    }
    for (final entry in desired.entries) {
      if (_connections.containsKey(entry.key)) continue;
      final id = entry.key;
      final connection = SseConnection(
        url: entry.value,
        onStatus: (status, detail) => _publish(
          statuses: {
            ...state.statuses,
            id: '${status.name}${detail == null ? '' : ' · $detail'}',
          },
        ),
        onEvent: (event) => receive(id, event),
      );
      _connections[id] = connection;
      _urls[id] = entry.value.toString();
      connection.start();
    }
  }

  void receive(String source, SseEvent event) {
    if (_disposed || event.type == 'heartbeat') return;
    if (!{
      'message',
      'rePrint',
      'print',
      'expiryPrint',
      'item_cancel',
      'payment_Completed',
    }.contains(event.type)) {
      _publish(error: '收到事件 ${event.type}，当前无对应处理器');
      return;
    }
    try {
      final data = Map<String, dynamic>.from(jsonDecode(event.data) as Map);
      final uuid = data['uuid']?.toString().trim() ?? '';
      if (uuid.isEmpty) throw const FormatException('消息缺少 UUID');
      final subscription = state.settings
          .where((s) => s.id == source && s.enabled)
          .firstOrNull;
      if (subscription == null) return;
      if (event.type == 'message') {
        unawaited(
          ref
              .read(orderCallingServiceProvider)
              .enqueueOrder(data, source: 'sse:$source', event: event.type)
              .catchError((Object _) {
                _publish(error: '订单推送入队失败，请检查订单推送设置');
              }),
        );
      }
      if (event.type == 'item_cancel' || event.type == 'payment_Completed') {
        return;
      }

      if (_pending.contains(uuid) ||
          state.records.any((r) => r['uuid'] == uuid)) {
        return;
      }
      _pending.add(uuid);
      _queue = _queue.then((_) async {
        try {
          if (!_disposed) await _process(source, event.type, data);
        } catch (_) {
          _publish(error: '消息处理失败，请检查打印记录和存储');
        } finally {
          _pending.remove(uuid);
        }
      });
    } catch (_) {
      _publish(error: '收到无效 SSE 消息（JSON 或 UUID 错误）');
    }
  }

  void retryInvalid(String uuid) {
    if (_pending.contains(uuid)) return;
    final record = state.records
        .where((r) => r['uuid'] == uuid && r['status'] == 'invalid')
        .firstOrNull;
    if (record == null) return;
    _pending.add(uuid);
    _queue = _queue.then((_) async {
      try {
        if (!_disposed) {
          await _process(
            record['source'] as String,
            record['event'] as String,
            Map<String, dynamic>.from(record['data'] as Map),
          );
        }
      } catch (_) {
        _publish(error: '消息重试失败，请检查存储');
      } finally {
        _pending.remove(uuid);
      }
    });
  }

  Future<void> _record(Map<String, dynamic> record) async {
    final records = [
      ...state.records.where((r) => r['uuid'] != record['uuid']),
      Map<String, dynamic>.from(record),
    ];
    // Keep unresolved jobs. Completed entries form a bounded restart dedup journal.
    while (records.length > 500) {
      final index = records.indexWhere(
        (r) => r['status'] == 'sent' || r['status'] == 'declined',
      );
      if (index < 0) throw StateError('未处理打印记录已满');
      records.removeAt(index);
    }
    await ref.read(ssePrintJournalProvider).save(records);
    _publish(records: records);
  }

  Future<void> _process(
    String source,
    String event,
    Map<String, dynamic> data,
  ) async {
    final config = state.settings
        .where((s) => s.id == source && s.enabled)
        .firstOrNull;
    if (config == null || !_hostReady) return;
    final record = <String, dynamic>{
      'uuid': data['uuid'].toString(),
      'event': event,
      'source': source,
      'time': DateTime.now().toIso8601String(),
      'data': data,
      'status': 'preparing',
      'sent': 0,
    };
    try {
      final dispatcher = ref.read(ssePrintDispatcherProvider);
      final tasks = dispatcher.prepare(
        event,
        data,
        ref.read(appSettingsSnapshotProvider)?.printers ?? [],
        center: config.center,
        seat: config.seat,
      );
      if (tasks.isEmpty) return;
      await _record(record);
      if (_disposed) return;
      // Persist before calling: a timeout can mean the server already accepted the claim.
      record['status'] = 'claiming';
      await _record(record);
      final client = ref.read(dioClientProvider);
      final result = await client.postJson<dynamic>(
        client.endpoints.sseCallback,
        body: {'uuid': data['uuid']},
        options: Options(extra: {'_retries': 3}),
      );
      if (_disposed) return;
      if (result is! Map || result['code'] != 200 || result['data'] == null) {
        record['status'] = 'declined';
        await _record(record);
        return;
      }
      record['status'] = 'sending';
      await _record(record);
      for (final task in tasks) {
        if (_disposed || !_hostReady) return;
        await dispatcher.submit(task);
        record['sent'] = (record['sent'] as int) + 1;
        await _record(record);
      }
      record['status'] = 'sent';
      await _record(record);
    } catch (error) {
      if (_disposed) return;
      record['error'] = error.toString();
      record['status'] = record['status'] == 'preparing'
          ? 'invalid'
          : 'uncertain';
      await _record(record);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final connection in _connections.values) {
      connection.close();
    }
    _connections.clear();
    super.dispose();
  }
}
