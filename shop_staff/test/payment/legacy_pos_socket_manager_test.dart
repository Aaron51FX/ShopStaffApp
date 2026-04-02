import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/legacy_pos_socket_manager.dart';

void main() {
  group('LegacyPosSocketManager', () {
    test('routes generic success frames to onSuccess', () async {
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

      final success = Completer<String>();
      var requestedPayData = false;

      await manager.payConnectSocket(
        '3',
        harness.host,
        harness.port,
        'MACHINE',
        'REQ',
        onError: (error) => fail('unexpected error: $error'),
        onLoading: (_) {},
        onLoadingEnd: () {},
        onSuccess: success.complete,
        onRequestPayData: () => requestedPayData = true,
        onDone: (_) {},
        onCancel: (_, __) => fail('unexpected cancel'),
        onTimeOut: () => fail('unexpected timeout'),
      );

      expect(
        await success.future.timeout(const Duration(seconds: 2)),
        _frame(transactionType: '123', result: '000', mpfs: '000'),
      );
      expect(requestedPayData, isTrue);
    });

    test('routes L06 in cancel branch to onCancelWaitResult only', () async {
      final harness = await _PosServerHarness.start(
        onClientData: (socket, _) {
          socket.write(
            _frame(transactionType: '900', result: 'L06', mpfs: '321'),
          );
        },
      );
      addTearDown(harness.dispose);

      final manager = LegacyPosSocketManager();
      addTearDown(manager.dispose);

      final cancelWait = Completer<(String, String)>();

      await manager.payConnectSocket(
        '3',
        harness.host,
        harness.port,
        'MACHINE',
        'REQ',
        onError: (error) => fail('unexpected error: $error'),
        onLoading: (_) {},
        onLoadingEnd: () {},
        onSuccess: (_) => fail('unexpected success'),
        onRequestPayData: () {},
        onDone: (_) {},
        onCancel: (_, __) => fail('unexpected terminal cancel'),
        onCancelWaitResult: (code, mpfs) => cancelWait.complete((code, mpfs)),
        onTimeOut: () => fail('unexpected timeout'),
      );

      expect(await cancelWait.future.timeout(const Duration(seconds: 2)), (
        'L06',
        '321',
      ));
    });

    test('routes fatal result codes to delayed onError', () async {
      final harness = await _PosServerHarness.start(
        onClientData: (socket, _) {
          socket.write(
            _frame(transactionType: '123', result: 'L11', mpfs: '000'),
          );
        },
      );
      addTearDown(harness.dispose);

      final manager = LegacyPosSocketManager();
      addTearDown(manager.dispose);

      final error = Completer<String>();

      await manager.payConnectSocket(
        '3',
        harness.host,
        harness.port,
        'MACHINE',
        'REQ',
        onError: error.complete,
        onLoading: (_) {},
        onLoadingEnd: () {},
        onSuccess: (_) => fail('unexpected success'),
        onRequestPayData: () {},
        onDone: (_) {},
        onCancel: (_, __) => fail('unexpected cancel'),
        onTimeOut: () => fail('unexpected timeout'),
      );

      expect(await error.future.timeout(const Duration(seconds: 5)), 'L11');
    });
  });
}

String _frame({
  required String transactionType,
  required String result,
  required String mpfs,
}) {
  return '311${transactionType}0000$result$mpfs';
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
      subscriptions.add(socket.listen((data) => onClientData(socket, data)));
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
