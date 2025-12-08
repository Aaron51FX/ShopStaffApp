
import 'package:flutter/material.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';

class StatusHero extends StatelessWidget {
  const StatusHero({super.key, required this.state, required this.args, this.onRetry});

  final PaymentFlowState state;
  final PaymentFlowPageArgs args;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final current = state.currentStatus;
    final theme = Theme.of(context);
    final effectiveResult = state.result?.status;
    final hasError = state.error != null;
    final message = hasError
        ? state.error!
        : current?.message ?? _defaultMessage(args.channelGroup, current?.type);
    final icon = hasError ? Icons.error_rounded : StatusHero.iconForStatus(current?.type, effectiveResult);
    final color = hasError ? Colors.redAccent : _colorForStatus(theme, current?.type, effectiveResult);
    final showRetry = _shouldShowRetry(state) && onRetry != null;

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
                  Text(_instructionFor(args.channelGroup), style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if (showRetry) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 50),
              label: const Text('重试', style: TextStyle(fontSize: 16)),
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

  static String _defaultMessage(String group, PaymentStatusType? type) {
    switch (group) {
      case PaymentChannels.card:
        if (type == PaymentStatusType.pending) return '正在连接终端…';
        if (type == PaymentStatusType.processing) return '请按照POS终端提示操作';
        return '信用卡支付处理中';
      case PaymentChannels.cash:
        if (type == PaymentStatusType.pending) return '请准备现金';
        if (type == PaymentStatusType.waitingForUser) return '等待顾客投入现金';
        return '现金支付处理中';
      case PaymentChannels.qr:
        if (type == PaymentStatusType.waitingForUser) return '请将二维码对准扫描区';
        return '二维码支付处理中';
      default:
        return '支付处理中';
    }
  }

  static String _instructionFor(String group) {
    switch (group) {
      case PaymentChannels.card:
        return '请按照终端提示插卡、刷卡或挥卡，完成支付后不要立即拔卡。';
      case PaymentChannels.cash:
        return '现金投入完成后，请等待机器找零并领取收据。';
      case PaymentChannels.qr:
        return '请使用顾客手机的二维码对准扫描器，等待确认提示。';
      default:
        return '请按照屏幕或终端提示完成支付。';
    }
  }

  static bool _shouldShowRetry(PaymentFlowState state) {
    if (state.isCancelling) return false;
    if (state.error != null) return true;
    final result = state.result?.status;
    if (result == PaymentStatusType.failure || result == PaymentStatusType.cancelled) {
      return true;
    }
    final currentType = state.currentStatus?.type;
    return currentType == PaymentStatusType.failure || currentType == PaymentStatusType.cancelled;
  }
}





