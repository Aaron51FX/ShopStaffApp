import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';

void main() {
  test('CashRegisterClosureSummary parses staffRejishime payload', () {
    final summary = CashRegisterClosureSummary.fromJson({
      'machineCode': 'M001',
      'shopCode': 'S001',
      'shopName': 'Shop',
      'startTime': '2026-06-08 09:00:00',
      'endTime': '2026-06-08 21:00:00',
      'printTime': '2026-06-08 21:05:00',
      'verifyCode': '1234',
      'verifyEmail': 'admin@example.com',
      'verifyUserName': 'Admin',
      'cashInfo': {
        '1000': {'backup': '1', 'income': '2', 'remain': '3'},
      },
      'cashInfoGlory': {'1000': '3', '500': 2.2},
      'aliPayTotal': 10,
      'au_PayTotal': '20',
      'cashTotal': 30.4,
      'creditCardTotal': 40,
      'd_PayTotal': 50,
      'discountTotal': 60,
      'm_PayTotal': 70,
      'noTaxTotal': 80,
      'payPayTotal': 90,
      'qty': 1,
      'qtyA': 2,
      'qtyB': 3,
      'r_PayTotal': 100,
      'repaymentQty': 4,
      'repaymentTotal': 110,
      'taxTotal': 120,
      'taxTotalA': 130,
      'taxTotalB': 140,
      'total': 150,
      'trafficTotal': 160,
      'voucherAmountTotal': 170,
      'wechatTotal': 180,
    });

    expect(summary.machineCode, 'M001');
    expect(summary.verifyEmail, 'admin@example.com');
    expect(summary.cashInfo['1000']?.income, '2');
    expect(summary.cashInfoGlory['1000'], 3);
    expect(summary.cashInfoGlory['500'], 2);
    expect(summary.auPayTotal, 20);
    expect(summary.cashTotal, 30);
    expect(summary.dPayTotal, 50);
    expect(summary.mPayTotal, 70);
    expect(summary.rPayTotal, 100);
    expect(summary.total, 150);
  });
}
