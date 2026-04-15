import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/repositories/bookkeeping_order_repository.dart';

final submitOrderUseCaseProvider = Provider<SubmitOrderUseCase>((ref) {
  return SubmitOrderUseCase(
    bookkeepingOrderRepository: ref.watch(bookkeepingOrderRepositoryProvider),
    logger: Logger('SubmitOrderUseCase'),
  );
});

class SubmitOrderInput {
  const SubmitOrderInput({
    required this.items,
    required this.machineCode,
    required this.language,
    required this.takeout,
    required this.discount,
    this.shopCode,
  });

  final List<CartItem> items;
  final String machineCode;
  final String language;
  final bool takeout;
  final double discount;
  final String? shopCode;
}

class SubmitOrderOutput {
  const SubmitOrderOutput({required this.order, required this.total});

  final OrderSubmissionResult order;
  final double total;
}

class SubmitOrderUseCase {
  SubmitOrderUseCase({
    required BookkeepingOrderRepository bookkeepingOrderRepository,
    Logger? logger,
  }) : _bookkeepingOrderRepository = bookkeepingOrderRepository,
       _logger = logger ?? Logger('SubmitOrderUseCase');

  final BookkeepingOrderRepository _bookkeepingOrderRepository;
  final Logger _logger;

  Future<SubmitOrderOutput> execute(SubmitOrderInput input) async {
    final total =
        input.items.fold<double>(0, (p, e) => p + e.lineTotal) - input.discount;
    _logger.fine('Prepare checkout order total=$total takeout=${input.takeout}');
    final result = await _bookkeepingOrderRepository.submitOfflineOrder(
      items: input.items,
      machineCode: input.machineCode,
      language: input.language,
      takeout: input.takeout,
      total: total,
      shopCode: input.shopCode,
    );
    return SubmitOrderOutput(order: result, total: total);
  }
}
