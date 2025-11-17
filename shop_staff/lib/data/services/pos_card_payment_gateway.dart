import 'package:logging/logging.dart';
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

class CardPaymentRequestData {
  CardPaymentRequestData({
    required this.requestInfo,
    required this.reportPayload,
    this.exceptionMessage,
  });

  final String? requestInfo;
  final Map<String, dynamic>? reportPayload;
  final String? exceptionMessage;

  bool get hasError => exceptionMessage != null && exceptionMessage!.isNotEmpty;
}

class PosCardPaymentGateway {
  PosCardPaymentGateway(this._remote, {Logger? logger}) : _logger = logger ?? Logger('PosCardPaymentGateway');

  final PosRemoteDataSource _remote;
  final Logger _logger;

  Future<CardPaymentRequestData> createPaymentRequest(PosPaymentRequest request) async {
    final payload = _buildRequestPayload(request);
    final resp = await _remote.requestPosPayment(payload);
    if (resp is! Map<String, dynamic>) {
      throw Exception('POS支付接口响应异常');
    }
    final code = resp['code'] as int?;
    if (code != 200) {
      final msg = resp['msg'] ?? resp['message'] ?? 'POS支付接口异常($code)';
      throw Exception(msg.toString());
    }
    final data = resp['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('POS支付接口缺少数据');
    }
    final requestInfo = data['requestInfo'] as String?;
    final exceptionMessage = data['exceptionMessage'] as String?;
    final reportPayload = Map<String, dynamic>.from(data);
    return CardPaymentRequestData(
      requestInfo: requestInfo,
      reportPayload: reportPayload,
      exceptionMessage: exceptionMessage,
    );
  }

  Future<void> reportPayment({
    required Map<String, dynamic> reportPayload,
    required String paymentInfo,
  }) async {
    final payload = Map<String, dynamic>.from(reportPayload)
      ..['paymentInfo'] = paymentInfo
      ..['result'] = true;
    final resp = await _remote.reportPosPayment(payload);
    if (resp is! Map<String, dynamic>) {
      throw Exception('POS支付结果上报失败');
    }
    final code = resp['code'] as int?;
    if (code != 200) {
      throw Exception('POS支付结果上报失败($code)');
    }
    final data = resp['data'];
    if (data is bool && data) {
      return;
    }
    if (data != true) {
      _logger.warning('POS支付结果上报返回异常: $data');
      throw Exception('POS支付结果上报失败');
    }
  }

  Map<String, dynamic> _buildRequestPayload(PosPaymentRequest request) {
    final map = request.customPayload ?? const {};
    String readString(String key, {String? fallback}) {
      final value = map[key];
      if (value == null) return fallback ?? '';
      if (value is String) return value;
      if (value is num) return value.toString();
      return fallback ?? '';
    }

    String authCode() {
      final val = readString('authCode');
      if (val.isNotEmpty) return val;
      return '0000000088888888';
    }

    final machineCode = readString('machineCode', fallback: request.order.orderId);
    final payType = readString('payType');
    final base = <String, dynamic>{
      'auth_code': authCode(),
      'machineCode': machineCode,
      'orderId': request.order.orderId,
    };
    if (payType.isNotEmpty) {
      base['payType'] = payType;
    }
    final extra = map['extraParams'];
    if (extra is Map<String, dynamic>) {
      base.addAll(extra);
    }
    return base;
  }

  //cancel function
  Future<void> cancelPayment(PosPaymentRequest request) async {
    // final payload = _buildRequestPayload(request);
    // final resp = await _remote.cancelPosPayment(payload);
    // if (resp is! Map<String, dynamic>) {
    //   throw Exception('POS支付取消接口响应异常');
    // }
    // final code = resp['code'] as int?;
    // if (code != 200) {
    //   final msg = resp['msg'] ?? resp['message'] ?? 'POS支付取消接口异常($code)';
    //   throw Exception(msg.toString());
    // }
    // final data = resp['data'];
    // if (data is! bool || data != true) {
    //   throw Exception('POS支付取消失败');
    // }
  }
}
