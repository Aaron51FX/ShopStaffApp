import 'package:equatable/equatable.dart';

import 'cart_item.dart';
import 'order_submission_result.dart';


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

  LocalOrderRecord copyWith({
    bool? isPaid,
    String? payMethod,
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
      ];
}
