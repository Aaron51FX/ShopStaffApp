import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/legacy_pos_socket_manager.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

void main() {
  group('LegacyPos transport events', () {
    test('emits connecting and sending events before success', () async {
      final harness = await _PosServerHarness.start(
        onClientData: (socket, _) {
          socket.write(
            _frame(transactionType: '123', result: '000', mpfs: '000'),
          );
        },
      );
      addTearDown(harness.dispose);

      final manager = LegacyPosSocketManager();
      addTearDown(manager.dispose);

      final run = manager.startTransportSession(
        payment: '3',
        posIp: harness.host,
        posPort: harness.port,
        machineCode: 'MACHINE',
        requestData: 'REQ',
      );

      final events = <LegacyPosTransportEvent>[];
      final success = Completer<void>();
      final sub = run.events.listen((event) {
        events.add(event);
        if (event.type == LegacyPosTransportEventType.success &&
            !success.isCompleted) {
          success.complete();
        }
      });
      addTearDown(sub.cancel);

      await success.future.timeout(const Duration(seconds: 2));

      final types = events.map((event) => event.type).toList();
      expect(types, contains(LegacyPosTransportEventType.connecting));
      expect(types, contains(LegacyPosTransportEventType.connected));
      expect(
        events.any(
          (event) =>
              event.type == LegacyPosTransportEventType.writeStarted &&
              event.action == PosAction.writePay &&
              event.phase == PaymentPhase.sending,
        ),
        isTrue,
      );
      expect(
        events.any(
          (event) =>
              event.type == LegacyPosTransportEventType.writeCompleted &&
              event.action == PosAction.writePay &&
              event.phase == PaymentPhase.sending,
        ),
        isTrue,
      );
      expect(
        events.any(
          (event) =>
              event.type == LegacyPosTransportEventType.loading &&
              event.loadingState == LegacyPosLoadingState.terminalProcessing &&
              event.phase == PaymentPhase.waitingUser,
        ),
        isTrue,
      );
    });

    test('emits waiting-for-terminal event with waitingUser phase', () async {
      final harness = await _PosServerHarness.start(onClientData: (_, __) {});
      addTearDown(harness.dispose);

      final manager = LegacyPosSocketManager();
      addTearDown(manager.dispose);

      final run = manager.startTransportSession(
        payment: '3',
        posIp: harness.host,
        posPort: harness.port,
        machineCode: 'MACHINE',
        requestData: 'REQ',
      );

      final waiting = Completer<LegacyPosTransportEvent>();
      final sub = run.events.listen((event) {
        if (event.type == LegacyPosTransportEventType.waitingForTerminal &&
            !waiting.isCompleted) {
          waiting.complete(event);
        }
      });
      addTearDown(sub.cancel);

      final event = await waiting.future.timeout(const Duration(seconds: 3));
      expect(event.phase, PaymentPhase.waitingUser);
    });

    test('keeps waiting after L06 and still delivers final success', () async {
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

      final manager = LegacyPosSocketManager();
      addTearDown(manager.dispose);

      final run = manager.startTransportSession(
        payment: '3',
        posIp: harness.host,
        posPort: harness.port,
        machineCode: 'MACHINE',
        requestData: 'REQ',
      );

      final events = <LegacyPosTransportEvent>[];
      final success = Completer<void>();
      final sub = run.events.listen((event) {
        events.add(event);
        if (event.type == LegacyPosTransportEventType.waitingForTerminal) {
          unawaited(manager.write(PosAction.cancel, 'CANCEL'));
        }
        if (event.type == LegacyPosTransportEventType.success &&
            !success.isCompleted) {
          success.complete();
        }
      });
      addTearDown(sub.cancel);

      await success.future.timeout(const Duration(seconds: 3));

      final ackIndex = events.indexWhere(
        (event) =>
            event.type == LegacyPosTransportEventType.cancelAcknowledged &&
            event.phase == PaymentPhase.sending,
      );
      final waitIndex = events.indexWhere(
        (event) =>
            event.type == LegacyPosTransportEventType.cancelWaitResult &&
            event.resultCode == 'L06' &&
            event.mpfsCode == '321' &&
            event.phase == PaymentPhase.waitingTerminalResult,
      );
      final successIndex = events.indexWhere(
        (event) =>
            event.type == LegacyPosTransportEventType.success &&
            event.phase == PaymentPhase.waitingUser,
      );

      expect(ackIndex, greaterThanOrEqualTo(0));
      expect(waitIndex, greaterThan(ackIndex));
      expect(successIndex, greaterThan(waitIndex));
    });

    test(
      'treats L11 after cancel follow-up as cancelled instead of error',
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

        final manager = LegacyPosSocketManager();
        addTearDown(manager.dispose);

        final run = manager.startTransportSession(
          payment: '3',
          posIp: harness.host,
          posPort: harness.port,
          machineCode: 'MACHINE',
          requestData: 'REQ',
        );

        final events = <LegacyPosTransportEvent>[];
        final cancelled = Completer<void>();
        final sub = run.events.listen((event) {
          events.add(event);
          if (event.type == LegacyPosTransportEventType.waitingForTerminal) {
            unawaited(manager.write(PosAction.cancel, 'CANCEL'));
          }
          if (event.type == LegacyPosTransportEventType.cancelled &&
              !cancelled.isCompleted) {
            cancelled.complete();
          }
        });
        addTearDown(sub.cancel);

        await cancelled.future.timeout(const Duration(seconds: 3));

        expect(
          events.any(
            (event) => event.type == LegacyPosTransportEventType.error,
          ),
          isFalse,
        );
        expect(
          events.any(
            (event) =>
                event.type == LegacyPosTransportEventType.cancelled &&
                event.resultCode == 'L11' &&
                event.phase == PaymentPhase.waitingTerminalResult,
          ),
          isTrue,
        );
      },
    );
  });
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
