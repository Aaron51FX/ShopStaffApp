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
    this.details,
    this.errorType,
    this.retryable,
    this.phase,
  });

  final PaymentStatusType type;
  final String? message;
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
    this.errorCode,
    this.payload,
    this.errorType,
    this.retryable,
  });

  final PaymentStatusType status;
  final bool success;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? payload;
  final PaymentErrorType? errorType;
  final bool? retryable;

  factory PaymentResult.success({String? message, Map<String, dynamic>? payload}) {
    return PaymentResult(
      status: PaymentStatusType.success,
      success: true,
      message: message,
      payload: payload,
    );
  }

  factory PaymentResult.failure({
    String? message,
    String? errorCode,
    Map<String, dynamic>? payload,
    PaymentErrorType errorType = PaymentErrorType.unknown,
    bool retryable = true,
  }) {
    return PaymentResult(
      status: PaymentStatusType.failure,
      success: false,
      message: message,
      errorCode: errorCode,
      payload: payload,
      errorType: errorType,
      retryable: retryable,
    );
  }

  factory PaymentResult.cancelled({
    String? message,
    String? errorCode,
    Map<String, dynamic>? payload,
    PaymentErrorType errorType = PaymentErrorType.userCancelled,
    bool retryable = true,
  }) {
    return PaymentResult(
      status: PaymentStatusType.cancelled,
      success: false,
      message: message,
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
