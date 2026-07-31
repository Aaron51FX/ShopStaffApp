class ApiException implements Exception {
  static const String defaultMessage = '服务异常，请联系供应商。';

  final String message;
  final int? statusCode;
  final dynamic data;
  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiResult<T> {
  final T? data;
  final ApiException? error;
  const ApiResult._({this.data, this.error});

  bool get isSuccess => error == null;
  static ApiResult<T> success<T>(T data) => ApiResult._(data: data);
  static ApiResult<T> failure<T>(ApiException e) => ApiResult._(error: e);
}
