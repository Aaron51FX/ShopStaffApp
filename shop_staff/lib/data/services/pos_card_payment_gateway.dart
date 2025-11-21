import 'package:logging/logging.dart';
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

class CardPaymentRequestData {
  CardPaymentRequestData({
    required this.requestInfo,
    required this.reportPayload,
    this.exceptionMessage,
    required this.success,
    required this.data,
  });

  final bool success;
  final String? requestInfo;
  final Map<String, dynamic>? reportPayload;
  final String? exceptionMessage;
  final Map<String, dynamic> data;

  bool get hasError => exceptionMessage != null && exceptionMessage!.isNotEmpty;
}

class CardCancelInstruction {
  CardCancelInstruction({required this.payload, this.prompt});

  final String payload;
  final String? prompt;
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
    final success = resp['success'];
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
      success: success == 'success' || code == 200,
      data: data,
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

  Future<CardCancelInstruction> fetchCancelInstruction(PosPaymentRequest request) async {
    final payload = _buildCancelPayload(request);
    final resp = await _remote.cancelCreditCard(payload);
    if (resp is! Map<String, dynamic>) {
      throw Exception('POS取消接口响应异常');
    }
    final code = resp['code'] as int?;
    final message = resp['msg'] ?? resp['message'];
    if (code != 200) {
      throw Exception(message?.toString() ?? 'POS取消接口异常($code)');
    }
    final data = resp['data'];
    String? cancelPayload;
    String? prompt;
    if (data is String) {
      cancelPayload = data;
    } else if (data is Map<String, dynamic>) {
      final candidates = [
        data['cancelInfo'],
        data['cancelData'],
        data['payload'],
        data['data'],
      ];
      for (final candidate in candidates) {
        if (candidate is String && candidate.isNotEmpty) {
          cancelPayload = candidate;
          break;
        }
      }
      final extraMessage = data['message'] ?? data['msg'];
      if (extraMessage != null) {
        prompt = extraMessage.toString();
      }
    }

    prompt ??= message?.toString();

    if (cancelPayload == null || cancelPayload.isEmpty) {
      throw Exception('POS取消指令为空');
    }

    return CardCancelInstruction(
      payload: cancelPayload,
      prompt: prompt ?? 'POS终端取消完成',
    );
  }

  Map<String, dynamic> _buildCancelPayload(PosPaymentRequest request) {
    final map = request.customPayload ?? const {};

    String readString(String key, {String? fallback}) {
      final value = map[key];
      if (value == null) return fallback ?? '';
      if (value is String) return value;
      if (value is num) return value.toString();
      return fallback ?? '';
    }

    final machineCode = readString('machineCode', fallback: request.order.orderId);

    return {
      'machineCode': machineCode,
      'orderId': request.order.orderId,
    };
  }
}
