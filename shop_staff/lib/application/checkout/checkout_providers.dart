import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/application/checkout/checkout_coordinator.dart';
import 'package:shop_staff/application/checkout/checkout_state.dart';
import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/data/providers.dart';

final checkoutCoordinatorProvider =
    StateNotifierProvider<CheckoutCoordinator, CheckoutState>((ref) {
      return CheckoutCoordinator(
        submitOrder: ref.watch(submitOrderUseCaseProvider),
        localOrders: ref.watch(localOrdersUseCasesProvider),
        buildPaymentRequest: ref.watch(
          buildCheckoutPaymentRequestUseCaseProvider,
        ),
        completePayment: ref.watch(completeCheckoutPaymentUseCaseProvider),
        readSettings: () => ref.read(appSettingsSnapshotProvider),
        logger: Logger('CheckoutCoordinator'),
      );
    });
