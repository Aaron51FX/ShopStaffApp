part of '../pages/payment_selection_page.dart';

class _PaymentSummaryData {
  const _PaymentSummaryData({
    required this.subtotal,
    required this.discount,
    required this.tax10,
    required this.tax8,
  });

  final double subtotal;
  final double discount;
  final double tax10;
  final double tax8;

  factory _PaymentSummaryData.fromArgs(
    PaymentSelectionPageArgs args, {
    OrderSubmissionResult? order,
  }) {
    return _PaymentSummaryData(
      subtotal: args.subtotal,
      discount: args.discount,
      tax10: order?.tax1.toDouble() ?? 0,
      tax8: order?.tax2.toDouble() ?? 0,
    );
  }
}
