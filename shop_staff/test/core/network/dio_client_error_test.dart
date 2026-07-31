import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/network/api_exception.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/core/network/dio_client.dart';

void main() {
  late DioClient client;

  setUp(() {
    client = DioClient.create(AppConfig.forEnv(AppEnvironment.staging));
    client.dio.httpClientAdapter = _ErrorAdapter();
  });

  test('4xx response exposes only its non-empty message', () async {
    await expectLater(
      client.getJson<dynamic>('/client-error'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.message, 'message', '验证码无效')
            .having((error) => error.toString(), 'toString', '验证码无效'),
      ),
    );
  });

  test('5xx response without a message uses the service fallback', () async {
    await expectLater(
      client.getJson<dynamic>('/server-error'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having(
              (error) => error.message,
              'message',
              ApiException.defaultMessage,
            )
            .having(
              (error) => error.toString(),
              'toString',
              ApiException.defaultMessage,
            ),
      ),
    );
  });

  test('blank response message uses the service fallback', () async {
    await expectLater(
      client.getJson<dynamic>('/blank-message'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          ApiException.defaultMessage,
        ),
      ),
    );
  });
}

class _ErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return switch (options.path) {
      '/client-error' => _json(400, <String, dynamic>{
        'message': '  验证码无效  ',
        'debug': 'must not be displayed',
      }),
      '/blank-message' => _json(422, <String, dynamic>{'message': '   '}),
      _ => _json(500, <String, dynamic>{'error': 'internal_server_error'}),
    };
  }

  ResponseBody _json(int statusCode, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
