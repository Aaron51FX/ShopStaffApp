import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/application/checkout/checkout_providers.dart';
import 'package:shop_staff/application/payments/payment_flow_usecase.dart';
import 'package:shop_staff/application/payments/selection/prepare_payment_selection_usecase.dart';
import 'package:shop_staff/application/payments/usecases/record_abnormal_payment_exit_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/presentations/payment/controllers/payment_flow_controller.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

final paymentFlowUseCaseProvider = Provider<PaymentFlowUseCase>((ref) {
  return PaymentFlowUseCase(
    orchestrator: ref.watch(paymentOrchestratorProvider),
    readSettingsSnapshot: () => ref.read(appSettingsSnapshotProvider),
    logger: Logger('PaymentFlowUseCase'),
  );
});

final preparePaymentSelectionUseCaseProvider =
    Provider<PreparePaymentSelectionUseCase>((ref) {
      return const PreparePaymentSelectionUseCase();
    });

final paymentSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<PaymentFlowController, PaymentSessionState, PaymentFlowPageArgs>((
      ref,
      args,
    ) {
      KeepAliveLink? keepAlive;
      final controller = PaymentFlowController(
        args,
        useCase: ref.read(paymentFlowUseCaseProvider),
        recordAbnormalExit: RecordAbnormalPaymentExitUseCase(
          orders: ref.read(localOrdersUseCasesProvider),
        ),
        checkoutCoordinator: ref.read(checkoutCoordinatorProvider.notifier),
        qrScanner: ref.read(qrScannerServiceProvider),
        onSessionActive: () => keepAlive ??= ref.keepAlive(),
        onTerminal: () {
          keepAlive?.close();
          keepAlive = null;
        },
      );
      scheduleMicrotask(() => unawaited(controller.start()));
      return controller;
    });
