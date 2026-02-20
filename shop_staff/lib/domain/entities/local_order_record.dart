import 'package:equatable/equatable.dart';

import 'cart_item.dart';
import 'order_submission_result.dart';

abstract class LocalOrderPayMethods {
  static const String abnormalCancelForceExit = 'ABNORMAL_CANCEL_FORCE_EXIT';
}

class LocalOrderRecord extends Equatable {
  const LocalOrderRecord({
    required this.orderId,
    required this.createdAt,
    required this.isPaid,
    this.payMethod = "",
    required this.items,
    required this.machineCode,
    required this.language,
    required this.takeout,
    required this.discount,
    required this.clientTotal,
    required this.orderResult,
    this.abnormalExit = false,
    this.abnormalReason,
    this.abnormalSessionId,
  });

  final String orderId;
  final DateTime createdAt;
  final bool isPaid;

  /// Payment method resolved from print document. Defaults to unknown.
  final String payMethod;

  /// Cart snapshot at submit time.
  final List<CartItem> items;

  /// Request context.
  final String machineCode;
  final String language;
  final bool takeout;
  final double discount;
  final double clientTotal;

  /// Backend response from order submit.
  final OrderSubmissionResult orderResult;

  /// Whether this order was force-exited from payment cancellation failure recovery.
  final bool abnormalExit;

  /// Optional machine-readable abnormal reason.
  final String? abnormalReason;

  /// Optional payment session id when abnormal exit occurred.
  final String? abnormalSessionId;

  bool get isAbnormalForceExit =>
      abnormalExit || payMethod == LocalOrderPayMethods.abnormalCancelForceExit;

  LocalOrderRecord copyWith({
    bool? isPaid,
    String? payMethod,
    bool? abnormalExit,
    String? abnormalReason,
    String? abnormalSessionId,
  }) {
    return LocalOrderRecord(
      orderId: orderId,
      createdAt: createdAt,
      isPaid: isPaid ?? this.isPaid,
      payMethod: payMethod ?? this.payMethod,
      items: items,
      machineCode: machineCode,
      language: language,
      takeout: takeout,
      discount: discount,
      clientTotal: clientTotal,
      orderResult: orderResult,
      abnormalExit: abnormalExit ?? this.abnormalExit,
      abnormalReason: abnormalReason ?? this.abnormalReason,
      abnormalSessionId: abnormalSessionId ?? this.abnormalSessionId,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        createdAt,
        isPaid,
        payMethod,
        items,
        machineCode,
        language,
        takeout,
        discount,
        clientTotal,
        orderResult,
        abnormalExit,
        abnormalReason,
        abnormalSessionId,
      ];
}
