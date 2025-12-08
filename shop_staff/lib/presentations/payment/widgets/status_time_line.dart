
import 'package:flutter/material.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_state.dart';
import 'package:shop_staff/presentations/payment/widgets/status_hero.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.state});

  final PaymentFlowState state;

  @override
  Widget build(BuildContext context) {
    final history = state.timeline;
    if (history.isEmpty) {
      if (state.error != null) {
        return Center(
          child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
        );
      }
      return const Center(child: Text('暂无状态更新'));
    }
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final status = history[index];
        return ListTile(
          leading: Icon(StatusHero.iconForStatus(status.type, null)),
          title: Text(status.message ?? _label(status.type)),
        );
      },
    );
  }

  static String _label(PaymentStatusType type) {
    switch (type) {
      case PaymentStatusType.initialized:
        return '初始化';
      case PaymentStatusType.pending:
        return '待处理';
      case PaymentStatusType.waitingForUser:
        return '等待顾客操作';
      case PaymentStatusType.processing:
        return '处理中';
      case PaymentStatusType.success:
        return '支付成功';
      case PaymentStatusType.failure:
        return '支付失败';
      case PaymentStatusType.cancelled:
        return '支付已取消';
    }
  }
}