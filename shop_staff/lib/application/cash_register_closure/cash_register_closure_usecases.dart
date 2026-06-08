import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/data/datasources/local/cash_register_closure_local_data_source.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/domain/repositories/cash_register_closure_repository.dart';

final cashRegisterClosureUseCasesProvider =
    Provider<CashRegisterClosureUseCases>((ref) {
      return CashRegisterClosureUseCases(
        repository: ref.watch(cashRegisterClosureRepositoryProvider),
        local: ref.watch(cashRegisterClosureLocalDataSourceProvider),
        logger: Logger('CashRegisterClosureUseCases'),
      );
    });

class CashRegisterClosureUseCases {
  CashRegisterClosureUseCases({
    required CashRegisterClosureRepository repository,
    required CashRegisterClosureLocalDataSource local,
    Logger? logger,
  }) : _repository = repository,
       _local = local,
       _logger = logger ?? Logger('CashRegisterClosureUseCases');

  final CashRegisterClosureRepository _repository;
  final CashRegisterClosureLocalDataSource _local;
  final Logger _logger;

  Future<List<CashRegisterClosureHistoryRecord>> loadHistory() {
    return _local.loadRecent(maxAge: const Duration(days: 31));
  }

  Future<List<CashRegisterClosureMailAccount>> fetchMailList({
    required String machineCode,
  }) {
    _logger.fine('Fetch cash register closure mail list machine=$machineCode');
    return _repository.fetchMailList(machineCode: machineCode);
  }

  Future<void> sendAdminVerify({
    required String machineCode,
    required String verifyEmail,
    required String verifyUserName,
  }) {
    _logger.fine(
      'Send cash register closure verify code machine=$machineCode '
      'email=$verifyEmail user=$verifyUserName',
    );
    return _repository.sendAdminVerify(
      machineCode: machineCode,
      verifyEmail: verifyEmail,
      verifyUserName: verifyUserName,
    );
  }

  Future<CashRegisterClosureSummary> fetchStaffRejishime(
    CashRegisterClosureVerifyInput input,
  ) {
    _logger.fine(
      'Fetch staff rejishime info machine=${input.machineCode} '
      'email=${input.verifyEmail}',
    );
    return _repository.fetchStaffRejishime(input);
  }

  Future<CashRegisterClosureHistoryRecord> saveConfirmedHistory(
    CashRegisterClosureSummary summary,
  ) {
    _logger.fine(
      'Save confirmed cash register closure machine=${summary.machineCode} '
      'printTime=${summary.printTime}',
    );
    return _local.save(summary);
  }

  Future<void> confirm(CashRegisterClosureVerifyInput input) {
    _logger.fine(
      'Confirm cash register closure machine=${input.machineCode} '
      'email=${input.verifyEmail}',
    );
    return _repository.confirm(input);
  }
}
