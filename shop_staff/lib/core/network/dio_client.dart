import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shop_staff/core/auth/auth_token_store.dart';
import 'package:shop_staff/domain/entities/auth_token.dart';

import 'api_exception.dart';
import 'app_environment.dart';
import 'endpoints.dart';

class DioClient {
  static const skipAuthenticationKey = 'skipAuthentication';
  static const skipAuthenticationRefreshKey = 'skipAuthenticationRefresh';
  static const authenticationRetriedKey = 'authenticationRetried';

  final Dio dio;
  final AppConfig config;
  final Endpoints endpoints;

  DioClient._(this.dio, this.config, this.endpoints);

  factory DioClient.create(
    AppConfig config, {
    AuthTokenStore? authTokenStore,
    Future<void> Function()? onAuthenticationRequired,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: config.apiBase,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    );

    final d = Dio(baseOptions);
    if (authTokenStore != null) {
      d.interceptors.add(
        _AuthenticationInterceptor(
          dio: d,
          tokenEndpoint: Endpoints(config).oauthToken,
          tokenStore: authTokenStore,
          onAuthenticationRequired: onAuthenticationRequired,
        ),
      );
    }
    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Initialize retry counter if absent
          options.extra.putIfAbsent('_retries', () => 0);
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (_shouldRetry(e)) {
            final req = e.requestOptions;
            final current = (req.extra['_retries'] as int? ?? 0);
            const maxRetries = 3;
            if (current < maxRetries) {
              req.extra['_retries'] = current + 1;
              // simple linear backoff
              final delayMs = 200 * (current + 1);
              await Future.delayed(Duration(milliseconds: delayMs));
              try {
                final response = await d.fetch(req);
                return handler.resolve(response);
              } catch (err) {
                return handler.next(
                  err is DioException
                      ? err
                      : DioException(requestOptions: req, error: err),
                );
              }
            }
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      d.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          compact: true,
          maxWidth: 120,
          filter: (options, _) =>
              options.extra[skipAuthenticationRefreshKey] != true,
        ),
      );
    }

    return DioClient._(d, config, Endpoints(config));
  }

  static bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Future<T> getJson<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? decoder,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get(
        path,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
      final data = res.data;
      return decoder != null ? decoder(data) : data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<T> postJson<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    T Function(dynamic json)? decoder,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.post(
        path,
        data: body,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
      final data = res.data;
      return decoder != null ? decoder(data) : data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<T> putJson<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    T Function(dynamic json)? decoder,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.put(
        path,
        data: body,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
      final data = res.data;
      return decoder != null ? decoder(data) : data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    final responseMessage = _responseMessage(e.response?.data);
    return ApiException(
      responseMessage ?? ApiException.defaultMessage,
      statusCode: e.response?.statusCode,
      data: e.response?.data,
    );
  }

  String? _responseMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is! String) return null;
    final normalized = message.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class _AuthenticationInterceptor extends Interceptor {
  _AuthenticationInterceptor({
    required Dio dio,
    required String tokenEndpoint,
    required AuthTokenStore tokenStore,
    Future<void> Function()? onAuthenticationRequired,
  }) : _dio = dio,
       _tokenEndpoint = tokenEndpoint,
       _tokenStore = tokenStore,
       _onAuthenticationRequired = onAuthenticationRequired;

  static const _clientId = 'smartwe_pad';

  final Dio _dio;
  final String _tokenEndpoint;
  final AuthTokenStore _tokenStore;
  final Future<void> Function()? _onAuthenticationRequired;
  Future<AuthToken?>? _refreshInFlight;
  bool _authenticationRequiredNotified = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[DioClient.skipAuthenticationKey] != true) {
      final token = await _tokenStore.read();
      if (token != null) {
        _authenticationRequiredNotified = false;
        options.headers['Authorization'] = token.authorizationValue;
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    final shouldRefresh =
        error.response?.statusCode == 401 &&
        request.extra[DioClient.skipAuthenticationRefreshKey] != true &&
        request.extra[DioClient.authenticationRetriedKey] != true;
    if (!shouldRefresh) {
      if (error.response?.statusCode == 401 &&
          request.extra[DioClient.skipAuthenticationRefreshKey] != true) {
        await _requireAuthentication();
      }
      handler.next(error);
      return;
    }

    try {
      final refreshed = await _refreshToken();
      if (refreshed == null) {
        await _requireAuthentication();
        handler.next(error);
        return;
      }
      request.headers['Authorization'] = refreshed.authorizationValue;
      request.extra[DioClient.authenticationRetriedKey] = true;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      await _requireAuthentication();
      handler.next(error);
    }
  }

  Future<AuthToken?> _refreshToken() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<AuthToken?> _performRefresh() async {
    final current = await _tokenStore.read();
    final refreshToken = current?.refreshToken.trim() ?? '';
    if (refreshToken.isEmpty) return null;

    final response = await _dio.post<dynamic>(
      _tokenEndpoint,
      data: FormData.fromMap(<String, dynamic>{
        'scope': _clientId,
        'client_id': _clientId,
        'client_secret': _clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      }),
      options: Options(
        extra: const <String, dynamic>{
          DioClient.skipAuthenticationKey: true,
          DioClient.skipAuthenticationRefreshKey: true,
        },
      ),
    );
    if (response.data is! Map) return null;
    final parsed = AuthToken.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    if (!parsed.isUsable) return null;
    final refreshed = parsed.refreshToken.trim().isEmpty
        ? AuthToken(
            accessToken: parsed.accessToken,
            refreshToken: refreshToken,
            tokenType: parsed.tokenType,
            expiresIn: parsed.expiresIn,
            scope: parsed.scope,
          )
        : parsed;
    await _tokenStore.save(refreshed);
    return refreshed;
  }

  Future<void> _requireAuthentication() async {
    if (_authenticationRequiredNotified) return;
    _authenticationRequiredNotified = true;
    await _tokenStore.clear();
    await _onAuthenticationRequired?.call();
  }
}
