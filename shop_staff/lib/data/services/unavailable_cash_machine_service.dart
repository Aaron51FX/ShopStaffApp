import 'package:shop_staff/domain/services/cash_machine_service.dart';

class UnavailableCashMachineService implements CashMachineService {
  const UnavailableCashMachineService(this.message);

  final String message;

  @override
  Stream<CashMachineEvent> get events => const Stream<CashMachineEvent>.empty();

  @override
  Future<CashMachineInitResult> initialize() async {
    return CashMachineInitResult(isReady: false, message: message);
  }

  @override
  Future<CashMachineReceipt> runPayment(int amount) async {
    throw StateError(message);
  }

  @override
  Future<CashMachineReceipt> completePayment() async {
    throw StateError(message);
  }

  @override
  Future<void> cancelPayment() async {}

  @override
  Future<void> dispose() async {}
}
