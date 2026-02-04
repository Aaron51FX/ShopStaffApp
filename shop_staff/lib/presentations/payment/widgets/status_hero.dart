
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
    if (key == null) return fallback;
    switch (key) {
      case PaymentMessageKeys.flowStarted:
        return t.paymentFlowStarted(args?['channel']?.toString() ?? '');
      case PaymentMessageKeys.statusInitialized:
        return t.paymentStatusInitialized;
      case PaymentMessageKeys.statusPending:
        return t.paymentStatusPending;
      case PaymentMessageKeys.statusWaitingUser:
        return t.paymentStatusWaitingUser;
      case PaymentMessageKeys.statusProcessing:
        return t.paymentStatusProcessing;
      case PaymentMessageKeys.statusSuccess:
        return t.paymentStatusSuccess;
      case PaymentMessageKeys.statusFailure:
        return t.paymentStatusFailure;
      case PaymentMessageKeys.statusCancelled:
        return t.paymentStatusCancelled;
      case PaymentMessageKeys.statusNoUpdates:
        return t.paymentStatusNoUpdates;
      case PaymentMessageKeys.cardInitTerminal:
        return t.paymentCardInitTerminal;
      case PaymentMessageKeys.cardSuccess:
        return t.paymentCardSuccess;
      case PaymentMessageKeys.cardFailure:
        return t.paymentCardFailure;
      case PaymentMessageKeys.cardCancelled:
        return t.paymentCardCancelled;
      case PaymentMessageKeys.cardCancelFailed:
        return t.paymentCardCancelFailed(args?['detail']?.toString() ?? '');
      case PaymentMessageKeys.cardInitFailed:
        return t.paymentCardInitFailed(args?['detail']?.toString() ?? '');
      case PaymentMessageKeys.posStreamClosed:
        return t.paymentPosStreamClosed;
      case PaymentMessageKeys.qrWaitScan:
        return t.paymentQrWaitScan;
      case PaymentMessageKeys.qrRequestBackend:
        return t.paymentQrRequestBackend;
      case PaymentMessageKeys.qrPosPrompt:
        return t.paymentQrPosPrompt;
      case PaymentMessageKeys.qrSuccess:
        return t.paymentQrSuccess;
      case PaymentMessageKeys.qrFailure:
        return t.paymentQrFailure(args?['detail']?.toString() ?? '');
      case PaymentMessageKeys.qrCancelled:
        return t.paymentQrCancelled;
      case PaymentMessageKeys.qrConfigMissing:
        return t.paymentQrConfigMissing;
      case PaymentMessageKeys.posWaitingResponse:
        return t.paymentPosWaitingResponse;
      case PaymentMessageKeys.posProcessing:
        return t.paymentPosProcessing;
      case PaymentMessageKeys.cashPrepare:
        return t.paymentCashPrepare;
      case PaymentMessageKeys.cashAwaitConfirm:
        return t.paymentCashAwaitConfirm;
      case PaymentMessageKeys.cashConfirming:
        return t.paymentCashConfirming;
      case PaymentMessageKeys.cashSuccess:
        return t.paymentCashSuccess;
      case PaymentMessageKeys.cashFailure:
        return t.paymentCashFailure(args?['detail']?.toString() ?? '');
      case PaymentMessageKeys.cashConfirmFailed:
        return t.paymentCashConfirmFailed(args?['detail']?.toString() ?? '');
      case PaymentMessageKeys.cashCancelled:
        return t.paymentCashCancelled;
      case PaymentMessageKeys.cashStageIdle:
        return t.paymentCashStageIdle;
      case PaymentMessageKeys.cashStageChecking:
        return t.paymentCashStageChecking;
      case PaymentMessageKeys.cashStageOpening:
        return t.paymentCashStageOpening;
      case PaymentMessageKeys.cashStageAccepting:
        return t.paymentCashStageAccepting;
      case PaymentMessageKeys.cashStageCounting:
        return t.paymentCashStageCounting;
      case PaymentMessageKeys.cashStageClosing:
        return t.paymentCashStageClosing;
      case PaymentMessageKeys.cashStageCompleted:
        return t.paymentCashStageCompleted;
      case PaymentMessageKeys.cashStageNearFull:
        return t.paymentCashStageNearFull;
      case PaymentMessageKeys.cashStageFull:
        return t.paymentCashStageFull;
      case PaymentMessageKeys.cashStageError:
        return t.paymentCashStageError;
      case PaymentMessageKeys.cashStageChange:
        return t.paymentCashStageChange;
      case PaymentMessageKeys.cashStageChangeFailed:
        return t.paymentCashStageChangeFailed;
      case PaymentMessageKeys.cashAmountCurrent:
        return t.paymentCashAmountCurrent(args?['amount']?.toString() ?? '');
      case PaymentMessageKeys.cashAmountFinal:
        return t.paymentCashAmountFinal(args?['amount']?.toString() ?? '');
      case PaymentMessageKeys.errorUnknown:
        return t.paymentErrorUnknown(args?['detail']?.toString() ?? '');
      case PaymentMessageKeys.sessionMissing:
        return t.paymentSessionMissing;
      case PaymentMessageKeys.flowEnded:
        return t.paymentFlowEnded;
      default:
        return fallback;
    }
  }
}
