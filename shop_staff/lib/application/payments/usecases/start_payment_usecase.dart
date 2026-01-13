import 'package:logging/logging.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';

import 'prepare_payment_channel_config_usecase.dart';

class PaymentFlowStartResult {
  const PaymentFlowStartResult({
    required this.session,
    required this.statuses,
    required this.result,
  });

  final PaymentSession session;
  final Stream<PaymentStatus> statuses;
  final Future<PaymentResult> result;
}

/// Starts a payment flow based on UI args.
class StartPaymentUseCase {
  StartPaymentUseCase({
    required PaymentOrchestrator orchestrator,
    required PreparePaymentChannelConfigUseCase prepareConfig,
    Logger? logger,
  })  : _orchestrator = orchestrator,
        _prepareConfig = prepareConfig,
        _logger = logger ?? Logger('StartPaymentUseCase');

  final PaymentOrchestrator _orchestrator;
  final PreparePaymentChannelConfigUseCase _prepareConfig;
  final Logger _logger;

  PaymentFlowStartResult call(PaymentFlowPageArgs args) {
    final config = _prepareConfig(args);

    final channel = PaymentChannel(
      group: args.channelGroup,
      code: args.channelCode,
      displayName: args.channelDisplayName,
    );
    final context = PaymentContext(
      order: args.order,
      channel: channel,
      channelConfig: config,
      metadata: args.metadata,
    );

    _logger.fine('Starting payment flow: ${args.channelGroup}');
    final session = _orchestrator.start(context);
    return PaymentFlowStartResult(
      session: session,
      statuses: _orchestrator.watch(session.sessionId),
      result: _orchestrator.result(session.sessionId),
    );
  }
}
