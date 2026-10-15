import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/services/order_calling_store.dart';
import 'package:shop_staff/data/services/order_calling_transport.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';

class OrderCallingState {
  const OrderCallingState({
    this.settings = const OrderCallingSettings(),
    this.loading = true,
    this.records = const [],
    this.error,
  });
  final OrderCallingSettings settings;
  final bool loading;
  final List<Map<String, dynamic>> records;
  final String? error;
}

final orderCallingControllerProvider =
    StateNotifierProvider<OrderCallingController, OrderCallingState>((ref) {
      final controller = OrderCallingController(
        settingsStore: ref.watch(keyValueStoreProvider),
        outbox: ref.watch(orderCallingStoreProvider),
        transport: ref.watch(orderCallingTransportProvider),
      );
      scheduleMicrotask(controller.initialize);
      return controller;
    });
final orderCallingServiceProvider = Provider<OrderCallingService>(
  (ref) => ref.watch(orderCallingControllerProvider.notifier),
);

class OrderCallingController extends StateNotifier<OrderCallingState>
    implements OrderCallingService {
  OrderCallingController({
    required KeyValueStore settingsStore,
    required OrderCallingStore outbox,
    required OrderCallingTransport transport,
  }) : _settingsStore = settingsStore,
       _outbox = outbox,
       _transport = transport,
       super(const OrderCallingState());
  static const settingsKey = 'order_calling_settings_v1';
  final KeyValueStore _settingsStore;
  final OrderCallingStore _outbox;
  final OrderCallingTransport _transport;
  final _ready = Completer<void>();
  Future<void> _mutations = Future.value();
  bool _disposed = false, _healthy = false, _draining = false;

  void _publish({
    OrderCallingSettings? settings,
    List<Map<String, dynamic>>? records,
    String? error,
    bool clearError = false,
  }) {
    if (_disposed) return;
    state = OrderCallingState(
      settings: settings ?? state.settings,
      records: records ?? state.records,
      loading: false,
      error: clearError ? null : (error ?? state.error),
    );
  }

  Future<void> initialize() async {
    try {
      final raw = await _settingsStore.read(settingsKey);
      final records = await _outbox.load();
      if (_disposed) return;
      for (final record in records) {
        if (!isCallingOrderEvent(record['event'] as String? ?? 'message')) {
          if (record['status'] != 'sent' && record['status'] != 'ignored') {
            record['status'] = 'ignored';
            await _outbox.put(record);
          }
          continue;
        }
        if (record['status'] == 'sending') {
          record['status'] = 'uncertain';
          record['error'] = 'Application interrupted while sending';
          await _outbox.put(record);
        }
      }
      _healthy = true;
      _publish(
        settings: raw == null
            ? const OrderCallingSettings()
            : OrderCallingSettings.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map),
              ),
        records: records,
      );
    } catch (_) {
      _healthy = false;
      _publish(error: 'Cannot load calling service settings or outbox');
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
    unawaited(_drain());
  }

  Future<void> _mutate(Future<void> Function() action) {
    final job = _mutations.then((_) async {
      await _ready.future;
      if (_disposed) return;
      if (!_healthy) throw StateError('Calling service storage is unavailable');
      await action();
    });
    _mutations = job.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return job;
  }

  Future<bool> saveSettings(OrderCallingSettings settings) async {
    try {
      if (settings.enabled || settings.ip.trim().isNotEmpty) {
        settings.endpoint;
      }
      await _mutate(() async {
        await _settingsStore.write(settingsKey, jsonEncode(settings.toJson()));
        _publish(settings: settings, clearError: true);
      });
      if (!_disposed) unawaited(_drain());
      return !_disposed;
    } catch (error) {
      _publish(error: error.toString());
      return false;
    }
  }

  @override
  Future<void> enqueueOrder(
    Map<String, dynamic> payload, {
    required String source,
    String event = 'message',
  }) async {
    if (!isCallingOrderEvent(event)) return;
    try {
      await _mutate(() async {
        if (!state.settings.enabled) return;
        final uuid = payload['uuid']?.toString().trim() ?? '';
        if (uuid.isEmpty) throw const FormatException('Order UUID is required');
        final id = 'order:$uuid';
        if (state.records.any(
          (record) => record['id'] == id && record['status'] != 'ignored',
        )) {
          return;
        }
        // Prune only delivered records; never silently evict a failed order.
        final records = state.records
            .where((record) => record['id'] != id)
            .toList();
        while (records.length >= 500) {
          final index = records.indexWhere(
            (record) =>
                record['status'] == 'sent' || record['status'] == 'ignored',
          );
          if (index < 0) throw StateError('Calling service outbox is full');
          final removed = records.removeAt(index);
          await _outbox.delete(removed['id'] as String);
        }
        final record = <String, dynamic>{
          'id': id,
          'uuid': uuid,
          'source': source,
          'event': event,
          'time': DateTime.now().toIso8601String(),
          'endpoint': state.settings.endpoint.toString(),
          'payload': jsonDecode(jsonEncode(payload)),
          'status': 'pending',
          'attempts': 0,
        };
        await _outbox.put(record);
        records.add(record);
        _publish(records: records);
      });
      if (!_disposed) unawaited(_drain());
    } catch (error) {
      // Delivery failure is visible here but must never turn a successful order into a retryable checkout.
      _publish(error: error.toString());
    }
  }

  Future<void> retry(String id) async {
    try {
      await _mutate(() async {
        if (!state.settings.enabled) return;
        final current = state.records.where((r) => r['id'] == id).firstOrNull;
        if (current == null ||
            !isCallingOrderEvent(current['event'] as String? ?? 'message') ||
            !{'failed', 'uncertain'}.contains(current['status'])) {
          return;
        }
        await _replace({
          ...current,
          'status': 'pending',
          'error': null,
          'endpoint': state.settings.endpoint.toString(),
        });
      });
      if (!_disposed) unawaited(_drain());
    } catch (error) {
      _publish(error: error.toString());
    }
  }

  Future<void> _replace(Map<String, dynamic> record) async {
    await _outbox.put(record);
    _publish(
      records: [
        for (final r in state.records) r['id'] == record['id'] ? record : r,
      ],
    );
  }

  Future<void> _drain() async {
    if (_disposed || !_healthy || _draining || !state.settings.enabled) return;
    _draining = true;
    try {
      while (!_disposed && state.settings.enabled) {
        Map<String, dynamic>? next;
        await _mutate(() async {
          final pending = state.records
              .where(
                (r) =>
                    r['status'] == 'pending' &&
                    isCallingOrderEvent(r['event'] as String? ?? 'message'),
              )
              .firstOrNull;
          if (pending == null || !state.settings.enabled) return;
          next = {
            ...pending,
            'status': 'sending',
            'attempts': (pending['attempts'] as int) + 1,
          };
          await _replace(next!);
        });
        if (next == null || _disposed) break;
        String? error;
        try {
          await _transport.send(
            Uri.parse(next!['endpoint'] as String),
            Map<String, dynamic>.from(next!['payload'] as Map),
          );
        } catch (failure) {
          error = failure.toString();
        }
        if (_disposed) return;
        await _mutate(
          () => _replace({
            ...next!,
            'status': error == null ? 'sent' : 'failed',
            'error': error,
            'finishedAt': DateTime.now().toIso8601String(),
          }),
        );
      }
    } catch (error) {
      _publish(error: error.toString());
    } finally {
      _draining = false;
      if (!_disposed &&
          state.error == null &&
          state.settings.enabled &&
          state.records.any(
            (record) =>
                record['status'] == 'pending' &&
                isCallingOrderEvent(record['event'] as String? ?? 'message'),
          )) {
        scheduleMicrotask(_drain);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
