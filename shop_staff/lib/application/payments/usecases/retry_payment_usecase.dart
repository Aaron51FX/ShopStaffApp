import 'package:logging/logging.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';

import 'cancel_payment_usecase.dart';
import 'start_payment_usecase.dart';

class RetryPaymentUseCase {
  RetryPaymentUseCase({
    required CancelPaymentUseCase cancelPayment,
    required StartPaymentUseCase startPayment,
    Logger? logger,
  })  : _cancelPayment = cancelPayment,
        _startPayment = startPayment,
        _logger = logger ?? Logger('RetryPaymentUseCase');

  final CancelPaymentUseCase _cancelPayment;
  final StartPaymentUseCase _startPayment;
  final Logger _logger;

  Future<PaymentFlowStartResult> call({
    required PaymentFlowPageArgs args,
    String? previousSessionId,
  }) async {
    if (previousSessionId != null && previousSessionId.isNotEmpty) {
      try {
        await _cancelPayment(previousSessionId);
      } catch (e, stack) {
        // Best-effort: ignore cancellation failures on retry.
        _logger.fine('Retry pre-cancel failed: $e', e, stack);
      }
    }
    return _startPayment(args);
  }
}
