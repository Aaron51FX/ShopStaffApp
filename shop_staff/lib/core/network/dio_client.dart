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
        // TODO: attach token if available
        return handler.next(options);
      },
      onError: (e, handler) {
        if (_shouldRetry(e)) {
          d.fetch(e.requestOptions).then((r) => handler.resolve(r)).catchError((err, stack) {
            handler.next(err is DioException ? err : DioException(requestOptions: e.requestOptions, error: err));
          });
          return;
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
