import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/entities/settlement_order.dart';
import 'package:shop_staff/domain/repositories/settlement_order_repository.dart';
import 'package:shop_staff/presentations/settlement/providers/settlement_order_providers.dart';

void main() {
  test('extracts link order key and fetches with device context', () async {
    final repository = _FakeSettlementOrderRepository();
    final controller = SettlementOrderController(
      repository: repository,
      readMachineCode: () => 'X3V9YPJABVZGAELIZ9',
      readLanguage: () => 'JP',
    );

    final succeeded = await controller.fetch(
      'https://sit-mobile.smartwe.jp/index?p=2Ou79s0VumJdMMjLOPoFA',
    );

    expect(succeeded, isTrue);
    expect(repository.orderKey, '2Ou79s0VumJdMMjLOPoFA');
    expect(repository.language, 'JP');
    expect(repository.machineCode, 'X3V9YPJABVZGAELIZ9');
    expect(controller.state.order?.orderId, 'order-1');
  });

  test('does not call API for an invalid order link', () async {
    final repository = _FakeSettlementOrderRepository();
    final controller = SettlementOrderController(
      repository: repository,
      readMachineCode: () => 'machine-1',
      readLanguage: () => 'JP',
    );

    final succeeded = await controller.fetch('https://example.com/?x=1');

    expect(succeeded, isFalse);
    expect(repository.callCount, 0);
    expect(controller.state.errorCode, 'invalid_code');
  });
}

class _FakeSettlementOrderRepository implements SettlementOrderRepository {
  int callCount = 0;
  String? orderKey;
  String? language;
  String? machineCode;

  @override
  Future<int> confirmOrderTotal(String orderId) async => 100;

  @override
  Future<SettlementOrder> fetchOrder({
    required String orderKey,
    required String language,
    required String machineCode,
  }) async {
    callCount++;
    this.orderKey = orderKey;
    this.language = language;
    this.machineCode = machineCode;
    return const SettlementOrder(
      orderId: 'order-1',
      totalPrice: 100,
      discount: 0,
      voucherAmount: 0,
      payableAmount: 100,
      tableNum: 'A1',
      tableNumText: 'Table',
      orderQty: 1,
      tax1: 10,
      tax2: 0,
      lines: [],
    );
  }
}
