import 'package:shop_staff/domain/entities/cash_register_closure.dart';

abstract class CashRegisterClosureRepository {
  Future<List<CashRegisterClosureMailAccount>> fetchMailList({
    required String machineCode,
  });

  Future<void> sendAdminVerify({
    required String machineCode,
    required String verifyEmail,
    required String verifyUserName,
  });

  Future<CashRegisterClosureSummary> fetchStaffRejishime(
    CashRegisterClosureVerifyInput input,
  );

  Future<void> confirm(CashRegisterClosureVerifyInput input);
}
