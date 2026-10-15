import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/data/repositories_impl/bookkeeping_order_repository_impl.dart';
import 'package:shop_staff/data/repositories_impl/order_repository_impl.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';

class _Remote extends PosRemoteDataSource {
  _Remote() : super(DioClient.create(AppConfig.forEnv(AppEnvironment.staging)));
  dynamic response = {
    'code': 200,
    'data': {'orderId': 123, 'total': 300, 'orderSnCode': 'A3'},
  };
  @override
  Future<dynamic> submitOfflineOrderV1(Map<String, dynamic> payload) async =>
      response;
  @override
  Future<dynamic> submitOrderV4(Map<String, dynamic> payload) async => response;
}

class _Calling implements OrderCallingService {
  final orders = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<void> enqueueOrder(
    Map<String, dynamic> payload, {
    required String source,
    String event = 'message',
  }) async {
    if (fail) throw StateError('storage failed');
    orders.add(payload);
  }
}

void main() {
  for (final offline in [true, false]) {
    test(
      '${offline ? 'offline' : 'standard'} repository forwards only successful submissions and isolates calling failure',
      () async {
        final remote = _Remote();
        final calling = _Calling();
        final offlineRepository = BookkeepingOrderRepositoryImpl(
          remote,
          orderCallingService: calling,
        );
        final standardRepository = OrderRepositoryImpl(
          remote,
          orderCallingService: calling,
        );
        Future<dynamic> submit() => offline
            ? offlineRepository.submitOfflineOrder(
                items: [],
                machineCode: 'M1',
                language: 'JP',
                takeout: false,
                total: 300,
              )
            : standardRepository.submitOrder(
                items: [],
                machineCode: 'M1',
                language: 'JP',
                takeout: false,
                total: 300,
              );
        final result = await submit();
        expect(result.orderId, '123');
        expect(calling.orders.single['order_sn_code'], 'A3');
        calling.fail = true;
        expect((await submit()).orderId, '123');
        calling.fail = false;
        remote.response = {
          'code': 500,
          'data': {'orderId': 456},
        };
        await submit();
        expect(calling.orders, hasLength(1));
        remote.response = {'code': 200, 'data': {}};
        await submit();
        expect(calling.orders, hasLength(1));
      },
    );
  }
}
