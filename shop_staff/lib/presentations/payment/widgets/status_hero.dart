
import 'package:flutter/material.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

class StatusHero extends StatelessWidget {
  const StatusHero({
    super.key,
    required this.state,
    required this.args,
    this.onRetry,
    this.onOpenSettings,
    this.onNetworkHelp,
  });

  final PaymentFlowState state;
  final PaymentFlowPageArgs args;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onNetworkHelp;

  @override
  Widget build(BuildContext context) {
    final current = state.currentStatus;
    final theme = Theme.of(context);
    final effectiveResult = state.result?.status;
    final hasError = state.error != null;
    final t = AppLocalizations.of(context);
    final localizedMessage = resolveMessage(
      t,
      key: current?.messageKey,
      args: current?.messageArgs,
      fallback: current?.message ?? _defaultMessage(t, args.channelGroup, current?.type),
    );
    final effectiveErrorType = _effectiveErrorType(state);
    final retryable = _effectiveRetryable(state);
    final message = hasError ? state.error! : localizedMessage;
    final icon = hasError ? Icons.error_rounded : StatusHero.iconForStatus(current?.type, effectiveResult);
    final color = hasError ? Colors.redAccent : _colorForStatus(theme, current?.type, effectiveResult);
    final showRetry = _shouldShowRetry(state, retryable) && onRetry != null;
    final showConfigAction = effectiveErrorType == PaymentErrorType.config && onOpenSettings != null;
    final showNetworkAction = effectiveErrorType == PaymentErrorType.network && onNetworkHelp != null;
    final errorHint = _errorHintForType(t, effectiveErrorType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 32),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!hasError)
                  Text(_instructionFor(t, args.channelGroup),
                      style: const TextStyle(color: Colors.black54)),
                if (hasError && errorHint != null)
                  Text(errorHint, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if (showRetry || showConfigAction || showNetworkAction) ...[
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showRetry)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      _retryLabelForType(t, effectiveErrorType),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                if (showConfigAction)
                  TextButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_rounded, size: 20),
                    label: const Text('去设置', style: TextStyle(fontSize: 16)),
                  ),
                if (showNetworkAction)
                  TextButton.icon(
                    onPressed: onNetworkHelp,
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 20),
                    label: const Text('检查网络', style: TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static IconData iconForStatus(PaymentStatusType? type, PaymentStatusType? resultType) {
    final effective = resultType ?? type;
    switch (effective) {
      case PaymentStatusType.success:
        return Icons.check_circle_rounded;
      case PaymentStatusType.failure:
        return Icons.error_rounded;
      case PaymentStatusType.cancelled:
        return Icons.cancel_rounded;
      case PaymentStatusType.waitingForUser:
        return Icons.hourglass_bottom_rounded;
      case PaymentStatusType.processing:
        return Icons.sync_rounded;
      case PaymentStatusType.pending:
      case PaymentStatusType.initialized:
      default:
        return Icons.payment_rounded;
    }
  }

  static Color _colorForStatus(ThemeData theme, PaymentStatusType? type, PaymentStatusType? resultType) {
    final effective = resultType ?? type;
    switch (effective) {
      case PaymentStatusType.success:
        return Colors.green;
      case PaymentStatusType.failure:
        return Colors.redAccent;
      case PaymentStatusType.cancelled:
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  static String _defaultMessage(AppLocalizations t, String group, PaymentStatusType? type) {
    switch (group) {
      case PaymentChannels.card:
        if (type == PaymentStatusType.pending) return t.paymentFallbackCardConnecting;
        if (type == PaymentStatusType.processing) return t.paymentFallbackCardFollowPos;
        return t.paymentFallbackCardProcessing;
      case PaymentChannels.cash:
        if (type == PaymentStatusType.pending) return t.paymentFallbackCashPrepare;
        if (type == PaymentStatusType.waitingForUser) return t.paymentFallbackCashWaiting;
        return t.paymentFallbackCashProcessing;
      case PaymentChannels.qr:
        if (type == PaymentStatusType.waitingForUser) return t.paymentFallbackQrAlign;
        return t.paymentFallbackQrProcessing;
      default:
        return t.paymentFallbackProcessing;
    }
  }

  static String _instructionFor(AppLocalizations t, String group) {
    switch (group) {
      case PaymentChannels.card:
        return t.paymentInstructionCard;
      case PaymentChannels.cash:
        return t.paymentInstructionCash;
      case PaymentChannels.qr:
        return t.paymentInstructionQr;
      default:
        return t.paymentInstructionDefault;
    }
  }

  static bool _shouldShowRetry(PaymentFlowState state, bool retryable) {
    if (state.isCancelling) return false;
    if (state.error != null) return retryable;
    final result = state.result?.status;
    if (result == PaymentStatusType.failure || result == PaymentStatusType.cancelled) {
      return retryable;
    }
    final currentType = state.currentStatus?.type;
    return (currentType == PaymentStatusType.failure || currentType == PaymentStatusType.cancelled) && retryable;
  }

  static PaymentErrorType? _effectiveErrorType(PaymentFlowState state) {
    return state.result?.errorType ?? state.currentStatus?.errorType;
  }

  static bool _effectiveRetryable(PaymentFlowState state) {
    return state.result?.retryable ?? state.currentStatus?.retryable ?? true;
  }

  static String? _errorHintForType(AppLocalizations t, PaymentErrorType? type) {
    switch (type) {
      case PaymentErrorType.device:
        return t.paymentErrorHintDevice;
      case PaymentErrorType.config:
        return t.paymentErrorHintConfig;
      case PaymentErrorType.network:
        return t.paymentErrorHintNetwork;
      case PaymentErrorType.backend:
        return t.paymentErrorHintBackend;
      case PaymentErrorType.userCancelled:
        return t.paymentErrorHintCancelled;
      case PaymentErrorType.unknown:
      default:
        return null;
    }
  }

  static String _retryLabelForType(AppLocalizations t, PaymentErrorType? type) {
    switch (type) {
      case PaymentErrorType.device:
        return t.paymentRetryDevice;
      case PaymentErrorType.network:
        return t.paymentRetryNetwork;
      case PaymentErrorType.config:
        return t.paymentRetryDefault;
      case PaymentErrorType.backend:
        return t.paymentRetryDefault;
      case PaymentErrorType.userCancelled:
        return t.paymentRetryRestart;
      case PaymentErrorType.unknown:
      default:
        return t.paymentRetryDefault;
    }
  }

  static String resolveMessage(
    AppLocalizations t, {
    required String? key,
    Map<String, dynamic>? args,
    required String fallback,
  }) {
    String resolveDetail() {
      final raw = args?['detail']?.toString() ?? '';
      return _resolveExternalDetail(t, raw);
    }
    String? resolveErrorCodeSuffix() {
      final rawCode = args?['errorCode']?.toString();
      if (rawCode == null || rawCode.isEmpty) return null;
      final desc = _resolveExternalErrorCodeDesc(t, rawCode);
      if (desc != null && desc.isNotEmpty) return desc;
      return t.paymentErrorCodeLabel(rawCode);
    }
    if (key == null) return fallback;
    late final String base;
    switch (key) {
      case PaymentMessageKeys.flowStarted:
        base = t.paymentFlowStarted(args?['channel']?.toString() ?? '');
        break;
      case PaymentMessageKeys.statusInitialized:
        base = t.paymentStatusInitialized;
        break;
      case PaymentMessageKeys.statusPending:
        base = t.paymentStatusPending;
        break;
      case PaymentMessageKeys.statusWaitingUser:
        base = t.paymentStatusWaitingUser;
        break;
      case PaymentMessageKeys.statusProcessing:
        base = t.paymentStatusProcessing;
        break;
      case PaymentMessageKeys.statusSuccess:
        base = t.paymentStatusSuccess;
        break;
      case PaymentMessageKeys.statusFailure:
        base = t.paymentStatusFailure;
        break;
      case PaymentMessageKeys.statusCancelled:
        base = t.paymentStatusCancelled;
        break;
      case PaymentMessageKeys.statusNoUpdates:
        base = t.paymentStatusNoUpdates;
        break;
      case PaymentMessageKeys.cardInitTerminal:
        base = t.paymentCardInitTerminal;
        break;
      case PaymentMessageKeys.cardSuccess:
        base = t.paymentCardSuccess;
        break;
      case PaymentMessageKeys.cardFailure:
        base = t.paymentCardFailure;
        break;
      case PaymentMessageKeys.cardCancelled:
        base = t.paymentCardCancelled;
        break;
      case PaymentMessageKeys.cardCancelFailed:
        base = t.paymentCardCancelFailed(resolveDetail());
        break;
      case PaymentMessageKeys.cardInitFailed:
        base = t.paymentCardInitFailed(resolveDetail());
        break;
      case PaymentMessageKeys.posStreamClosed:
        base = t.paymentPosStreamClosed;
        break;
      case PaymentMessageKeys.qrWaitScan:
        base = t.paymentQrWaitScan;
        break;
      case PaymentMessageKeys.qrRequestBackend:
        base = t.paymentQrRequestBackend;
        break;
      case PaymentMessageKeys.qrPosPrompt:
        base = t.paymentQrPosPrompt;
        break;
      case PaymentMessageKeys.qrSuccess:
        base = t.paymentQrSuccess;
        break;
      case PaymentMessageKeys.qrFailure:
        base = t.paymentQrFailure(resolveDetail());
        break;
      case PaymentMessageKeys.qrCancelled:
        base = t.paymentQrCancelled;
        break;
      case PaymentMessageKeys.qrConfigMissing:
        base = t.paymentQrConfigMissing;
        break;
      case PaymentMessageKeys.posWaitingResponse:
        base = t.paymentPosWaitingResponse;
        break;
      case PaymentMessageKeys.posProcessing:
        base = t.paymentPosProcessing;
        break;
      case PaymentMessageKeys.posFetchingPayData:
        base = t.paymentPosFetchingPayData;
        break;
      case PaymentMessageKeys.posWaitingUser:
        base = t.paymentPosWaitingUser;
        break;
      case PaymentMessageKeys.posRequestPayData:
        base = t.paymentPosRequestPayData;
        break;
      case PaymentMessageKeys.posLoading:
        base = t.paymentPosLoading(args?['mode']?.toString() ?? '');
        break;
      case PaymentMessageKeys.posTerminalDone:
        base = t.paymentPosTerminalDone(args?['action']?.toString() ?? '');
        break;
      case PaymentMessageKeys.posTerminalCancelled:
        base = t.paymentPosTerminalCancelled(
          args?['code']?.toString() ?? '',
          args?['mpfs']?.toString() ?? '',
        );
        break;
      case PaymentMessageKeys.posTimeout:
        base = t.paymentPosTimeout;
        break;
      case PaymentMessageKeys.posReportResult:
        base = t.paymentPosReportResult;
        break;
      case PaymentMessageKeys.posPaymentSuccess:
        base = t.paymentPosPaymentSuccess;
        break;
      case PaymentMessageKeys.posResultHandleFailed:
        base = t.paymentPosResultHandleFailed(resolveDetail());
        break;
      case PaymentMessageKeys.posCancelProcessing:
        base = t.paymentPosCancelProcessing;
        break;
      case PaymentMessageKeys.posCancelFailed:
        base = t.paymentPosCancelFailed(resolveDetail());
        break;
      case PaymentMessageKeys.posOperatorCancelled:
        base = t.paymentPosOperatorCancelled;
        break;
      case PaymentMessageKeys.cashPrepare:
        base = t.paymentCashPrepare;
        break;
      case PaymentMessageKeys.cashAwaitConfirm:
        base = t.paymentCashAwaitConfirm;
        break;
      case PaymentMessageKeys.cashConfirming:
        base = t.paymentCashConfirming;
        break;
      case PaymentMessageKeys.cashSuccess:
        base = t.paymentCashSuccess;
        break;
      case PaymentMessageKeys.cashFailure:
        base = t.paymentCashFailure(resolveDetail());
        break;
      case PaymentMessageKeys.cashConfirmFailed:
        base = t.paymentCashConfirmFailed(resolveDetail());
        break;
      case PaymentMessageKeys.cashCancelled:
        base = t.paymentCashCancelled;
        break;
      case PaymentMessageKeys.cashStageIdle:
        base = t.paymentCashStageIdle;
        break;
      case PaymentMessageKeys.cashStageChecking:
        base = t.paymentCashStageChecking;
        break;
      case PaymentMessageKeys.cashStageOpening:
        base = t.paymentCashStageOpening;
        break;
      case PaymentMessageKeys.cashStageAccepting:
        base = t.paymentCashStageAccepting;
        break;
      case PaymentMessageKeys.cashStageCounting:
        base = t.paymentCashStageCounting;
        break;
      case PaymentMessageKeys.cashStageClosing:
        base = t.paymentCashStageClosing;
        break;
      case PaymentMessageKeys.cashStageCompleted:
        base = t.paymentCashStageCompleted;
        break;
      case PaymentMessageKeys.cashStageNearFull:
        base = t.paymentCashStageNearFull;
        break;
      case PaymentMessageKeys.cashStageFull:
        base = t.paymentCashStageFull;
        break;
      case PaymentMessageKeys.cashStageError:
        base = t.paymentCashStageError;
        break;
      case PaymentMessageKeys.cashStageChange:
        base = t.paymentCashStageChange;
        break;
      case PaymentMessageKeys.cashStageChangeFailed:
        base = t.paymentCashStageChangeFailed;
        break;
      case PaymentMessageKeys.cashAmountCurrent:
        base = t.paymentCashAmountCurrent(args?['amount']?.toString() ?? '');
        break;
      case PaymentMessageKeys.cashAmountFinal:
        base = t.paymentCashAmountFinal(args?['amount']?.toString() ?? '');
        break;
      case PaymentMessageKeys.errorUnknown:
        base = t.paymentErrorUnknown(resolveDetail());
        break;
      case PaymentMessageKeys.sessionMissing:
        base = t.paymentSessionMissing;
        break;
      case PaymentMessageKeys.flowEnded:
        base = t.paymentFlowEnded;
        break;
      default:
        base = fallback;
        break;
    }

    final suffix = resolveErrorCodeSuffix();
    if (suffix == null || suffix.isEmpty) return base;
    return '$base ($suffix)';
  }

  static String _resolveExternalDetail(AppLocalizations t, String raw) {
    if (raw.isEmpty) return raw;
    switch (raw) {
      case 'POS_IP_MISSING':
        return t.paymentErrorPosIpMissing;
      case 'POS_PORT_INVALID':
        return t.paymentErrorPosPortInvalid;
      case 'POS_CONFIG_MISSING':
        return t.paymentErrorPosConfigMissing;
      case 'POS_CARD_GATEWAY_REQUIRED':
        return t.paymentErrorPosCardGatewayRequired;
      case 'POS_SESSION_MISSING':
        return t.paymentErrorPosSessionMissing;
      case 'POS_CANCEL_INSTRUCTION_EMPTY':
        return t.paymentErrorPosCancelInstructionEmpty;
      case 'POS_REQUEST_DATA_MISSING':
        return t.paymentErrorPosRequestDataMissing;
      case 'POS_CANCEL_NOT_SUPPORTED':
        return t.paymentErrorPosCancelNotSupported;
      case 'POS_CANCEL_FAILED':
        return t.paymentErrorPosCancelFailed;
      case 'PAYMENT_FINALIZE_NOT_REQUIRED':
        return t.paymentErrorPaymentFinalizeNotRequired;
      case 'CASH_RECEIPT_MISSING':
        return t.paymentErrorCashReceiptMissing;
      case 'CASH_BUSY':
        return t.paymentErrorCashBusy;
      case 'CASH_NO_PENDING':
        return t.paymentErrorCashNoPending;
      case 'QR_SCAN_CANCELLED':
        return t.paymentErrorQrScanCancelled;
      case 'QR_SCAN_RESET':
        return t.paymentErrorQrScanReset;
      case 'QR_SCAN_RELEASED':
        return t.paymentErrorQrScanReleased;
      default:
        return raw;
    }
  }

  static String? _resolveExternalErrorCodeDesc(AppLocalizations t, String rawCode) {
    switch (rawCode) {
      case 'POS_CANCEL_FAILED':
        return t.paymentErrorPosCancelFailed;
      default:
        return null;
    }
  }
}
