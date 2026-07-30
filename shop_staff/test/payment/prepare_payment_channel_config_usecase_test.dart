import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/checkout/models/checkout_payment_request.dart';
import 'package:shop_staff/application/payments/usecases/prepare_payment_channel_config_usecase.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

void main() {
  test('real QR payment does not read or inject POS settings before topay', () {
    var settingsReads = 0;
    final useCase = PreparePaymentChannelConfigUseCase(
      readSettingsSnapshot: () {
        settingsReads += 1;
        return null;
      },
    );

    final config = useCase(
      const CheckoutPaymentRequest(
        order: OrderSubmissionResult(
          orderId: 'ORDER-QR-1',
          tax1: 0,
          baseTax1: 1000,
          tax2: 0,
          baseTax2: 0,
          total: 1000,
        ),
        channelGroup: PaymentChannels.qr,
        channelCode: 'QR',
        paymentMode: PaymentFlowMode.real,
        metadata: <String, dynamic>{'machineCode': 'M001'},
      ),
    );

    expect(settingsReads, 0);
    expect(config, isNot(contains('posIp')));
    expect(config, isNot(contains('posPort')));
  });
}
