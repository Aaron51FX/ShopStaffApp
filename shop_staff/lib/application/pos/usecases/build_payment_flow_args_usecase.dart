import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';

/// Compatibility alias for callers not yet migrated to checkout naming.
@Deprecated('Use BuildCheckoutPaymentRequestUseCase')
typedef BuildPaymentFlowArgsUseCase = BuildCheckoutPaymentRequestUseCase;

@Deprecated('Use buildCheckoutPaymentRequestUseCaseProvider')
final buildPaymentFlowArgsUseCaseProvider =
    Provider<BuildCheckoutPaymentRequestUseCase>((ref) {
      return ref.watch(buildCheckoutPaymentRequestUseCaseProvider);
    });
