import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/services/pos_payment_service.dart';

class PosPaymentStatusAdapterConfig {
  const PosPaymentStatusAdapterConfig({
    required this.successMessageKey,
    required this.failureMessageKey,
    required this.cancelledMessageKey,
    this.pendingMessageKey = PaymentMessageKeys.posWaitingResponse,
    this.processingMessageKey = PaymentMessageKeys.posProcessing,
    this.defaultFailureErrorType = PaymentErrorType.device,
    this.defaultCancelledErrorType = PaymentErrorType.userCancelled,
  });

  final String successMessageKey;
  final String failureMessageKey;
  final String cancelledMessageKey;
  final String pendingMessageKey;
  final String processingMessageKey;
  final PaymentErrorType defaultFailureErrorType;
  final PaymentErrorType defaultCancelledErrorType;
}

class PosPaymentStatusAdapter {
  const PosPaymentStatusAdapter(this.config);

  final PosPaymentStatusAdapterConfig config;

  PaymentStatus map(PosPaymentStatus status) {
    final details = <String, dynamic>{
      if (status.details != null) ...status.details!,
      if (status.approvalCode != null) 'approvalCode': status.approvalCode,
      if (status.errorCode != null) 'errorCode': status.errorCode,
    };
    final messageArgs = <String, dynamic>{
      if (status.messageArgs != null) ...status.messageArgs!,
      if (status.errorCode != null) 'errorCode': status.errorCode,
    };
    return PaymentStatus(
      type: _mapType(status.type),
      message: status.message,
      messageKey: status.messageKey ?? _fallbackMessageKey(status),
      messageArgs: messageArgs.isEmpty ? null : messageArgs,
      details: details.isEmpty ? null : details,
      errorType: status.errorType ?? _fallbackErrorType(status.type),
      retryable: status.retryable ?? _fallbackRetryable(status.type),
      phase: status.phase ?? _fallbackPhase(status.type),
    );
  }

  PaymentResult? toTerminalResult(PosPaymentStatus status) {
    final mapped = map(status);
    if (!mapped.isTerminal) {
      return null;
    }
    switch (mapped.type) {
      case PaymentStatusType.success:
        return PaymentResult.success(
          message: mapped.message,
          messageKey: mapped.messageKey,
          messageArgs: mapped.messageArgs,
          payload: mapped.details,
        );
      case PaymentStatusType.cancelled:
        return PaymentResult.cancelled(
          message: mapped.message,
          messageKey: mapped.messageKey,
          messageArgs: mapped.messageArgs,
          errorCode: mapped.details?['errorCode'] as String?,
          payload: mapped.details,
          errorType: mapped.errorType ?? config.defaultCancelledErrorType,
          retryable: mapped.retryable ?? true,
        );
      case PaymentStatusType.failure:
        return PaymentResult.failure(
          message: mapped.message,
          messageKey: mapped.messageKey,
          messageArgs: mapped.messageArgs,
          errorCode: mapped.details?['errorCode'] as String?,
          payload: mapped.details,
          errorType: mapped.errorType ?? config.defaultFailureErrorType,
          retryable: mapped.retryable ?? true,
        );
      case PaymentStatusType.initialized:
      case PaymentStatusType.pending:
      case PaymentStatusType.waitingForUser:
      case PaymentStatusType.processing:
      case PaymentStatusType.indeterminate:
      case PaymentStatusType.reconciling:
        return null;
    }
  }

  PaymentStatusType _mapType(PosPaymentStatusType type) {
    switch (type) {
      case PosPaymentStatusType.pending:
        return PaymentStatusType.pending;
      case PosPaymentStatusType.processing:
        return PaymentStatusType.processing;
      case PosPaymentStatusType.success:
        return PaymentStatusType.success;
      case PosPaymentStatusType.failure:
        return PaymentStatusType.failure;
      case PosPaymentStatusType.cancelled:
        return PaymentStatusType.cancelled;
    }
  }

  String _fallbackMessageKey(PosPaymentStatus status) {
    switch (status.type) {
      case PosPaymentStatusType.pending:
        return config.pendingMessageKey;
      case PosPaymentStatusType.processing:
        return config.processingMessageKey;
      case PosPaymentStatusType.success:
        return config.successMessageKey;
      case PosPaymentStatusType.failure:
        return config.failureMessageKey;
      case PosPaymentStatusType.cancelled:
        return config.cancelledMessageKey;
    }
  }

  PaymentErrorType? _fallbackErrorType(PosPaymentStatusType type) {
    switch (type) {
      case PosPaymentStatusType.failure:
        return config.defaultFailureErrorType;
      case PosPaymentStatusType.cancelled:
        return config.defaultCancelledErrorType;
      case PosPaymentStatusType.pending:
      case PosPaymentStatusType.processing:
      case PosPaymentStatusType.success:
        return null;
    }
  }

  bool? _fallbackRetryable(PosPaymentStatusType type) {
    switch (type) {
      case PosPaymentStatusType.failure:
      case PosPaymentStatusType.cancelled:
        return true;
      case PosPaymentStatusType.pending:
      case PosPaymentStatusType.processing:
      case PosPaymentStatusType.success:
        return null;
    }
  }

  PaymentPhase? _fallbackPhase(PosPaymentStatusType type) {
    switch (type) {
      case PosPaymentStatusType.pending:
        return PaymentPhase.sending;
      case PosPaymentStatusType.processing:
        return PaymentPhase.waitingUser;
      case PosPaymentStatusType.success:
      case PosPaymentStatusType.failure:
      case PosPaymentStatusType.cancelled:
        return null;
    }
  }
}
