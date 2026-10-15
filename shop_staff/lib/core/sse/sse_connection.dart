import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class SseEvent {
  const SseEvent(this.type, this.data, this.id);
  final String type;
  final String data;
  final String id;
}

/// Incremental SSE framing. A partial event at EOF is deliberately discarded.
class SseDecoder {
  SseDecoder({this.lastEventId = '', this.onRetry}) : _eventId = lastEventId;
  String _eventId;
  String lastEventId;
  final void Function(int milliseconds)? onRetry;
  String _type = '';
  final List<String> _data = [];
  int _size = 0;
  bool _first = true;

  SseEvent? addLine(String line) {
    if (_first) {
      _first = false;
      if (line.startsWith('\uFEFF')) line = line.substring(1);
    }
    if (line.isEmpty) {
      lastEventId = _eventId;
      final result = _data.isEmpty
          ? null
          : SseEvent(
              _type.isEmpty ? 'message' : _type,
              _data.join('\n'),
              lastEventId,
            );
      _data.clear();
      _type = '';
      _size = 0;
      return result;
    }
    _size += line.length;
    if (_size > 1024 * 1024) {
      throw const FormatException('SSE event exceeds 1 MiB');
    }
    if (line.startsWith(':')) return null;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'data':
        _data.add(value);
      case 'event':
        _type = value;
      case 'id':
        if (!value.contains('\u0000')) _eventId = value;
      case 'retry':
        if (RegExp(r'^\d+$').hasMatch(value)) {
          final retry = int.tryParse(value);
          if (retry != null) onRetry?.call(retry);
        }
    }
    return null;
  }
}

enum SseConnectionStatus { stopped, connecting, connected, retrying, rejected }

/// One reconnect owner per subscription; close invalidates every pending callback.
class SseConnection {
  SseConnection({
    required this.url,
    required this.onEvent,
    required this.onStatus,
    http.Client Function()? clientFactory,
    this.idleTimeout = const Duration(seconds: 65),
  }) : _clientFactory = clientFactory ?? http.Client.new;
  final Uri url;
  final void Function(SseEvent) onEvent;
  final void Function(SseConnectionStatus, String?) onStatus;
  final http.Client Function() _clientFactory;
  final Duration idleTimeout;
  http.Client? _client;
  StreamSubscription<String>? _subscription;
  Timer? _retryTimer;
  Timer? _idleTimer;
  int _generation = 0;
  int _attempt = 0;
  int _retryMs = 2000;
  String _lastId = '';
  bool _closed = true;

  void start() {
    if (!_closed) return;
    _closed = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_closed) return;
    final generation = ++_generation;
    bool active() => !_closed && generation == _generation;
    onStatus(SseConnectionStatus.connecting, null);
    final client = _clientFactory();
    _client = client;
    try {
      final request = http.Request('GET', url)
        ..headers.addAll({
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          if (_lastId.isNotEmpty) 'Last-Event-ID': _lastId,
        });
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 15));
      if (!active()) return;
      if (response.statusCode == 204 ||
          (response.statusCode >= 400 &&
              response.statusCode < 500 &&
              response.statusCode != 408 &&
              response.statusCode != 429)) {
        close();
        onStatus(SseConnectionStatus.rejected, 'HTTP ${response.statusCode}');
        return;
      }
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').toLowerCase().startsWith(
            'text/event-stream',
          )) {
        throw const FormatException('Invalid SSE response');
      }
      onStatus(SseConnectionStatus.connected, null);
      final decoder = SseDecoder(
        lastEventId: _lastId,
        onRetry: (ms) => _retryMs = ms.clamp(500, 60000),
      );
      void touch() {
        _idleTimer?.cancel();
        _idleTimer = Timer(idleTimeout, () {
          if (active()) _reconnect('Heartbeat timeout');
        });
      }

      touch();
      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (!active()) return;
              touch(); // Comments count as heartbeat activity too.
              try {
                final event = decoder.addLine(line);
                _lastId = decoder.lastEventId;
                if (event != null) {
                  _attempt = 0;
                  onEvent(event);
                }
              } catch (_) {
                _reconnect('Invalid or oversized SSE event');
              }
            },
            onError: (Object error) {
              if (active()) _reconnect('Stream interrupted');
            },
            onDone: () {
              if (active()) _reconnect('Connection closed');
            },
            cancelOnError: true,
          );
    } catch (_) {
      if (active()) _reconnect('Connection failed');
    }
  }

  void _reconnect(String reason) {
    if (_closed) return;
    ++_generation;
    _release();
    final delay = min(60000, _retryMs * pow(2, min(_attempt++, 5))).toInt();
    onStatus(SseConnectionStatus.retrying, reason);
    _retryTimer = Timer(
      Duration(milliseconds: delay + Random().nextInt(500)),
      _connect,
    );
  }

  void _release() {
    _retryTimer?.cancel();
    _idleTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    _client?.close();
    _client = null;
  }

  void close() {
    _closed = true;
    ++_generation;
    _release();
    onStatus(SseConnectionStatus.stopped, null);
  }
}
