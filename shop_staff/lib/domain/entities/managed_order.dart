import 'package:equatable/equatable.dart';

import 'cart_item.dart';
import 'local_order_record.dart';
import 'order_submission_result.dart';
import 'product.dart';

enum ManagedOrderStatus {
  unpaid(0),
  paid(1),
  canceled(2);

  const ManagedOrderStatus(this.apiValue);
  final int apiValue;

  static ManagedOrderStatus fromApi(dynamic value) {
    final normalized = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    return ManagedOrderStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => ManagedOrderStatus.unpaid,
    );
  }
}

class ManagedOrderQuery extends Equatable {
  const ManagedOrderQuery({
    required this.shopCode,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.page = 1,
    this.limit = 50,
  });

  final String shopCode;
  final ManagedOrderStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [
    shopCode,
    status,
    startDate,
    endDate,
    page,
    limit,
  ];
}

class ManagedOrder extends Equatable {
  const ManagedOrder({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.price,
    this.serialNumber = '',
    this.payChannel = '',
    this.payBizId = '',
    this.payPrice = 0,
    this.changeAmount = 0,
    this.discount = 0,
    this.payTime,
    this.remark = '',
    this.takeout = false,
  });

  final String orderId;
  final ManagedOrderStatus status;
  final DateTime? createdAt;
  final double price;
  final String serialNumber;
  final String payChannel;
  final String payBizId;
  final double payPrice;
  final double changeAmount;
  final double discount;
  final DateTime? payTime;
  final String remark;
  final bool takeout;

  bool get requiresExternalRefund =>
      status == ManagedOrderStatus.paid &&
      payChannel.isNotEmpty &&
      payChannel != '0' &&
      payChannel != 'Cash' &&
      payBizId.isEmpty;

  bool get usesOnlinePaymentCancellation =>
      status == ManagedOrderStatus.paid &&
      payChannel.isNotEmpty &&
      payChannel != '0' &&
      payChannel != 'Cash' &&
      payBizId.isNotEmpty;

  ManagedOrder copyWith({ManagedOrderStatus? status, String? payChannel}) {
    return ManagedOrder(
      orderId: orderId,
      status: status ?? this.status,
      createdAt: createdAt,
      price: price,
      serialNumber: serialNumber,
      payChannel: payChannel ?? this.payChannel,
      payBizId: payBizId,
      payPrice: payPrice,
      changeAmount: changeAmount,
      discount: discount,
      payTime: payTime,
      remark: remark,
      takeout: takeout,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    status,
    createdAt,
    price,
    serialNumber,
    payChannel,
    payBizId,
    payPrice,
    changeAmount,
    discount,
    payTime,
    remark,
    takeout,
  ];
}

class ManagedOrderPage extends Equatable {
  const ManagedOrderPage({required this.orders, required this.hasMore});

  final List<ManagedOrder> orders;
  final bool hasMore;

  @override
  List<Object?> get props => [orders, hasMore];
}

class ManagedOrderOption extends Equatable {
  const ManagedOrderOption({
    required this.groupName,
    required this.name,
    required this.price,
    required this.quantity,
    this.code = '',
  });

  final String groupName;
  final String name;
  final double price;
  final int quantity;
  final String code;

  @override
  List<Object?> get props => [groupName, name, price, quantity, code];
}

class ManagedOrderLine extends Equatable {
  const ManagedOrderLine({
    required this.name,
    required this.quantity,
    required this.price,
    required this.options,
    this.productId = 0,
    this.categoryId = '',
    this.tax = 0,
  });

  final int productId;
  final String categoryId;
  final String name;
  final int quantity;
  final double price;
  final int tax;
  final List<ManagedOrderOption> options;

  @override
  List<Object?> get props => [
    productId,
    categoryId,
    name,
    quantity,
    price,
    tax,
    options,
  ];
}

class ManagedOrderDetail extends Equatable {
  const ManagedOrderDetail({required this.order, required this.lines});

  final ManagedOrder order;
  final List<ManagedOrderLine> lines;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  LocalOrderRecord toLocalOrder({
    required String machineCode,
    required String language,
  }) {
    final items = <CartItem>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final productId = line.productId == 0
          ? line.name.hashCode.abs() + index
          : line.productId;
      final product = Product(
        id: productId,
        name: line.name,
        categoryId: line.categoryId,
        price: line.price,
        originalPrice: line.price,
        tax: line.tax,
        imageUrl: '',
      );
      final options = line.options
          .map(
            (option) => SelectedOption(
              groupCode: option.groupName,
              groupName: option.groupName,
              optionCode: option.code.isEmpty ? option.name : option.code,
              optionName: option.name,
              extraPrice: option.price,
              quantity: option.quantity,
            ),
          )
          .toList(growable: false);
      items.add(
        CartItem(
          id: '$productId-${options.map((option) => option.optionCode).join('|')}',
          product: product,
          options: options,
          quantity: line.quantity,
        ),
      );
    }

    return LocalOrderRecord(
      orderId: order.orderId,
      createdAt: order.createdAt ?? DateTime.now(),
      isPaid: order.status == ManagedOrderStatus.paid,
      payMethod: order.payChannel,
      items: items,
      machineCode: machineCode,
      language: language,
      takeout: order.takeout,
      discount: order.discount.abs(),
      clientTotal: order.price,
      orderResult: OrderSubmissionResult(
        orderId: order.orderId,
        tax1: 0,
        baseTax1: 0,
        tax2: 0,
        baseTax2: 0,
        total: order.price.toInt(),
      ),
    );
  }

  @override
  List<Object?> get props => [order, lines];
}
