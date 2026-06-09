import 'package:shop_staff/domain/entities/cash_register_closure.dart';

class CashRegisterClosurePageArgs {
  const CashRegisterClosurePageArgs({
    required this.machineCode,
    required this.shopName,
  });

  final String machineCode;
  final String shopName;
}

class CashRegisterClosureDetailPageArgs {
  const CashRegisterClosureDetailPageArgs({
    required this.machineCode,
    required this.shopName,
    this.summary,
    this.input,
    this.mail,
    required this.isHistory,
  });

  const CashRegisterClosureDetailPageArgs.pending({
    required this.machineCode,
    required this.shopName,
    required CashRegisterClosureMailAccount this.mail,
  }) : summary = null,
       input = null,
       isHistory = false;

  final String machineCode;
  final String shopName;
  final CashRegisterClosureSummary? summary;
  final CashRegisterClosureVerifyInput? input;
  final CashRegisterClosureMailAccount? mail;
  final bool isHistory;
}
