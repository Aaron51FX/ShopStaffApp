import 'dart:async';

import '../entities/order_submission_result.dart';

/// Canonical status types a payment flow can emit.
enum PaymentStatusType {
  initialized,
  pending,
  waitingForUser,
  processing,
  success,
  failure,
  cancelled,
}

/// Localization keys for payment flow messages.
abstract class PaymentMessageKeys {
  static const String flowStarted = 'payment_flow_started';
  static const String statusInitialized = 'payment_status_initialized';
  static const String statusPending = 'payment_status_pending';
  static const String statusWaitingUser = 'payment_status_waiting_user';
  static const String statusProcessing = 'payment_status_processing';
  static const String statusSuccess = 'payment_status_success';
  static const String statusFailure = 'payment_status_failure';
  static const String statusCancelled = 'payment_status_cancelled';
  static const String statusNoUpdates = 'payment_status_no_updates';

  static const String cardInitTerminal = 'payment_card_init_terminal';
  static const String cardSuccess = 'payment_card_success';
  static const String cardFailure = 'payment_card_failure';
  static const String cardCancelled = 'payment_card_cancelled';
  static const String cardCancelFailed = 'payment_card_cancel_failed';
  static const String cardInitFailed = 'payment_card_init_failed';
  static const String posStreamClosed = 'payment_pos_stream_closed';

  static const String qrWaitScan = 'payment_qr_wait_scan';
  static const String qrRequestBackend = 'payment_qr_request_backend';
  static const String qrPosPrompt = 'payment_qr_pos_prompt';
  static const String qrSuccess = 'payment_qr_success';
  static const String qrFailure = 'payment_qr_failure';
  static const String qrCancelled = 'payment_qr_cancelled';
  static const String qrConfigMissing = 'payment_qr_config_missing';

  static const String posWaitingResponse = 'payment_pos_waiting_response';
  static const String posProcessing = 'payment_pos_processing';

  static const String cashPrepare = 'payment_cash_prepare';
  static const String cashAwaitConfirm = 'payment_cash_await_confirm';
  static const String cashConfirming = 'payment_cash_confirming';
  static const String cashSuccess = 'payment_cash_success';
  static const String cashFailure = 'payment_cash_failure';
  static const String cashConfirmFailed = 'payment_cash_confirm_failed';
  static const String cashCancelled = 'payment_cash_cancelled';

  static const String cashStageIdle = 'payment_cash_stage_idle';
  static const String cashStageChecking = 'payment_cash_stage_checking';
  static const String cashStageOpening = 'payment_cash_stage_opening';
  static const String cashStageAccepting = 'payment_cash_stage_accepting';
  static const String cashStageCounting = 'payment_cash_stage_counting';
  static const String cashStageClosing = 'payment_cash_stage_closing';
  static const String cashStageCompleted = 'payment_cash_stage_completed';
  static const String cashStageNearFull = 'payment_cash_stage_nearfull';
  static const String cashStageFull = 'payment_cash_stage_full';
  static const String cashStageError = 'payment_cash_stage_error';
  static const String cashStageChange = 'payment_cash_stage_change';
  static const String cashStageChangeFailed = 'payment_cash_stage_change_failed';
  static const String cashAmountCurrent = 'payment_cash_amount_current';
  static const String cashAmountFinal = 'payment_cash_amount_final';

  static const String errorUnknown = 'payment_error_unknown';
  static const String sessionMissing = 'payment_session_missing';
  static const String flowEnded = 'payment_flow_ended';
  static const String posFetchingPayData = 'payment_pos_fetching_data';
  static const String posWaitingUser = 'payment_pos_waiting_user';
  static const String posRequestPayData = 'payment_pos_request_pay_data';
  static const String posLoading = 'payment_pos_loading';
  static const String posTerminalDone = 'payment_pos_terminal_done';
  static const String posTerminalCancelled = 'payment_pos_terminal_cancelled';
  static const String posTimeout = 'payment_pos_timeout';
  static const String posReportResult = 'payment_pos_report_result';
  static const String posPaymentSuccess = 'payment_pos_payment_success';
  static const String posResultHandleFailed = 'payment_pos_result_handle_failed';
  static const String posCancelProcessing = 'payment_pos_cancel_processing';
  static const String posCancelFailed = 'payment_pos_cancel_failed';
  static const String posOperatorCancelled = 'payment_pos_operator_cancelled';
  static const String paymentForceExitRecorded = 'payment_force_exit_recorded';

  // External error codes to be mapped into localized messages.
  static const String errorPosIpMissing = 'payment_error_pos_ip_missing';
  static const String errorPosPortInvalid = 'payment_error_pos_port_invalid';
  static const String errorPosConfigMissing = 'payment_error_pos_config_missing';
  static const String errorPosCardGatewayRequired = 'payment_error_pos_card_gateway_required';
  static const String errorPosSessionMissing = 'payment_error_pos_session_missing';
  static const String errorPosCancelInstructionEmpty = 'payment_error_pos_cancel_instruction_empty';
  static const String errorPosRequestDataMissing = 'payment_error_pos_request_data_missing';
  static const String errorPosCancelNotSupported = 'payment_error_pos_cancel_not_supported';
  static const String errorPosCancelFailed = 'payment_error_pos_cancel_failed';
  static const String errorPaymentFinalizeNotRequired = 'payment_error_payment_finalize_not_required';
  static const String errorCashReceiptMissing = 'payment_error_cash_receipt_missing';
  static const String errorCashBusy = 'payment_error_cash_busy';
  static const String errorCashNoPending = 'payment_error_cash_no_pending';
  static const String errorQrScanCancelled = 'payment_error_qr_scan_cancelled';
  static const String errorQrScanReset = 'payment_error_qr_scan_reset';
  static const String errorQrScanReleased = 'payment_error_qr_scan_released';
}

/// Canonical payment phases to drive precise UI controls (e.g. cancel availability).
enum PaymentPhase {
  initializing,
  connecting,
  requesting,
  sending,
  waitingUser,
  confirming,
}

/// Canonical error types to drive UI handling and recovery options.
enum PaymentErrorType {
  userCancelled,
  device,
  network,
  config,
  backend,
  unknown,
}

/// Immutable descriptor of a payment status update.
class PaymentStatus {
  const PaymentStatus({
    required this.type,
    this.message,
    this.messageKey,
    this.messageArgs,
    this.details,
    this.errorType,
    this.retryable,
    this.phase,
  });

  final PaymentStatusType type;
  final String? message;
  final String? messageKey;
  final Map<String, dynamic>? messageArgs;
  final Map<String, dynamic>? details;
  final PaymentErrorType? errorType;
  final bool? retryable;
  final PaymentPhase? phase;

  bool get isTerminal =>
      type == PaymentStatusType.success ||
      type == PaymentStatusType.failure ||
      type == PaymentStatusType.cancelled;
}

/// Result information returned once a payment flow completes.
class PaymentResult {
  const PaymentResult({
    required this.status,
    required this.success,
    this.message,
    this.messageKey,
    this.messageArgs,
    this.errorCode,
    this.payload,
    this.errorType,
    this.retryable,
  });

  final PaymentStatusType status;
  final bool success;
  final String? message;
  final String? messageKey;
  final Map<String, dynamic>? messageArgs;
  final String? errorCode;
  final Map<String, dynamic>? payload;
  final PaymentErrorType? errorType;
  final bool? retryable;

  factory PaymentResult.success({
    String? message,
    String? messageKey,
    Map<String, dynamic>? messageArgs,
    Map<String, dynamic>? payload,
  }) {
    return PaymentResult(
      status: PaymentStatusType.success,
      success: true,
      message: message,
      messageKey: messageKey,
      messageArgs: messageArgs,
      payload: payload,
    );
  }

  factory PaymentResult.failure({
    String? message,
    String? messageKey,
    Map<String, dynamic>? messageArgs,
    String? errorCode,
    Map<String, dynamic>? payload,
    PaymentErrorType errorType = PaymentErrorType.unknown,
    bool retryable = true,
  }) {
    return PaymentResult(
      status: PaymentStatusType.failure,
      success: false,
      message: message,
      messageKey: messageKey,
      messageArgs: messageArgs,
      errorCode: errorCode,
      payload: payload,
      errorType: errorType,
      retryable: retryable,
    );
  }

  factory PaymentResult.cancelled({
    String? message,
    String? messageKey,
    Map<String, dynamic>? messageArgs,
    String? errorCode,
    Map<String, dynamic>? payload,
    PaymentErrorType errorType = PaymentErrorType.userCancelled,
    bool retryable = true,
  }) {
    return PaymentResult(
      status: PaymentStatusType.cancelled,
      success: false,
      message: message,
      messageKey: messageKey,
      messageArgs: messageArgs,
      errorCode: errorCode,
      payload: payload,
      errorType: errorType,
      retryable: retryable,
    );
  }
}

/// Logical channel metadata (e.g. card/qr/cash + specific provider code).
class PaymentChannel {
  const PaymentChannel({
    required this.group,
    required this.code,
    this.displayName,
  });

  final String group;
  final String code;
  final String? displayName;

  String get key => '$group::$code';
}

/// Commonly used channel keys.
abstract class PaymentChannels {
  static const String cash = 'cash';
  static const String card = 'card';
  static const String qr = 'qr';
}

/// Rich context passed to a payment flow.
class PaymentContext {
  const PaymentContext({
    required this.order,
    required this.channel,
    this.channelConfig,
    this.metadata,
  });

  final OrderSubmissionResult order;
  final PaymentChannel channel;
  final Map<String, dynamic>? channelConfig;
  final Map<String, dynamic>? metadata;
}

/// Represents an active payment flow run.
class PaymentFlowRun {
  PaymentFlowRun({
    required this.statuses,
    required this.result,
    required this.cancel,
    this.finalize,
  });

  final Stream<PaymentStatus> statuses;
  final Future<PaymentResult> result;
  final Future<void> Function() cancel;
  final Future<void> Function()? finalize;
}

/// Base contract that every payment flow must implement.
abstract class PaymentFlow {
  PaymentFlowRun start(PaymentContext context);
}
