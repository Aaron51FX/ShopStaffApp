import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/auth/auth_token_store.dart';
import 'package:shop_staff/core/network/api_exception.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/domain/entities/auth_token.dart';

void main() {
  test('adds Authorization and retries once with refreshed token', () async {
    final storage = _MemoryKeyValueStore();
    final tokenStore = AuthTokenStore(storage);
    await tokenStore.save(
      const AuthToken(
        accessToken: 'expired-access',
        refreshToken: 'refresh-1',
        tokenType: 'Bearer',
      ),
    );
    final adapter = _AuthAdapter(refreshSucceeds: true);
    final client = DioClient.create(
      AppConfig.forEnv(AppEnvironment.staging),
      authTokenStore: tokenStore,
    );
    client.dio.httpClientAdapter = adapter;

    final response = await client.getJson<Map<String, dynamic>>('/protected');

    expect(response['ok'], isTrue);
    expect(adapter.protectedCalls, 2);
    expect(adapter.refreshCalls, 1);
    expect(adapter.authorizationHeaders, <String>[
      'Bearer expired-access',
      'Bearer refreshed-access',
    ]);
    expect((await tokenStore.read())?.accessToken, 'refreshed-access');
  });

  test('refresh failure clears only token and requires login', () async {
    final storage = _MemoryKeyValueStore();
    final tokenStore = AuthTokenStore(storage);
    await storage.write(AppStorageKeys.activationCode, 'MACHINE-1');
    await tokenStore.save(
      const AuthToken(
        accessToken: 'expired-access',
        refreshToken: 'invalid-refresh',
        tokenType: 'Bearer',
      ),
    );
    var authenticationRequiredCount = 0;
    final client = DioClient.create(
      AppConfig.forEnv(AppEnvironment.staging),
      authTokenStore: tokenStore,
      onAuthenticationRequired: () async {
        authenticationRequiredCount += 1;
      },
    );
    client.dio.httpClientAdapter = _AuthAdapter(refreshSucceeds: false);

    await expectLater(
      client.getJson<Map<String, dynamic>>('/protected'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );

    expect(await tokenStore.read(), isNull);
    expect(
      await storage.read(AppStorageKeys.activationCode),
      'MACHINE-1',
      reason: 'automatic auth expiry must preserve machine activation',
    );
    expect(authenticationRequiredCount, 1);
  });

  test('concurrent 401 responses share one refresh request', () async {
    final storage = _MemoryKeyValueStore();
    final tokenStore = AuthTokenStore(storage);
    await tokenStore.save(
      const AuthToken(
        accessToken: 'expired-access',
        refreshToken: 'refresh-1',
        tokenType: 'Bearer',
      ),
    );
    final adapter = _AuthAdapter(
      refreshSucceeds: true,
      refreshDelay: const Duration(milliseconds: 30),
    );
    final client = DioClient.create(
      AppConfig.forEnv(AppEnvironment.staging),
      authTokenStore: tokenStore,
    );
    client.dio.httpClientAdapter = adapter;

    final responses = await Future.wait(<Future<Map<String, dynamic>>>[
      client.getJson<Map<String, dynamic>>('/protected'),
      client.getJson<Map<String, dynamic>>('/protected'),
    ]);

    expect(responses.every((response) => response['ok'] == true), isTrue);
    expect(adapter.refreshCalls, 1);
    expect(adapter.protectedCalls, 4);
  });
}

class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({
    required this.refreshSucceeds,
    this.refreshDelay = Duration.zero,
  });

  final bool refreshSucceeds;
  final Duration refreshDelay;
  int protectedCalls = 0;
  int refreshCalls = 0;
  final List<String> authorizationHeaders = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/uaa/oauth/token')) {
      refreshCalls += 1;
      if (refreshDelay > Duration.zero) {
        await Future<void>.delayed(refreshDelay);
      }
      if (!refreshSucceeds) {
        return _json(401, <String, dynamic>{'error': 'invalid_grant'});
      }
      return _json(200, <String, dynamic>{
        'access_token': 'refreshed-access',
        'refresh_token': 'refresh-2',
        'token_type': 'Bearer',
      });
    }

    if (options.path.endsWith('/protected')) {
      protectedCalls += 1;
      final authorization = options.headers['Authorization']?.toString() ?? '';
      authorizationHeaders.add(authorization);
      if (authorization != 'Bearer refreshed-access') {
        return _json(401, <String, dynamic>{'error': 'unauthorized'});
      }
      return _json(200, <String, dynamic>{'ok': true});
    }

    return _json(404, <String, dynamic>{'error': 'not_found'});
  }

  ResponseBody _json(int status, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
