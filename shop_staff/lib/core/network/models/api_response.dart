class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic raw)? dataParser,
  }) {
    return ApiResponse(
      code: json['code'] ?? json['status'] ?? 0,
      message: json['message'] ?? json['msg'] ?? '',
      data: dataParser != null ? dataParser(json['data']) : json['data'],
    );
  }

  bool get isOk => code == 0 || code == 200;
}
