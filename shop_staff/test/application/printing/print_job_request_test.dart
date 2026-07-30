import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/printing/models/print_job_request.dart';
import 'package:shop_staff/data/models/print_info.dart';

void main() {
  test('bookkeeping payment method overrides API print value', () {
    const source = PrintInfoDocument(payMethod: '現金支払');
    const request = PrintJobRequest(
      machineCode: 'M001',
      printers: [],
      paymentMethodOverride: 'QR Code（オフライン）',
    );

    final result = request.applyDocumentOverrides(source);

    expect(result.payMethod, 'QR Code（オフライン）');
    expect(source.payMethod, '現金支払');
  });

  test('empty payment method override preserves API print value', () {
    const source = PrintInfoDocument(payMethod: '現金支払');
    const request = PrintJobRequest(machineCode: 'M001', printers: []);

    expect(request.applyDocumentOverrides(source), same(source));
  });
}
