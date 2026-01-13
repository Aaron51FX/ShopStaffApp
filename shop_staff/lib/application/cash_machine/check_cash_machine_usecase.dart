import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';

final checkCashMachineUseCaseProvider = Provider<CheckCashMachineUseCase>((ref) {
  return CheckCashMachineUseCase(
    cashMachine: ref.watch(cashMachineServiceProvider),
    logger: Logger('CheckCashMachineUseCase'),
  );
});

class CheckCashMachineResult {
  const CheckCashMachineResult({required this.isReady, this.message});

  final bool isReady;
  final String? message;
}

/// Application-layer orchestration for the "cash machine health check" step.
///
/// Why a UseCase:
/// - Entry/Settings UI wants a stable, consistent check flow and messaging.
/// - The underlying hardware steps may vary by cash-machine model/vendor.
/// - Later you can route to different implementations (factory/strategy)
///   without touching the presentation state machine.
class CheckCashMachineUseCase {
  CheckCashMachineUseCase({
    required CashMachineService cashMachine,
    Logger? logger,
  })  : _cashMachine = cashMachine,
        _logger = logger ?? Logger('CheckCashMachineUseCase');

  final CashMachineService _cashMachine;
  final Logger _logger;

  Future<CheckCashMachineResult> execute() async {
    _logger.fine('Cash machine check start');
    final result = await _cashMachine.initialize();
    _logger.fine('Cash machine check done isReady=${result.isReady}');
    return CheckCashMachineResult(isReady: result.isReady, message: result.message);
  }
}
