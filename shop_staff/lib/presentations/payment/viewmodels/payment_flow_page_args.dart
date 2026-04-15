import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

class PaymentFlowPageArgs {
  const PaymentFlowPageArgs({
    required this.order,
    required this.channelGroup,
    required this.channelCode,
    required this.paymentMode,
    this.channelDisplayName,
    this.channelConfig,
    this.metadata,
  });

  final OrderSubmissionResult order;
  final String channelGroup;
  final String channelCode;
  final PaymentFlowMode paymentMode;
  final String? channelDisplayName;
  final Map<String, dynamic>? channelConfig;
  final Map<String, dynamic>? metadata;
}
