import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';

final localOrdersUseCasesProvider = Provider<LocalOrdersUseCases>((ref) {
  return LocalOrdersUseCases(
    local: ref.watch(localOrderLocalDataSourceProvider),
    logger: Logger('LocalOrdersUseCases'),
  );
});

class LocalOrdersUseCases {
  LocalOrdersUseCases({
    required LocalOrderLocalDataSource local,
    Logger? logger,
  })  : _local = local,
        _logger = logger ?? Logger('LocalOrdersUseCases');

  final LocalOrderLocalDataSource _local;
  final Logger _logger;

  Future<List<LocalOrderRecord>> loadAll() async {
    _logger.fine('Load local orders');
    return _local.loadAll();
  }

  Future<LocalOrderRecord?> getById(String orderId) async {
    return _local.getById(orderId);
  }

  Future<void> save(LocalOrderRecord record) async {
    _logger.fine('Save local order id=${record.orderId} paid=${record.isPaid}');
    await _local.save(record);
  }

  Future<void> updatePaid(String orderId, bool isPaid) async {
    _logger.fine('Update local order id=$orderId paid=$isPaid');
    await _local.updatePaid(orderId, isPaid);
  }

  Future<void> delete(String orderId) async {
    _logger.fine('Delete local order id=$orderId');
    await _local.delete(orderId);
  }
}
