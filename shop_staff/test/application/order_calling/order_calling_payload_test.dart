import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/order_calling_payload.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';

void main() {
  final items = [
    const CartItem(
      id: 'tea',
      product: Product(
        id: 1,
        name: '奶茶',
        categoryId: 'drinks',
        price: 300,
        originalPrice: 300,
        tax: 8,
        imageUrl: '',
      ),
      options: [
        SelectedOption(
          groupCode: 'sugar',
          groupName: '糖',
          optionCode: 'half',
          optionName: '半糖',
          extraPrice: 20,
          quantity: 2,
        ),
      ],
      quantity: 3,
      note: '少冰',
    ),
  ];
  test(
    'local order contains quantities, options, notes, total and a stable UUID',
    () {
      final order = OrderSubmissionResult.fromJson({
        'orderId': 123,
        'total': 1020,
        'serialNumber': 'A12',
      });
      final payload = localCallingPayload(
        order: order,
        items: items,
        machineCode: 'M1',
        takeout: true,
        language: 'JP',
        shopCode: 'S1',
      );
      expect(payload['uuid'], 'shopstaff:M1:123');
      expect(payload['order_sn_code'], 'A12');
      expect(payload['order_type'], 'Take_Out');
      expect(payload['total'], 1020);
      final line =
          ((payload['orderLinesMap'] as Map)['0'] as List).single as Map;
      expect(line['name'], '奶茶');
      expect(line['qty'], 3);
      expect(line['price'], 340);
      expect(line['remark'], '少冰');
      expect((line['options'] as Map)['糖'], [
        {'name': '半糖', 'qty': 2, 'price': 20.0, 'optionCode': 'half'},
      ]);
    },
  );
  test(
    'backend ticket UUID, pickup number and printer routing take precedence',
    () {
      final order = OrderSubmissionResult.fromJson({
        'orderId': '1',
        'total': 100,
        'printInfo': {
          'uuid': 'backend-id',
          'order_sn_code': 'B09',
          'orderLinesMap': {
            '12': [
              {'name': 'backend dish'},
            ],
          },
          'remark': 'backend remark',
          'payment_code': 'QR',
        },
      });
      final payload = localCallingPayload(
        order: order,
        items: items,
        machineCode: 'M1',
        takeout: false,
        language: 'JP',
      );
      expect(payload['uuid'], 'backend-id');
      expect(payload['order_sn_code'], 'B09');
      expect((payload['orderLinesMap'] as Map).keys, ['12']);
      expect(payload['payment_code'], 'QR');
    },
  );
  test(
    'IP and port form the internal HTTP endpoint with a default of 3000',
    () {
      expect(
        const OrderCallingSettings(ip: '192.168.1.20').endpoint.toString(),
        'http://192.168.1.20:3000/api/add/order',
      );
      expect(
        const OrderCallingSettings(
          ip: '192.168.1.20',
          port: 3100,
        ).endpoint.toString(),
        'http://192.168.1.20:3100/api/add/order',
      );
      expect(
        const OrderCallingSettings(ip: '::1').endpoint.toString(),
        'http://[::1]:3000/api/add/order',
      );
    },
  );
  test('IP input rejects prefixes, ports, host names and invalid octets', () {
    for (final ip in [
      '',
      'ftp://host',
      'http://192.168.1.20',
      '192.168.1.20:3000',
      'host.local',
      '999.168.1.20',
      '1.2.3',
      ':::',
    ]) {
      expect(
        () => OrderCallingSettings(ip: ip).endpoint,
        throwsFormatException,
        reason: ip,
      );
    }
    for (final port in [0, -1, 65536]) {
      expect(
        () => OrderCallingSettings(ip: '192.168.1.20', port: port).endpoint,
        throwsFormatException,
      );
    }
  });
  test('previously saved address migrates to separate IP and port fields', () {
    final migrated = OrderCallingSettings.fromJson({
      'enabled': true,
      'address': 'http://192.168.1.20:3100/api/add/order',
    });
    expect(migrated.ip, '192.168.1.20');
    expect(migrated.port, 3100);
    expect(migrated.enabled, isTrue);
    expect(migrated.toJson(), {
      'enabled': true,
      'ip': '192.168.1.20',
      'port': 3100,
    });
    expect(
      OrderCallingSettings.fromJson({'address': 'http://192.168.1.20'}).port,
      3000,
    );
    expect(OrderCallingSettings.fromJson({'ip': '192.168.1.20'}).port, 3000);
  });
}
