import 'package:shop_staff/application/pos/usecases/local_orders_usecases.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';

class RecordAbnormalPaymentExitUseCase {
  const RecordAbnormalPaymentExitUseCase({required LocalOrdersUseCases orders})
    : _orders = orders;

  static const String forceExitReason = 'cancel_failure_force_exit';
  static const String payMethod = LocalOrderPayMethods.abnormalCancelForceExit;

  final LocalOrdersUseCases _orders;

  /// Returns false when the order no longer exists locally.
  Future<bool> execute({required String orderId, String? sessionId}) async {
    final existing = await _orders.getById(orderId);
    if (existing == null) return false;

    final alreadyRecorded =
        existing.payMethod == payMethod &&
        !existing.isPaid &&
        existing.abnormalExit &&
        existing.abnormalReason == forceExitReason &&
        existing.abnormalSessionId == sessionId;
    if (!alreadyRecorded) {
      await _orders.save(
        existing.copyWith(
          isPaid: false,
          payMethod: payMethod,
          abnormalExit: true,
          abnormalReason: forceExitReason,
          abnormalSessionId: sessionId,
        ),
      );
    }
    return true;
  }
}
