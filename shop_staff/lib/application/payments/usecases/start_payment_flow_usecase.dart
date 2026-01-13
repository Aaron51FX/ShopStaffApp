export 'start_payment_usecase.dart' show PaymentFlowStartResult, StartPaymentUseCase;
export 'prepare_payment_channel_config_usecase.dart' show PreparePaymentChannelConfigUseCase;

import 'start_payment_usecase.dart';

@Deprecated('Use StartPaymentUseCase')
class StartPaymentFlowUseCase extends StartPaymentUseCase {
  StartPaymentFlowUseCase({
    required super.orchestrator,
    required super.prepareConfig,
    super.logger,
  });
}
