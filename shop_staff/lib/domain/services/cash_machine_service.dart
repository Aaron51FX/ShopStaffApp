enum CashMachineStage {
  idle,
  checking,
  opening,
  accepting,
  counting,
  change,
  changeFailed,
  closing,
  completed,
  nearfull,
  full,
  error,
}

abstract class CashMachineEvent {
  const CashMachineEvent();
}

class CashMachineStageEvent extends CashMachineEvent {
  const CashMachineStageEvent(this.stage, {this.message});

  final CashMachineStage stage;
  final String? message;
}

class CashMachineAmountEvent extends CashMachineEvent {
  const CashMachineAmountEvent(this.amount, {this.isFinal = false});

  final int amount;
  final bool isFinal;
}

class CashMachineErrorEvent extends CashMachineEvent {
  const CashMachineErrorEvent(this.message);

  final String message;
}

class CashMachineReceiptReadyEvent extends CashMachineEvent {
  const CashMachineReceiptReadyEvent(this.receipt);

  final CashMachineReceipt receipt;
}

abstract class CashMachineService {
  Stream<CashMachineEvent> get events;

  Future<CashMachineInitResult> initialize();

  /// Runs the full cash-acceptance sequence (open -> accept -> close) and
  /// returns the resulting receipt.
  Future<CashMachineReceipt> runPayment(int amount);

  Future<CashMachineReceipt> completePayment();

  /// Attempts to abort any ongoing sequence and bring the machine back to idle.
  Future<void> cancelPayment();

  Future<void> dispose();
}

class CashMachineInitResult {
  final bool isReady;
  final String? message;
  const CashMachineInitResult({required this.isReady, this.message});
}

class CashMachineReceipt {
  const CashMachineReceipt({required this.acceptedAmount, required this.expectedAmount, this.raw});

  final int acceptedAmount;
  final int expectedAmount;
  final Map<String, dynamic>? raw;

  Map<String, dynamic> toJson() => {
        'acceptedAmount': acceptedAmount,
        'expectedAmount': expectedAmount,
        if (raw != null) 'raw': raw,
      };
}
