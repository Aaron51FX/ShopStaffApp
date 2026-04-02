import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/data/services/pos_card_payment_gateway.dart';
import 'package:shop_staff/data/services/pos_payment_service_impl.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

void main() {
  group('PosPaymentServiceImpl', () {
    test(
      'L06 keeps the POS session active until the final terminal result arrives',
      () async {
        final harness = await _PosServerHarness.start(
          onClientData: (socket, data) {
            final payload = String.fromCharCodes(data);
            if (payload == 'REQ') {
              return;
            }
            if (payload == 'CANCEL') {
              _safeWrite(
                socket,
                _frame(transactionType: '900', result: '000', mpfs: '000'),
              );
              Future<void>.delayed(const Duration(milliseconds: 40), () {
                _safeWrite(
                  socket,
                  _frame(transactionType: '900', result: 'L06', mpfs: '321'),
                );
              });
              Future<void>.delayed(const Duration(milliseconds: 80), () {
                _safeWrite(
                  socket,
                  _frame(transactionType: '123', result: '000', mpfs: '000'),
                );
              });
            }
          },
        );
        addTearDown(harness.dispose);

        final service = PosPaymentServiceImpl(
          cardGateway: _FakePosCardPaymentGateway(
            requestData: 'REQ',
            cancelPayload: 'CANCEL',
          ),
        );

        final session = await service.startPayment(
          PosPaymentRequest(
            order: _testOrder(),
            channelGroup: PaymentChannels.card,
            channelCode: 'CARD',
            customPayload: {
              'paymentCode': '3',
              'posIp': harness.host,
              'posPort': harness.port,
              'machineCode': 'MACHINE',
            },
          ),
        );

        final statuses = <PosPaymentStatus>[];
        final waitingUser = Completer<void>();
        final success = Completer<void>();
        final sub = service.watchStatus(session.sessionId).listen((status) {
          statuses.add(status);
          if (status.messageKey == PaymentMessageKeys.posWaitingUser &&
              !waitingUser.isCompleted) {
            waitingUser.complete();
          }
          if (status.type == PosPaymentStatusType.success &&
              !success.isCompleted) {
            success.complete();
          }
        });
        addTearDown(sub.cancel);

        await waitingUser.future.timeout(const Duration(seconds: 4));
        await service.cancel(session.sessionId);
        await success.future.timeout(const Duration(seconds: 4));

        final waitingIndex = statuses.indexWhere(
          (status) =>
              status.messageKey == PaymentMessageKeys.posWaitingUser &&
              status.phase == PaymentPhase.waitingUser,
        );
        final cancelProcessingIndex = statuses.indexWhere(
          (status) =>
              status.messageKey == PaymentMessageKeys.posCancelProcessing &&
              status.phase == PaymentPhase.sending,
        );
        final finalizingIndex = statuses.indexWhere(
          (status) =>
              status.messageKey == PaymentMessageKeys.posFinalizing &&
              status.phase == PaymentPhase.sending,
        );
        final waitResultIndex = statuses.indexWhere(
          (status) =>
              status.type == PosPaymentStatusType.processing &&
              status.messageKey == PaymentMessageKeys.posCancelWaitResult &&
              status.phase == PaymentPhase.waitingTerminalResult,
        );
        final successIndex = statuses.indexWhere(
          (status) =>
              status.type == PosPaymentStatusType.success &&
              status.messageKey == PaymentMessageKeys.posPaymentSuccess,
        );

        expect(waitingIndex, greaterThanOrEqualTo(0));
        expect(cancelProcessingIndex, greaterThan(waitingIndex));
        expect(finalizingIndex, greaterThan(cancelProcessingIndex));
        expect(waitResultIndex, greaterThan(finalizingIndex));
        expect(successIndex, greaterThan(waitResultIndex));
      },
    );

    test(
      'L11 after cancel follow-up finishes as cancelled without surfacing failure',
      () async {
        final harness = await _PosServerHarness.start(
          onClientData: (socket, data) {
            final payload = String.fromCharCodes(data);
            if (payload == 'REQ') {
              return;
            }
            if (payload == 'CANCEL') {
              _safeWrite(
                socket,
                _frame(transactionType: '900', result: '000', mpfs: '000'),
              );
              Future<void>.delayed(const Duration(milliseconds: 40), () {
                _safeWrite(
                  socket,
                  _frame(transactionType: '123', result: 'L11', mpfs: '000'),
                );
              });
            }
          },
        );
        addTearDown(harness.dispose);

        final service = PosPaymentServiceImpl(
          cardGateway: _FakePosCardPaymentGateway(
            requestData: 'REQ',
            cancelPayload: 'CANCEL',
          ),
        );

        final session = await service.startPayment(
          PosPaymentRequest(
            order: _testOrder(),
            channelGroup: PaymentChannels.card,
            channelCode: 'CARD',
            customPayload: {
              'paymentCode': '3',
              'posIp': harness.host,
              'posPort': harness.port,
              'machineCode': 'MACHINE',
            },
          ),
        );

        final statuses = <PosPaymentStatus>[];
        final waitingUser = Completer<void>();
        final cancelled = Completer<void>();
        final sub = service.watchStatus(session.sessionId).listen((status) {
          statuses.add(status);
          if (status.messageKey == PaymentMessageKeys.posWaitingUser &&
              !waitingUser.isCompleted) {
            waitingUser.complete();
          }
          if (status.type == PosPaymentStatusType.cancelled &&
              !cancelled.isCompleted) {
            cancelled.complete();
          }
        });
        addTearDown(sub.cancel);

        await waitingUser.future.timeout(const Duration(seconds: 4));
        await service.cancel(session.sessionId);
        await cancelled.future.timeout(const Duration(seconds: 4));

        expect(
          statuses.any((status) => status.type == PosPaymentStatusType.failure),
          isFalse,
        );
        expect(
          statuses.any(
            (status) =>
                status.type == PosPaymentStatusType.cancelled &&
                status.messageKey == PaymentMessageKeys.posTerminalCancelled &&
                status.errorCode == 'L11' &&
                status.phase == PaymentPhase.waitingTerminalResult,
          ),
          isTrue,
        );
      },
    );
  });
}

OrderSubmissionResult _testOrder() {
  return const OrderSubmissionResult(
    orderId: 'ORDER-1',
    tax1: 0,
    baseTax1: 0,
    tax2: 0,
    baseTax2: 0,
    total: 1000,
  );
}

String _frame({
  required String transactionType,
  required String result,
  required String mpfs,
}) {
  return '311${transactionType}0000$result$mpfs';
}

void _safeWrite(Socket socket, String payload) {
  try {
    socket.write(payload);
  } catch (_) {}
}

class _FakePosCardPaymentGateway extends PosCardPaymentGateway {
  _FakePosCardPaymentGateway({
    required this.requestData,
    required this.cancelPayload,
  }) : super(
         PosRemoteDataSource(
           DioClient.create(AppConfig.forEnv(AppEnvironment.production)),
         ),
       );

  final String requestData;
  final String cancelPayload;

  @override
  Future<CardPaymentRequestData> createPaymentRequest(
    PosPaymentRequest request,
  ) async {
    return CardPaymentRequestData(
      requestInfo: requestData,
      reportPayload: const <String, dynamic>{},
      success: true,
      data: const <String, dynamic>{'requestInfo': 'REQ'},
    );
  }

  @override
  Future<CardCancelInstruction> fetchCancelInstruction(
    PosPaymentRequest request,
  ) async {
    return CardCancelInstruction(payload: cancelPayload);
  }

  @override
  Future<void> reportPayment({
    required Map<String, dynamic> reportPayload,
    required String paymentInfo,
  }) async {}
}

class _PosServerHarness {
  _PosServerHarness(this._server, this._subscriptions);

  final ServerSocket _server;
  final List<StreamSubscription<dynamic>> _subscriptions;

  String get host => _server.address.address;
  int get port => _server.port;

  static Future<_PosServerHarness> start({
    required void Function(Socket socket, List<int> data) onClientData,
  }) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final subscriptions = <StreamSubscription<dynamic>>[];
    final acceptSub = server.listen((socket) {
      subscriptions.add(
        socket.listen(
          (data) => onClientData(socket, data),
          onError: (_) {},
          cancelOnError: true,
        ),
      );
    });
    subscriptions.add(acceptSub);
    return _PosServerHarness(server, subscriptions);
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _server.close();
  }
}
