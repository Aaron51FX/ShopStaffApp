import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/payment_backend_gateway.dart';
import 'package:shop_staff/data/services/payment_channel_support.dart';
import 'package:shop_staff/data/services/payment_flows/qr_payment_flow.dart';
import 'package:shop_staff/data/services/pos_card_payment_gateway.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

void main() {
  test('empty requestInfo uses result without reading POS settings', () async {
    final terminal = _FakePosPaymentService();
    var settingsReads = 0;
    PosPaymentRequest? topayRequest;
    final flow = _flow(
      terminal: terminal,
      response: _response(result: true, requestInfo: ''),
      onRequest: (request) => topayRequest = request,
      readSettings: () {
        settingsReads += 1;
        return const PosTerminalSettings(posIp: '192.0.2.10', posPort: 1234);
      },
    );

    final result = await flow.start(_context()).result;

    expect(result.status, PaymentStatusType.success);
    expect(settingsReads, 0);
    expect(terminal.startedRequests, isEmpty);
    expect(topayRequest?.customPayload, containsPair('payType', ''));
  });

  test('empty requestInfo uses failed result and exception message', () async {
    final terminal = _FakePosPaymentService();
    var settingsReads = 0;
    final flow = _flow(
      terminal: terminal,
      response: _response(
        result: false,
        requestInfo: '',
        exceptionMessage: 'payment rejected',
      ),
      readSettings: () {
        settingsReads += 1;
        return const PosTerminalSettings(posIp: '192.0.2.10', posPort: 1234);
      },
    );

    final result = await flow.start(_context()).result;

    expect(result.status, PaymentStatusType.failure);
    expect(settingsReads, 0);
    expect(terminal.startedRequests, isEmpty);
  });

  test(
    'requestInfo with empty exception starts POS without checking result',
    () async {
      final terminal = _FakePosPaymentService();
      var settingsReads = 0;
      final flow = _flow(
        terminal: terminal,
        response: _response(
          result: false,
          requestInfo: 'paypay-terminal-request',
          exceptionMessage: '',
        ),
        readSettings: () {
          settingsReads += 1;
          return const PosTerminalSettings(posIp: '192.0.2.10', posPort: 1234);
        },
      );

      final result = await flow.start(_context()).result;

      expect(result.status, PaymentStatusType.success);
      expect(settingsReads, 1);
      expect(terminal.startedRequests, hasLength(1));
      expect(
        terminal.startedRequests.single.customPayload,
        containsPair('posIp', '192.0.2.10'),
      );
      expect(
        terminal.startedRequests.single.customPayload,
        containsPair('posPort', 1234),
      );
    },
  );

  test('requestInfo with exception fails without starting POS', () async {
    final terminal = _FakePosPaymentService();
    var settingsReads = 0;
    final flow = _flow(
      terminal: terminal,
      response: _response(
        result: true,
        requestInfo: 'paypay-terminal-request',
        exceptionMessage: 'unsupported QR code',
      ),
      readSettings: () {
        settingsReads += 1;
        return const PosTerminalSettings(posIp: '192.0.2.10', posPort: 1234);
      },
    );

    final result = await flow.start(_context()).result;

    expect(result.status, PaymentStatusType.failure);
    expect(result.message, 'unsupported QR code');
    expect(settingsReads, 0);
    expect(terminal.startedRequests, isEmpty);
  });
}

QrPaymentFlow _flow({
  required _FakePosPaymentService terminal,
  required CardPaymentRequestData response,
  required PosTerminalSettings? Function() readSettings,
  void Function(PosPaymentRequest request)? onRequest,
}) {
  return QrPaymentFlow(
    scannerService: _FakeScannerService(),
    backendGateway: _FakePaymentBackendGateway(),
    posPaymentService: terminal,
    createPaymentRequest: (request) async {
      onRequest?.call(request);
      return response;
    },
    readPosTerminalSettings: readSettings,
  );
}

CardPaymentRequestData _response({
  bool? result,
  String? requestInfo,
  String? exceptionMessage,
}) {
  return CardPaymentRequestData(
    requestInfo: requestInfo,
    reportPayload: const <String, dynamic>{},
    exceptionMessage: exceptionMessage,
    success: true,
    data: <String, dynamic>{if (result != null) 'result': result},
  );
}

PaymentContext _context() {
  return const PaymentContext(
    order: OrderSubmissionResult(
      orderId: 'ORDER-QR-1',
      tax1: 0,
      baseTax1: 1000,
      tax2: 0,
      baseTax2: 0,
      total: 1000,
    ),
    channel: PaymentChannel(
      group: PaymentChannels.qr,
      code: 'QR',
      displayName: 'QR Code',
    ),
    mode: PaymentFlowMode.real,
    metadata: <String, dynamic>{'machineCode': 'M001'},
  );
}

class _FakeScannerService implements QrScannerService {
  @override
  Future<String> acquireCode(PaymentContext context) async => 'QR-CODE';

  @override
  Future<void> cancelScan() async {}
}

class _FakePaymentBackendGateway implements PaymentBackendGateway {
  @override
  Future<void> confirmPayment(
    PaymentContext context,
    Map<String, dynamic> payload,
  ) async {}
}

class _FakePosPaymentService implements PosPaymentService {
  final List<PosPaymentRequest> startedRequests = <PosPaymentRequest>[];

  @override
  Future<PosPaymentSession> startPayment(PosPaymentRequest request) async {
    startedRequests.add(request);
    return const PosPaymentSession(
      sessionId: 'pos-session-1',
      initialStatus: PosPaymentStatus(type: PosPaymentStatusType.pending),
    );
  }

  @override
  Stream<PosPaymentStatus> watchStatus(String sessionId) {
    return Stream<PosPaymentStatus>.value(
      const PosPaymentStatus(type: PosPaymentStatusType.success),
    );
  }

  @override
  Future<void> cancel(String sessionId) async {}
}
