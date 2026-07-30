import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/application/checkout/checkout_state.dart';
import 'package:shop_staff/application/checkout/models/checkout_draft.dart';
import 'package:shop_staff/application/checkout/models/checkout_payment_request.dart';
import 'package:shop_staff/application/checkout/usecases/complete_checkout_payment_usecase.dart';
import 'package:shop_staff/application/checkout/usecases/build_checkout_payment_request_usecase.dart';
import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/application/pos/usecases/submit_order_usecase.dart';
import 'package:shop_staff/application/printing/models/print_job_request.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

/// Application-level coordinator for the macro checkout lifecycle.
///
/// Menu, payment, and printing keep their own internal state. This class only
/// transfers immutable outputs between them and owns cross-feature ordering.
class CheckoutCoordinator extends StateNotifier<CheckoutState> {
  CheckoutCoordinator({
    required SubmitOrderUseCase submitOrder,
    required LocalOrdersUseCases localOrders,
    required BuildCheckoutPaymentRequestUseCase buildPaymentRequest,
    required CompleteCheckoutPaymentUseCase completePayment,
    required AppSettingsSnapshot? Function() readSettings,
    Logger? logger,
  }) : _submitOrder = submitOrder,
       _localOrders = localOrders,
       _buildPaymentRequest = buildPaymentRequest,
       _completePayment = completePayment,
       _readSettings = readSettings,
       _logger = logger ?? Logger('CheckoutCoordinator'),
       super(const CheckoutState());

  final SubmitOrderUseCase _submitOrder;
  final LocalOrdersUseCases _localOrders;
  final BuildCheckoutPaymentRequestUseCase _buildPaymentRequest;
  final CompleteCheckoutPaymentUseCase _completePayment;
  final AppSettingsSnapshot? Function() _readSettings;
  final Logger _logger;

  void begin(CheckoutDraft draft) {
    state = CheckoutState(stage: CheckoutStage.selectingPayment, draft: draft);
  }

  Future<OrderSubmissionResult> beginNewOrder(CheckoutDraft draft) async {
    state = CheckoutState(stage: CheckoutStage.submittingOrder, draft: draft);
    try {
      _logger.info(
        '[CHECKOUT_FLOW] submit offline order before payment selection',
      );
      final order = await _ensureOrderSubmitted(draft);
      _logger.info(
        '[CHECKOUT_FLOW] offline order submitted orderId=${order.orderId}',
      );
      return order;
    } catch (error, stack) {
      _logger.warning(
        'Submit checkout order before navigation failed',
        error,
        stack,
      );
      state = CheckoutState(error: error.toString());
      rethrow;
    }
  }

  Future<void> beginExistingOrder({
    required CheckoutDraft draft,
    required OrderSubmissionResult order,
  }) async {
    state = CheckoutState(
      stage: CheckoutStage.selectingPayment,
      draft: draft,
      order: order,
      submittedTotal: order.total.toDouble(),
    );

    try {
      final existing = await _localOrders.getById(order.orderId);
      if (existing == null) {
        await _localOrders.save(
          LocalOrderRecord(
            orderId: order.orderId,
            createdAt: DateTime.now(),
            isPaid: false,
            items: draft.items,
            machineCode: draft.machineCode,
            language: draft.language,
            takeout: draft.takeout,
            discount: draft.discount,
            clientTotal: order.total.toDouble(),
            orderResult: order,
          ),
        );
      }
    } catch (error, stack) {
      _logger.warning('Save existing settlement order failed', error, stack);
      state = state.copyWith(warning: error.toString());
    }
  }

  Future<CheckoutPaymentRequest> preparePayment({
    required String group,
    required String code,
    required String label,
  }) async {
    final draft = state.draft;
    if (draft == null) throw StateError('CHECKOUT_DRAFT_MISSING');

    final settings = _readSettings();
    final basic = settings?.basic ?? const BasicSettings();
    final paymentMode = basic.paymentModes.resolveForGroup(
      group,
      cashMachine: basic.cashMachine,
    );

    try {
      final order = await _ensureOrderSubmitted(draft);
      await _localOrders.updatePaymentMode(order.orderId, paymentMode);
      await _localOrders.updatePayMethod(order.orderId, code);

      final requiresOrderStateUpdate =
          paymentMode == PaymentFlowMode.bookkeeping ||
          (paymentMode == PaymentFlowMode.real &&
              group == PaymentChannels.cash &&
              basic.cashMachine.brand == CashMachineBrand.star);
      final request = _buildPaymentRequest.execute(
        order: order,
        shop: draft.shop,
        machineCode: draft.machineCode,
        group: group,
        code: code,
        paymentMode: paymentMode,
        label: label,
        items: draft.items,
        language: draft.language,
        takeout: draft.takeout,
        basic: basic,
        posInfo: settings?.posTerminal,
        discount: draft.discount,
        requiresOrderStateUpdate: requiresOrderStateUpdate,
      );
      state = state.copyWith(
        stage: CheckoutStage.paymentReady,
        paymentRequest: request,
        paymentResult: null,
        printRequest: null,
        error: null,
      );
      return request;
    } catch (error, stack) {
      _logger.warning('Prepare checkout payment failed', error, stack);
      state = state.copyWith(
        stage: CheckoutStage.selectingPayment,
        error: error.toString(),
      );
      rethrow;
    }
  }

  void paymentStarted(CheckoutPaymentRequest request) {
    if (state.order == null) {
      state = CheckoutState(
        stage: CheckoutStage.paying,
        order: request.order,
        paymentRequest: request,
      );
      return;
    }
    if (state.order?.orderId != request.order.orderId) return;
    state = state.copyWith(
      stage: CheckoutStage.paying,
      paymentRequest: request,
      paymentResult: null,
      printRequest: null,
      error: null,
    );
  }

  /// Returns whether the local order completion flag was updated successfully.
  Future<bool> paymentCompleted(PaymentResult result) async {
    final order = state.order;
    if (order == null) throw StateError('CHECKOUT_ORDER_MISSING');

    switch (result.status) {
      case PaymentStatusType.success:
        var localOrderUpdated = true;
        String? warning;
        try {
          await _completePayment.execute(order.orderId);
        } catch (error, stack) {
          localOrderUpdated = false;
          warning = error.toString();
          _logger.warning(
            'Payment succeeded but local checkout completion failed',
            error,
            stack,
          );
        }
        state = state.copyWith(
          stage: CheckoutStage.printReady,
          paymentResult: result,
          printRequest: _buildPrintRequest(order, result),
          warning: warning,
          error: null,
        );
        return localOrderUpdated;
      case PaymentStatusType.indeterminate:
        state = state.copyWith(
          stage: CheckoutStage.paymentIndeterminate,
          paymentResult: result,
          printRequest: null,
          error: null,
        );
        return true;
      case PaymentStatusType.failure:
      case PaymentStatusType.cancelled:
        state = state.copyWith(
          stage: CheckoutStage.paymentFailed,
          paymentResult: result,
          printRequest: null,
          error: null,
        );
        return true;
      case PaymentStatusType.initialized:
      case PaymentStatusType.pending:
      case PaymentStatusType.waitingForUser:
      case PaymentStatusType.processing:
      case PaymentStatusType.reconciling:
        throw StateError('CHECKOUT_PAYMENT_RESULT_NOT_TERMINAL');
    }
  }

  void printingStarted() {
    if (state.stage != CheckoutStage.printReady) return;
    state = state.copyWith(stage: CheckoutStage.printing);
  }

  void printingCompleted() {
    if (state.stage != CheckoutStage.printing &&
        state.stage != CheckoutStage.printReady) {
      return;
    }
    state = state.copyWith(stage: CheckoutStage.completed, printRequest: null);
  }

  void reset() {
    state = const CheckoutState();
  }

  Future<OrderSubmissionResult> _ensureOrderSubmitted(
    CheckoutDraft draft,
  ) async {
    final existing = state.order;
    if (existing != null) return existing;

    state = state.copyWith(stage: CheckoutStage.submittingOrder, error: null);
    final output = await _submitOrder.execute(
      SubmitOrderInput(
        items: draft.items,
        machineCode: draft.machineCode,
        language: draft.language,
        takeout: draft.takeout,
        discount: draft.discount,
        shopCode: draft.shop.shopCode,
      ),
    );

    String? warning;
    try {
      await _localOrders.save(
        LocalOrderRecord(
          orderId: output.order.orderId,
          createdAt: DateTime.now(),
          isPaid: false,
          items: draft.items,
          machineCode: draft.machineCode,
          language: draft.language,
          takeout: draft.takeout,
          discount: draft.discount,
          clientTotal: output.total,
          orderResult: output.order,
        ),
      );
    } catch (error, stack) {
      warning = error.toString();
      _logger.warning('Save submitted checkout order failed', error, stack);
    }

    state = state.copyWith(
      stage: CheckoutStage.selectingPayment,
      order: output.order,
      submittedTotal: output.total,
      warning: warning,
    );
    return output.order;
  }

  PrintJobRequest _buildPrintRequest(
    OrderSubmissionResult order,
    PaymentResult result,
  ) {
    final settings = _readSettings();
    final printers = settings?.printers ?? const <PrinterSettings>[];
    final receiptOnly = state.draft?.isSettlement ?? false;
    final hasLabelPrinter = printers.any(
      (printer) => printer.type == 10 && !printer.receipt && printer.isOn,
    );
    return PrintJobRequest(
      machineCode:
          state.draft?.machineCode ??
          state.paymentRequest?.metadata?['machineCode']?.toString() ??
          '',
      printers: printers,
      orderId: order.orderId,
      payAmount: order.total.toString(),
      printType: !receiptOnly && hasLabelPrinter ? 'Label' : '',
      document: result.payload?['printDocument'] as PrintInfoDocument?,
      receiptOnly: receiptOnly,
      logoImageBase64: state.draft?.shop.logoImageBase64,
      paymentMethodOverride: _bookkeepingPaymentMethodLabel(),
    );
  }

  String? _bookkeepingPaymentMethodLabel() {
    final payment = state.paymentRequest;
    if (payment == null || payment.paymentMode != PaymentFlowMode.bookkeeping) {
      return null;
    }
    return switch (payment.channelGroup) {
      PaymentChannels.cash => '現金支払（オフライン）',
      PaymentChannels.card => 'クレジットカード（オフライン）',
      PaymentChannels.qr => 'QR Code（オフライン）',
      _ => null,
    };
  }
}
