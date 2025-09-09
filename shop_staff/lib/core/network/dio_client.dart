import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'api_exception.dart';
import 'app_environment.dart';
import 'endpoints.dart';

class DioClient {
  final Dio dio;
  final AppConfig config;
  final Endpoints endpoints;

  DioClient._(this.dio, this.config, this.endpoints);

  factory DioClient.create(AppConfig config) {
    final baseOptions = BaseOptions(
      baseUrl: config.apiBase,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
      },
    );

    final d = Dio(baseOptions);
    d.interceptors.add(InterceptorsWrapper(
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
                return handler.next(err is DioException
                    ? err
                    : DioException(requestOptions: req, error: err));
              }
            }
        }
        return handler.next(e);
      },
    ));

    d.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        compact: true,
        maxWidth: 120,
      ),
    );

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
      final res = await dio.get(path,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken);
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
      final res = await dio.post(path,
          data: body, queryParameters: query, options: options, cancelToken: cancelToken);
      final data = res.data;
      return decoder != null ? decoder(data) : data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    return ApiException(
      e.message ?? 'Network Error',
      statusCode: e.response?.statusCode,
      data: e.response?.data,
    );
  }
}
