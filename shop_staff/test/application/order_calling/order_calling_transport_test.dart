import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/order_calling_transport.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  String? sentBody;
  int calls = 0;
  int status = 200;
  String body = '{"code":200}';
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    request = options;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        [],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      sentBody = utf8.decode(bytes);
    }
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'LAN delivery posts the legacy JSON without cloud authorization',
    () async {
      final dio = Dio();
      final adapter = _Adapter();
      dio.httpClientAdapter = adapter;
      final transport = DioOrderCallingTransport(dio);
      addTearDown(transport.close);
      await transport.send(
        Uri.parse('http://192.168.1.20:3000/api/add/order'),
        {
          'uuid': 'a',
          'orderLinesMap': {
            '10': [
              {'name': '日本語'},
            ],
          },
        },
      );
      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.uri.path, '/api/add/order');
      expect(
        adapter.request!.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('authorization')),
      );
      final data = jsonDecode(adapter.sentBody!) as Map;
      expect(data['uuid'], 'a');
      expect(data['orderLinesMap'], isNotEmpty);
    },
  );
  test(
    'application rejection and HTTP failures do not silently succeed or retry',
    () async {
      final dio = Dio();
      final adapter = _Adapter();
      dio.httpClientAdapter = adapter;
      final transport = DioOrderCallingTransport(dio);
      addTearDown(transport.close);
      adapter.body = '{"code":500,"msg":"failed"}';
      await expectLater(
        transport.send(Uri.parse('http://example.com/api/add/order'), {
          'uuid': 'a',
        }),
        throwsStateError,
      );
      adapter.status = 503;
      await expectLater(
        transport.send(Uri.parse('http://example.com/api/add/order'), {
          'uuid': 'a',
        }),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 2);
    },
  );
}
