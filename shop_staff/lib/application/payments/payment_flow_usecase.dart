import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/payment_orchestrator.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';

import 'usecases/cancel_payment_usecase.dart';
import 'usecases/confirm_manual_payment_usecase.dart';
import 'usecases/observe_payment_status_usecase.dart';
import 'usecases/prepare_payment_channel_config_usecase.dart';
import 'usecases/retry_payment_usecase.dart';
import 'usecases/start_payment_usecase.dart';

final paymentFlowUseCaseProvider = Provider<PaymentFlowUseCase>((ref) {
  final orchestrator = ref.watch(paymentOrchestratorProvider);
  return PaymentFlowUseCase(
    orchestrator: orchestrator,
    readSettingsSnapshot: () => ref.read(appSettingsSnapshotProvider),
    logger: Logger('PaymentFlowUseCase'),
  );
});

class PaymentFlowUseCase {
  PaymentFlowUseCase({
    required PaymentOrchestrator orchestrator,
    required AppSettingsSnapshot? Function() readSettingsSnapshot,
    Logger? logger,
  })  : _start = StartPaymentUseCase(
          orchestrator: orchestrator,
          prepareConfig: PreparePaymentChannelConfigUseCase(
            readSettingsSnapshot: readSettingsSnapshot,
            logger: Logger('PreparePaymentChannelConfigUseCase'),
          ),
          logger: Logger('StartPaymentUseCase'),
        ),
        _cancel = CancelPaymentUseCase(orchestrator: orchestrator),
        _confirmManual = ConfirmManualPaymentUseCase(orchestrator: orchestrator),
        _observe = ObservePaymentStatusUseCase(orchestrator: orchestrator),
        _retry = RetryPaymentUseCase(
          cancelPayment: CancelPaymentUseCase(orchestrator: orchestrator),
          startPayment: StartPaymentUseCase(
            orchestrator: orchestrator,
            prepareConfig: PreparePaymentChannelConfigUseCase(
              readSettingsSnapshot: readSettingsSnapshot,
              logger: Logger('PreparePaymentChannelConfigUseCase'),
            ),
            logger: Logger('StartPaymentUseCase'),
          ),
        ),
        _logger = logger ?? Logger('PaymentFlowUseCase');

  final StartPaymentUseCase _start;
  final CancelPaymentUseCase _cancel;
  final ConfirmManualPaymentUseCase _confirmManual;
  final ObservePaymentStatusUseCase _observe;
  final RetryPaymentUseCase _retry;
  final Logger _logger;

  PaymentFlowStartResult start(PaymentFlowPageArgs args) {
    _logger.fine('Start payment flow facade: ${args.channelGroup}');
    return _start(args);
  }

  Stream<PaymentStatus> observe(String sessionId) => _observe(sessionId);

  Future<void> cancel(String sessionId) => _cancel(sessionId);

  Future<void> finalize(String sessionId) => _confirmManual(sessionId);

  Future<PaymentFlowStartResult> retry({
    required PaymentFlowPageArgs args,
    String? previousSessionId,
  }) {
    return _retry(args: args, previousSessionId: previousSessionId);
  }
}
