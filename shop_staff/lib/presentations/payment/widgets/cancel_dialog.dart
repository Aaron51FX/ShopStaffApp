
import 'package:flutter/material.dart';
import 'package:shop_staff/presentations/payment/viewmodels/cancel_dialog_state.dart';

class CancelDialog extends StatelessWidget {
  const CancelDialog({super.key, required this.state, required this.onClose});

  final CancelDialogState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CancelDialogStatus.loading:
        return AlertDialog(
          title: const Text('正在取消'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 16),
              Expanded(child: Text(state.message ?? '正在向终端发送取消指令…')),
            ],
          ),
        );
      case CancelDialogStatus.success:
      case CancelDialogStatus.failure:
        final isSuccess = state.status == CancelDialogStatus.success;
        final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_outline;
        final color = isSuccess ? Colors.green : Colors.redAccent;
        final title = isSuccess ? '取消成功' : '取消失败';
        final message = state.message ?? (isSuccess ? '支付已取消' : '取消失败，请稍后重试');
        return AlertDialog(
          title: Text(title),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: onClose,
              child: Text(isSuccess ? '完成' : '确定'),
            ),
          ],
        );
      case CancelDialogStatus.hidden:
        return const SizedBox.shrink();
    }
  }
}