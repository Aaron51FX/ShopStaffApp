import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/data/services/star_cash_machine_service.dart';
import 'package:shop_staff/data/services/starxpand_cash_drawer_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:starxpand_flutter/starxpand_flutter.dart';

void main() {
  group('StarCashMachineService', () {
    const settings = CashMachineSettings(
      enabled: true,
      brand: CashMachineBrand.star,
      connectionType: PrinterConnectionType.bluetoothClassic,
      deviceIdentifier: 'STAR-DRAWER-001',
      modelName: 'mC-Print3',
    );

    test('initialize fails when drawer is already open', () async {
      final drawerService = _FakeStarXpandCashDrawerService(
        status: const StarXpandDrawerStatus(
          hasError: false,
          coverOpen: false,
          drawerOpenCloseSignal: true,
          paperEmpty: false,
          paperNearEmpty: false,
        ),
      );
      final service = StarCashMachineService(
        settings: settings,
        drawerService: drawerService,
        logger: Logger('TestStarCashMachine'),
      );

      final result = await service.initialize();

      expect(result.isReady, isFalse);
      expect(result.message, contains('打开状态'));
    });

    test('runPayment opens drawer and returns expected receipt', () async {
      final drawerService = _FakeStarXpandCashDrawerService(
        status: const StarXpandDrawerStatus(
          hasError: false,
          coverOpen: false,
          drawerOpenCloseSignal: false,
          paperEmpty: false,
          paperNearEmpty: false,
        ),
      );
      final service = StarCashMachineService(
        settings: settings,
        drawerService: drawerService,
        logger: Logger('TestStarCashMachine'),
      );

      final receipt = await service.runPayment(1280);
      final completed = await service.completePayment();

      expect(drawerService.openCallCount, 1);
      expect(receipt.acceptedAmount, 1280);
      expect(receipt.expectedAmount, 1280);
      expect(completed.acceptedAmount, 1280);
    });

    test('runPayment throws busy when previous payment is pending', () async {
      final drawerService = _FakeStarXpandCashDrawerService(
        status: const StarXpandDrawerStatus(
          hasError: false,
          coverOpen: false,
          drawerOpenCloseSignal: false,
          paperEmpty: false,
          paperNearEmpty: false,
        ),
      );
      final service = StarCashMachineService(
        settings: settings,
        drawerService: drawerService,
        logger: Logger('TestStarCashMachine'),
      );

      await service.runPayment(500);

      expect(
        () => service.runPayment(500),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _FakeStarXpandCashDrawerService extends StarXpandCashDrawerService {
  _FakeStarXpandCashDrawerService({required this.status});

  final StarXpandDrawerStatus status;
  int openCallCount = 0;

  @override
  Future<StarXpandDrawerStatus> getStatus({
    required CashMachineSettings settings,
  }) async {
    return status;
  }

  @override
  Future<void> openDrawer({
    required CashMachineSettings settings,
    StarXpandDrawerChannel channel = StarXpandDrawerChannel.no1,
    int onTimeMs = 200,
  }) async {
    openCallCount += 1;
  }
}
