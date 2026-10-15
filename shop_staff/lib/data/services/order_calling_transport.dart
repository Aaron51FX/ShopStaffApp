import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class OrderCallingTransport {
  Future<void> send(Uri endpoint, Map<String, dynamic> payload);
  void close();
}

class DioOrderCallingTransport implements OrderCallingTransport {
  DioOrderCallingTransport([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 3),
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              contentType: Headers.jsonContentType,
            ),
          );
  final Dio _dio;
  @override
  Future<void> send(Uri endpoint, Map<String, dynamic> payload) async {
    // Dedicated client: no cloud credentials, refresh interceptors, or automatic POST retries.
    final response = await _dio.postUri<dynamic>(endpoint, data: payload);
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw StateError('HTTP ${response.statusCode}');
    }
    final body = response.data;
    if (body is Map &&
        (body['success'] == false ||
            (body['code'] != null &&
                !{0, 200, '0', '200'}.contains(body['code'])))) {
      throw StateError('Calling service rejected the order');
    }
  }

  @override
  void close() => _dio.close(force: true);
}

final orderCallingTransportProvider = Provider<OrderCallingTransport>((ref) {
  final transport = DioOrderCallingTransport();
  ref.onDispose(transport.close);
  return transport;
});
