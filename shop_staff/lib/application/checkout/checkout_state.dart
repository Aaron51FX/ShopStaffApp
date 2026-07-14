import 'package:shop_staff/application/checkout/models/checkout_draft.dart';
import 'package:shop_staff/application/checkout/models/checkout_payment_request.dart';
import 'package:shop_staff/application/printing/models/print_job_request.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

enum CheckoutStage {
  idle,
  selectingPayment,
  submittingOrder,
  paymentReady,
  paying,
  paymentFailed,
  paymentIndeterminate,
  printReady,
  printing,
  completed,
}

class CheckoutState {
  const CheckoutState({
    this.stage = CheckoutStage.idle,
    this.draft,
    this.order,
    this.submittedTotal,
    this.paymentRequest,
    this.paymentResult,
    this.printRequest,
    this.warning,
    this.error,
  });

  static const Object _unset = Object();

  final CheckoutStage stage;
  final CheckoutDraft? draft;
  final OrderSubmissionResult? order;
  final double? submittedTotal;
  final CheckoutPaymentRequest? paymentRequest;
  final PaymentResult? paymentResult;
  final PrintJobRequest? printRequest;
  final String? warning;
  final String? error;

  bool get hasActiveCheckout => draft != null && stage != CheckoutStage.idle;
  bool get isBusy =>
      stage == CheckoutStage.submittingOrder || stage == CheckoutStage.printing;

  CheckoutState copyWith({
    CheckoutStage? stage,
    Object? draft = _unset,
    Object? order = _unset,
    Object? submittedTotal = _unset,
    Object? paymentRequest = _unset,
    Object? paymentResult = _unset,
    Object? printRequest = _unset,
    Object? warning = _unset,
    Object? error = _unset,
  }) {
    return CheckoutState(
      stage: stage ?? this.stage,
      draft: identical(draft, _unset) ? this.draft : draft as CheckoutDraft?,
      order: identical(order, _unset)
          ? this.order
          : order as OrderSubmissionResult?,
      submittedTotal: identical(submittedTotal, _unset)
          ? this.submittedTotal
          : submittedTotal as double?,
      paymentRequest: identical(paymentRequest, _unset)
          ? this.paymentRequest
          : paymentRequest as CheckoutPaymentRequest?,
      paymentResult: identical(paymentResult, _unset)
          ? this.paymentResult
          : paymentResult as PaymentResult?,
      printRequest: identical(printRequest, _unset)
          ? this.printRequest
          : printRequest as PrintJobRequest?,
      warning: identical(warning, _unset) ? this.warning : warning as String?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}
