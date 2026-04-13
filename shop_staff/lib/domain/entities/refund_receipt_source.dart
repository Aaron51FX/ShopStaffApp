import 'package:equatable/equatable.dart';

import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/receipt_document.dart';

/// Raw refund settlement row returned by the refund API.
///
/// The backend field meanings are not fully normalized yet, so both `amountMinor`
/// and `payAmountMinor` are preserved as-is for downstream mapping.
class RefundSettlementRecord extends Equatable {
  const RefundSettlementRecord({
    this.address,
    required this.amountMinor,
    required this.changeMinor,
    required this.couponMinor,
    this.couponType,
    required this.executeMark,
    this.machineCode,
    this.orderId,
    this.orderIdStr,
    required this.payAmountMinor,
    this.payChannel,
    this.payTime,
    this.requestMessage,
    this.responseMessage,
    this.serialNumber,
    this.shopName,
    this.telNo,
  });

  final String? address;
  final int amountMinor;
  final int changeMinor;
  final int couponMinor;
  final int? couponType;
  final bool executeMark;
  final String? machineCode;
  final int? orderId;
  final String? orderIdStr;
  final int payAmountMinor;
  final String? payChannel;
  final String? payTime;
  final String? requestMessage;
  final String? responseMessage;
  final String? serialNumber;
  final String? shopName;
  final String? telNo;

  factory RefundSettlementRecord.fromJson(Map<String, dynamic> json) {
    return RefundSettlementRecord(
      address: _nullableString(json['address']),
      amountMinor: _toInt(json['amount']),
      changeMinor: _toInt(json['change']),
      couponMinor: _toInt(json['coupon']),
      couponType: _toIntOrNull(json['couponType']),
      executeMark: json['executeMark'] == true,
      machineCode: _nullableString(json['machineCode']),
      orderId: _toIntOrNull(json['orderId']),
      orderIdStr: _nullableString(json['orderIdStr']),
      payAmountMinor: _toInt(json['payAmount']),
      payChannel: _nullableString(json['payChannel']),
      payTime: _nullableString(json['payTime']),
      requestMessage: _nullableString(json['requestMessage']),
      responseMessage: _nullableString(json['responseMessage']),
      serialNumber: _nullableString(json['serialNumber']),
      shopName: _nullableString(json['shopName']),
      telNo: _nullableString(json['telNo']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (address != null) 'address': address,
      'amount': amountMinor,
      'change': changeMinor,
      'coupon': couponMinor,
      if (couponType != null) 'couponType': couponType,
      'executeMark': executeMark,
      if (machineCode != null) 'machineCode': machineCode,
      if (orderId != null) 'orderId': orderId,
      if (orderIdStr != null) 'orderIdStr': orderIdStr,
      'payAmount': payAmountMinor,
      if (payChannel != null) 'payChannel': payChannel,
      if (payTime != null) 'payTime': payTime,
      if (requestMessage != null) 'requestMessage': requestMessage,
      if (responseMessage != null) 'responseMessage': responseMessage,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (shopName != null) 'shopName': shopName,
      if (telNo != null) 'telNo': telNo,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    address,
    amountMinor,
    changeMinor,
    couponMinor,
    couponType,
    executeMark,
    machineCode,
    orderId,
    orderIdStr,
    payAmountMinor,
    payChannel,
    payTime,
    requestMessage,
    responseMessage,
    serialNumber,
    shopName,
    telNo,
  ];
}

class RefundLineSelection extends Equatable {
  const RefundLineSelection({
    this.originalLineId,
    required this.name,
    this.categoryName,
    required this.quantity,
    this.originalQuantity,
    required this.unitPriceMinor,
    this.lineTotalMinor,
    this.options = const <ReceiptLineOption>[],
    this.note,
  });

  final String? originalLineId;
  final String name;
  final String? categoryName;
  final int quantity;
  final int? originalQuantity;
  final int unitPriceMinor;
  final int? lineTotalMinor;
  final List<ReceiptLineOption> options;
  final String? note;

  int get resolvedLineTotalMinor {
    final optionDeltaPerUnit = options.fold<int>(
      0,
      (sum, option) => sum + option.priceDeltaMinor * option.quantity,
    );
    return lineTotalMinor ?? (unitPriceMinor + optionDeltaPerUnit) * quantity;
  }

  ReceiptLine toReceiptLine() {
    return ReceiptLine(
      lineId: originalLineId,
      name: name,
      categoryName: categoryName,
      quantity: quantity,
      originalQuantity: originalQuantity,
      unitPriceMinor: unitPriceMinor,
      lineTotalMinor: resolvedLineTotalMinor,
      options: options,
      note: note,
    );
  }

  factory RefundLineSelection.fromPrintOrderLine(
    PrintOrderLine line, {
    int? quantity,
    String? note,
  }) {
    final actualQty = quantity ?? line.qty;
    final options = line.options.entries
        .expand(
          (entry) => entry.value.map(
            (option) => ReceiptLineOption(
              group: entry.key,
              name: option.name,
              quantity: option.qty <= 0 ? 1 : option.qty,
              priceDeltaMinor: option.price ?? 0,
            ),
          ),
        )
        .toList(growable: false);

    return RefundLineSelection(
      originalLineId: line.bizId > 0 ? line.bizId.toString() : null,
      name: line.name,
      categoryName: line.categoryName.isEmpty ? null : line.categoryName,
      quantity: actualQty <= 0 ? 1 : actualQty,
      originalQuantity: line.qty <= 0 ? null : line.qty,
      unitPriceMinor: line.price,
      options: options,
      note: note,
    );
  }

  factory RefundLineSelection.fromCartItem(CartItem item, {int? quantity}) {
    final actualQty = quantity ?? item.quantity;
    return RefundLineSelection(
      originalLineId: item.id,
      name: item.product.name,
      quantity: actualQty <= 0 ? 1 : actualQty,
      originalQuantity: item.quantity <= 0 ? null : item.quantity,
      unitPriceMinor: item.product.price.round(),
      options: item.options
          .map(
            (option) => ReceiptLineOption(
              group: option.groupName,
              name: option.optionName,
              quantity: option.quantity <= 0 ? 1 : option.quantity,
              priceDeltaMinor: option.extraPrice.round(),
            ),
          )
          .toList(growable: false),
      note: item.note,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    originalLineId,
    name,
    categoryName,
    quantity,
    originalQuantity,
    unitPriceMinor,
    lineTotalMinor,
    options,
    note,
  ];
}

class RefundReceiptSource extends Equatable {
  const RefundReceiptSource({
    required this.originalOrder,
    this.originalPrintInfo,
    required this.refundedLines,
    required this.settlements,
    required this.refundId,
    required this.reasonCode,
    required this.reasonLabel,
    this.operatorId,
    this.operatorName,
    this.processedAt,
    this.requestedTotalMinor,
    this.taxLines = const <ReceiptTaxLine>[],
  });

  final LocalOrderRecord originalOrder;
  final PrintInfoDocument? originalPrintInfo;
  final List<RefundLineSelection> refundedLines;
  final List<RefundSettlementRecord> settlements;
  final String refundId;
  final String reasonCode;
  final String reasonLabel;
  final String? operatorId;
  final String? operatorName;
  final String? processedAt;
  final int? requestedTotalMinor;
  final List<ReceiptTaxLine> taxLines;

  int get resolvedRequestedTotalMinor =>
      requestedTotalMinor ??
      refundedLines.fold<int>(
        0,
        (sum, line) => sum + line.resolvedLineTotalMinor,
      );

  @override
  List<Object?> get props => <Object?>[
    originalOrder,
    originalPrintInfo,
    refundedLines,
    settlements,
    refundId,
    reasonCode,
    reasonLabel,
    operatorId,
    operatorName,
    processedAt,
    requestedTotalMinor,
    taxLines,
  ];
}

String? _nullableString(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? 0;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
