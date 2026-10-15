import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shop_staff/core/sse/sse_connection.dart';

class _Client extends http.BaseClient {
  _Client(this.respond);
  final Future<http.StreamedResponse> Function(http.BaseRequest) respond;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      respond(request);
  @override
  void close() {
    closed = true;
  }
}

void main() {
  test('BOM, comments, multiline data, empty data and ID inheritance', () {
    final parser = SseDecoder();
    expect(parser.addLine('\uFEFF:ping'), isNull);
    parser.addLine('id: 1');
    parser.addLine('event: print');
    parser.addLine('data: first');
    parser.addLine('data: second');
    final first = parser.addLine('')!;
    expect(first.type, 'print');
    expect(first.id, '1');
    expect(first.data, 'first\nsecond');
    parser.addLine('data:');
    final second = parser.addLine('')!;
    expect(second.type, 'message');
    expect(second.data, '');
    expect(second.id, '1');
    parser.addLine('id:');
    parser.addLine('id: bad\u0000id');
    parser.addLine('');
    expect(parser.lastEventId, '');
  });

  test('retry accepts only decimal integers and events are bounded', () {
    final retries = <int>[];
    final parser = SseDecoder(onRetry: retries.add);
    parser.addLine('retry: -1');
    parser.addLine('retry: 1.2');
    parser.addLine('retry: 1500');
    expect(retries, [1500]);
    expect(
      () => parser.addLine('data: ${'x' * (1024 * 1024)}'),
      throwsFormatException,
    );
  });

  testWidgets('stream frames survive fragmented UTF8 and CRLF', (tester) async {
    final stream = StreamController<List<int>>();
    final events = <SseEvent>[];
    final client = _Client((request) async {
      expect(request.headers['Accept'], 'text/event-stream');
      return http.StreamedResponse(
        stream.stream,
        200,
        headers: {'content-type': 'text/event-stream; charset=utf-8'},
      );
    });
    final connection = SseConnection(
      url: Uri.parse('https://example.com/sse'),
      clientFactory: () => client,
      onEvent: events.add,
      onStatus: (_, _) {},
    );
    connection.start();
    await tester.pump();
    final bytes = utf8.encode('id: abc\r\nevent: print\r\ndata: 日本語\r\n\r\n');
    for (final byte in bytes) {
      stream.add([byte]);
    }
    await tester.pump();
    expect(events.single.data, '日本語');
    expect(events.single.id, 'abc');
    connection.close();
    unawaited(stream.close());
    await tester.pump();
    expect(client.closed, isTrue);
  });

  testWidgets('close during pending connection cannot resurrect or dispatch', (
    tester,
  ) async {
    final response = Completer<http.StreamedResponse>();
    final client = _Client((_) => response.future);
    final events = <SseEvent>[];
    final statuses = <SseConnectionStatus>[];
    final connection = SseConnection(
      url: Uri.parse('https://example.com/sse'),
      clientFactory: () => client,
      onEvent: events.add,
      onStatus: (s, _) => statuses.add(s),
    );
    connection.start();
    connection.close();
    response.complete(
      http.StreamedResponse(
        Stream.value(utf8.encode('data: late\n\n')),
        200,
        headers: {'content-type': 'text/event-stream'},
      ),
    );
    await tester.pump(const Duration(minutes: 2));
    expect(events, isEmpty);
    expect(statuses.last, SseConnectionStatus.stopped);
    expect(client.closed, isTrue);
  });

  testWidgets('HTTP 204 stops retries', (tester) async {
    var calls = 0;
    final statuses = <SseConnectionStatus>[];
    final connection = SseConnection(
      url: Uri.parse('https://example.com/sse'),
      clientFactory: () => _Client((_) async {
        calls++;
        return http.StreamedResponse(const Stream.empty(), 204);
      }),
      onEvent: (_) {},
      onStatus: (s, _) => statuses.add(s),
    );
    connection.start();
    await tester.pump();
    await tester.pump(const Duration(minutes: 2));
    expect(calls, 1);
    expect(statuses.last, SseConnectionStatus.rejected);
    connection.close();
  });

  testWidgets('EOF reconnect uses Last-Event-ID, manual close cancels retry', (
    tester,
  ) async {
    var calls = 0;
    final ids = <String?>[];
    final statuses = <String>[];
    final stream = StreamController<List<int>>();
    final connection = SseConnection(
      url: Uri.parse('https://example.com/sse'),
      clientFactory: () => _Client((request) async {
        calls++;
        if (calls == 1) {
          return http.StreamedResponse(
            Stream.value(utf8.encode('retry: 500\nid: saved\ndata: hello\n\n')),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }
        ids.add(request.headers['Last-Event-ID']);
        return http.StreamedResponse(
          stream.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
      onEvent: (_) {},
      onStatus: (status, detail) => statuses.add('${status.name}: $detail'),
    );
    connection.start();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 2, reason: 'ids=$ids statuses=$statuses');
    expect(ids, ['saved']);
    unawaited(stream.close());
    await tester.pump();
    await tester.pump();
    connection.close();
    await tester.pump(const Duration(minutes: 2));
    expect(calls, 2);
  });

  testWidgets('comment heartbeats prevent idle reconnect; silence reconnects', (
    tester,
  ) async {
    var calls = 0;
    final streams = <StreamController<List<int>>>[];
    final connection = SseConnection(
      url: Uri.parse('https://example.com/sse'),
      idleTimeout: const Duration(seconds: 5),
      clientFactory: () => _Client((_) async {
        calls++;
        final stream = StreamController<List<int>>();
        streams.add(stream);
        return http.StreamedResponse(
          stream.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
      onEvent: (_) {},
      onStatus: (_, _) {},
    );
    connection.start();
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 4));
      streams.first.add(utf8.encode(': heartbeat\n\n'));
      await tester.pump();
    }
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 2);
    connection.close();
    for (final stream in streams) {
      unawaited(stream.close());
      await tester.pump();
    }
  });
}
