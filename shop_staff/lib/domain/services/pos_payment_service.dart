import '../entities/order_submission_result.dart';

/// Represents a request to start a POS payment flow for a specific order and channel.
class PosPaymentRequest {
  PosPaymentRequest({
    required this.order,
    required this.channelGroup,
    required this.channelCode,
    this.customPayload,
  });

  final OrderSubmissionResult order;
  final String channelGroup;
  final String channelCode;
  final Map<String, dynamic>? customPayload;
}

/// The possible states a POS payment session can report while processing.
enum PosPaymentStatusType { pending, processing, success, failure, cancelled }

/// Detailed status information returned by an active POS payment session.
class PosPaymentStatus {
  const PosPaymentStatus({
    required this.type,
    this.message,
    this.approvalCode,
    this.errorCode,
  });

  final PosPaymentStatusType type;
  final String? message;
  final String? approvalCode;
  final String? errorCode;
}

/// A handle returned when a POS payment session is initiated.
class PosPaymentSession {
  const PosPaymentSession({required this.sessionId, required this.initialStatus});

  final String sessionId;
  final PosPaymentStatus initialStatus;
}

/// Contract for POS payment services that communicate with external payment terminals.
abstract class PosPaymentService {
  /// Start a payment flow for the given [request]. Returns the session metadata.
  Future<PosPaymentSession> startPayment(PosPaymentRequest request);

  /// Observe live status updates for an active payment session.
  Stream<PosPaymentStatus> watchStatus(String sessionId);

  /// Cancel the ongoing payment session if supported by the terminal.
  Future<void> cancel(String sessionId);
}
