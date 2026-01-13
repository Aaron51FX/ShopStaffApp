import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/repositories/order_repository.dart';

final submitOrderUseCaseProvider = Provider<SubmitOrderUseCase>((ref) {
  return SubmitOrderUseCase(
    orderRepository: ref.watch(orderRepositoryProvider),
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
  });

  final List<CartItem> items;
  final String machineCode;
  final String language;
  final bool takeout;
  final double discount;
}

class SubmitOrderOutput {
  const SubmitOrderOutput({required this.order, required this.total});

  final OrderSubmissionResult order;
  final double total;
}

class SubmitOrderUseCase {
  SubmitOrderUseCase({
    required OrderRepository orderRepository,
    Logger? logger,
  })  : _orderRepository = orderRepository,
        _logger = logger ?? Logger('SubmitOrderUseCase');

  final OrderRepository _orderRepository;
  final Logger _logger;

  Future<SubmitOrderOutput> execute(SubmitOrderInput input) async {
    final total = input.items.fold<double>(0, (p, e) => p + e.lineTotal) - input.discount;
    _logger.fine('Submit order total=$total takeout=${input.takeout}');
    final result = await _orderRepository.submitOrder(
      items: input.items,
      machineCode: input.machineCode,
      language: input.language,
      takeout: input.takeout,
      total: total,
    );
    return SubmitOrderOutput(order: result, total: total);
  }
}
