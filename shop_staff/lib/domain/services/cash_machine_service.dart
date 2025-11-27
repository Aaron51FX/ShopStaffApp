abstract class CashMachineService {
  Future<CashMachineInitResult> initialize();
  Future<void> dispose();
  // 其它：startPayment、cancelPayment 等
}

class CashMachineInitResult {
  final bool isReady;
  final String? message;
  const CashMachineInitResult({required this.isReady, this.message});
}