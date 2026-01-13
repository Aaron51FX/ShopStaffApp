import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/datasources/local/suspended_order_local_data_source.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/suspended_order.dart';

final suspendedOrdersUseCasesProvider = Provider<SuspendedOrdersUseCases>((ref) {
  return SuspendedOrdersUseCases(
    local: ref.watch(suspendedOrderLocalDataSourceProvider),
    logger: Logger('SuspendedOrdersUseCases'),
  );
});

/// Small group of related use cases for suspended orders.
class SuspendedOrdersUseCases {
  SuspendedOrdersUseCases({
    required SuspendedOrderLocalDataSource local,
    Logger? logger,
  })  : _local = local,
        _logger = logger ?? Logger('SuspendedOrdersUseCases');

  final SuspendedOrderLocalDataSource _local;
  final Logger _logger;

  Future<List<SuspendedOrder>> loadAll() async {
    _logger.fine('Load suspended orders');
    return _local.loadAll();
  }

  Future<void> save(SuspendedOrder order) async {
    _logger.fine('Save suspended order id=${order.id}');
    await _local.save(order);
  }

  Future<void> delete(String id) async {
    _logger.fine('Delete suspended order id=$id');
    await _local.delete(id);
  }
}
