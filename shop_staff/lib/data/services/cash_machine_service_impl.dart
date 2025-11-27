
import 'package:flutter/material.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';
import 'package:shop_staff/plugins/cash_changer/lib/cash_changer.dart';
import 'package:shop_staff/plugins/cash_changer/lib/cash_changer_define.dart';
import 'package:logging/logging.dart';

class CashMachineServiceImpl implements CashMachineService {
  final Logger _logger;
  
  CashMachineServiceImpl(this._logger);

  @override
  Future<CashMachineInitResult> initialize() async {
    try {
      final status = await CashChanger.checkChangerStatus;
      // if (!status.isSuccess) {
      //   return _fail(status.error);
      // }
      
      if (!status.isSuccess) {
        int retCode = status.error?.code ?? -1;
        debugPrint('Cash Changer open error code: $retCode');
        if (retCode == 0) {
          retCode = 100;
        }
        HealthResultCode resultCodeEnum = HealthResultCode.values[retCode - 100];

        switch (resultCodeEnum) {
          case HealthResultCode.OPOS_SUCCESS:
          case HealthResultCode.OPOS_E_ILLEGAL:
            //await stopCashChanger(DepositAction.repay.index, true);
            break;
          case HealthResultCode.OPOS_E_CLOSED:
          case HealthResultCode.OPOS_E_NOTCLAIMED:
          case HealthResultCode.OPOS_E_DISABLED:
            //await openCashChanger();
            break;
          case HealthResultCode.OPOS_E_BUSY:
            await Future.delayed(Duration(seconds: 5));
            //await checkChangerStatus();
            break;
          case HealthResultCode.OPOS_E_NOHARDWARE:
            break;
          default:
            break;
        }

        //return _fail(open.error);
      }

      final open = await CashChanger.openCashChanger();
      if (!open.isSuccess) return _fail(open.error);

      final start = await CashChanger.startDeposit();
      if (!start.isSuccess) return _fail(start.error);

      final deposit = await CashChanger.depositAmount;
      if (!deposit.isSuccess) return _fail(deposit.error);

      final end = await CashChanger.endDeposit(DepositAction.repay.index);
      if (!end.isSuccess) return _fail(end.error);

      return const CashMachineInitResult(isReady: true);
    } catch (e, s) {
      _logger.severe('Cash init error', e, s);
      return CashMachineInitResult(isReady: false, message: e.toString());
    }
  }

  CashMachineInitResult _fail(CashOperationError? err) {
    final msg = err?.message ?? 'cash_error_common';
    return CashMachineInitResult(isReady: false, message: msg);
  }

  @override
  Future<void> dispose() async {
    await CashChanger.closeCashChanger;
  }
}