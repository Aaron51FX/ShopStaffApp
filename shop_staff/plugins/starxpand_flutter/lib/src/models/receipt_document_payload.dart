class ReceiptDocumentPayload {
  ReceiptDocumentPayload({
    required this.schema,
    required this.kind,
    required this.shop,
    required this.transaction,
    this.originalTransaction,
    this.lines = const <ReceiptLinePayload>[],
    required this.totals,
    this.payment,
    this.refund,
    this.extras = const <String, dynamic>{},
  });

  factory ReceiptDocumentPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptDocumentPayload(
      schema: (json['schema'] ?? '').toString(),
      kind: ReceiptDocumentKindX.fromWireValue(
        (json['kind'] ?? 'sale').toString(),
      ),
      shop: ReceiptShopPayload.fromJson(
        Map<String, dynamic>.from(
          json['shop'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{},
        ),
      ),
      transaction: ReceiptTransactionPayload.fromJson(
        Map<String, dynamic>.from(
          json['transaction'] as Map<dynamic, dynamic>? ??
              const <String, dynamic>{},
        ),
      ),
      originalTransaction: json['originalTransaction'] is Map
          ? ReceiptOriginalTransactionPayload.fromJson(
              Map<String, dynamic>.from(
                json['originalTransaction'] as Map<dynamic, dynamic>,
              ),
            )
          : null,
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptLinePayload.fromJson)
          .toList(growable: false),
      totals: ReceiptTotalsPayload.fromJson(
        Map<String, dynamic>.from(
          json['totals'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{},
        ),
      ),
      payment: json['payment'] is Map
          ? ReceiptPaymentPayload.fromJson(
              Map<String, dynamic>.from(
                json['payment'] as Map<dynamic, dynamic>,
              ),
            )
          : null,
      refund: json['refund'] is Map
          ? ReceiptRefundPayload.fromJson(
              Map<String, dynamic>.from(
                json['refund'] as Map<dynamic, dynamic>,
              ),
            )
          : null,
      extras: Map<String, dynamic>.from(
        json['extras'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  final String schema;
  final ReceiptDocumentKind kind;
  final ReceiptShopPayload shop;
  final ReceiptTransactionPayload transaction;
  final ReceiptOriginalTransactionPayload? originalTransaction;
  final List<ReceiptLinePayload> lines;
  final ReceiptTotalsPayload totals;
  final ReceiptPaymentPayload? payment;
  final ReceiptRefundPayload? refund;
  final Map<String, dynamic> extras;
}

enum ReceiptDocumentKind { sale, refund }

extension ReceiptDocumentKindX on ReceiptDocumentKind {
  String get wireValue {
    switch (this) {
      case ReceiptDocumentKind.sale:
        return 'sale';
      case ReceiptDocumentKind.refund:
        return 'refund';
    }
  }

  static ReceiptDocumentKind fromWireValue(String raw) {
    switch (raw) {
      case 'refund':
        return ReceiptDocumentKind.refund;
      case 'sale':
      default:
        return ReceiptDocumentKind.sale;
    }
  }
}

enum ReceiptRefundStatus { success, partial, failed }

extension ReceiptRefundStatusX on ReceiptRefundStatus {
  static ReceiptRefundStatus fromWireValue(String raw) {
    switch (raw) {
      case 'success':
        return ReceiptRefundStatus.success;
      case 'partial':
        return ReceiptRefundStatus.partial;
      case 'failed':
      default:
        return ReceiptRefundStatus.failed;
    }
  }
}

class ReceiptShopPayload {
  ReceiptShopPayload({
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.taxRegistrationNo,
  });

  factory ReceiptShopPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptShopPayload(
      name: (json['name'] ?? '').toString(),
      code: _nullableString(json['code']),
      address: _nullableString(json['address']),
      phone: _nullableString(json['phone']),
      taxRegistrationNo: _nullableString(json['taxRegistrationNo']),
    );
  }

  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final String? taxRegistrationNo;
}

class ReceiptTransactionPayload {
  ReceiptTransactionPayload({
    required this.receiptId,
    this.orderId,
    this.displayOrderNo,
    this.serialNumber,
    this.occurredAt,
    this.businessDateLabel,
    this.machineCode,
    this.locale = 'ja-JP',
    this.currency = 'JPY',
  });

  factory ReceiptTransactionPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptTransactionPayload(
      receiptId: (json['receiptId'] ?? '').toString(),
      orderId: _nullableString(json['orderId']),
      displayOrderNo: _nullableString(json['displayOrderNo']),
      serialNumber: _nullableString(json['serialNumber']),
      occurredAt: _nullableString(json['occurredAt']),
      businessDateLabel: _nullableString(json['businessDateLabel']),
      machineCode: _nullableString(json['machineCode']),
      locale: _nullableString(json['locale']) ?? 'ja-JP',
      currency: _nullableString(json['currency']) ?? 'JPY',
    );
  }

  final String receiptId;
  final String? orderId;
  final String? displayOrderNo;
  final String? serialNumber;
  final String? occurredAt;
  final String? businessDateLabel;
  final String? machineCode;
  final String locale;
  final String currency;
}

class ReceiptOriginalTransactionPayload {
  ReceiptOriginalTransactionPayload({
    this.orderId,
    this.orderIdStr,
    this.serialNumber,
    this.paidAt,
  });

  factory ReceiptOriginalTransactionPayload.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReceiptOriginalTransactionPayload(
      orderId: _nullableString(json['orderId']),
      orderIdStr: _nullableString(json['orderIdStr']),
      serialNumber: _nullableString(json['serialNumber']),
      paidAt: _nullableString(json['paidAt']),
    );
  }

  final String? orderId;
  final String? orderIdStr;
  final String? serialNumber;
  final String? paidAt;
}

class ReceiptLinePayload {
  ReceiptLinePayload({
    this.lineId,
    required this.name,
    this.categoryName,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    this.options = const <ReceiptLineOptionPayload>[],
    this.note,
  });

  factory ReceiptLinePayload.fromJson(Map<String, dynamic> json) {
    return ReceiptLinePayload(
      lineId: _nullableString(json['lineId']),
      name: (json['name'] ?? '').toString(),
      categoryName: _nullableString(json['categoryName']),
      quantity: _toInt(json['quantity'], fallback: 1),
      unitPriceMinor: _toInt(json['unitPriceMinor']),
      lineTotalMinor: _toInt(json['lineTotalMinor']),
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptLineOptionPayload.fromJson)
          .toList(growable: false),
      note: _nullableString(json['note']),
    );
  }

  final String? lineId;
  final String name;
  final String? categoryName;
  final int quantity;
  final int unitPriceMinor;
  final int lineTotalMinor;
  final List<ReceiptLineOptionPayload> options;
  final String? note;
}

class ReceiptLineOptionPayload {
  ReceiptLineOptionPayload({
    required this.group,
    required this.name,
    this.quantity = 1,
    this.priceDeltaMinor = 0,
  });

  factory ReceiptLineOptionPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptLineOptionPayload(
      group: (json['group'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: _toInt(json['quantity'], fallback: 1),
      priceDeltaMinor: _toInt(json['priceDeltaMinor']),
    );
  }

  final String group;
  final String name;
  final int quantity;
  final int priceDeltaMinor;
}

class ReceiptTotalsPayload {
  ReceiptTotalsPayload({
    required this.subtotalMinor,
    this.discountMinor = 0,
    this.taxLines = const <ReceiptTaxLinePayload>[],
    required this.grandTotalMinor,
    this.paidMinor,
    this.changeMinor,
  });

  factory ReceiptTotalsPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptTotalsPayload(
      subtotalMinor: _toInt(json['subtotalMinor']),
      discountMinor: _toInt(json['discountMinor']),
      taxLines: (json['taxLines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptTaxLinePayload.fromJson)
          .toList(growable: false),
      grandTotalMinor: _toInt(json['grandTotalMinor']),
      paidMinor: _toIntOrNull(json['paidMinor']),
      changeMinor: _toIntOrNull(json['changeMinor']),
    );
  }

  final int subtotalMinor;
  final int discountMinor;
  final List<ReceiptTaxLinePayload> taxLines;
  final int grandTotalMinor;
  final int? paidMinor;
  final int? changeMinor;
}

class ReceiptTaxLinePayload {
  ReceiptTaxLinePayload({
    required this.label,
    required this.baseMinor,
    required this.taxMinor,
  });

  factory ReceiptTaxLinePayload.fromJson(Map<String, dynamic> json) {
    return ReceiptTaxLinePayload(
      label: (json['label'] ?? '').toString(),
      baseMinor: _toInt(json['baseMinor']),
      taxMinor: _toInt(json['taxMinor']),
    );
  }

  final String label;
  final int baseMinor;
  final int taxMinor;
}

class ReceiptPaymentPayload {
  ReceiptPaymentPayload({
    required this.methodCode,
    required this.methodLabel,
    this.memberNo,
  });

  factory ReceiptPaymentPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptPaymentPayload(
      methodCode: (json['methodCode'] ?? '').toString(),
      methodLabel: (json['methodLabel'] ?? '').toString(),
      memberNo: _nullableString(json['memberNo']),
    );
  }

  final String methodCode;
  final String methodLabel;
  final String? memberNo;
}

class ReceiptRefundPayload {
  ReceiptRefundPayload({
    required this.refundId,
    required this.reasonCode,
    required this.reasonLabel,
    this.operatorId,
    this.operatorName,
    required this.requestedTotalMinor,
    this.approvedTotalMinor,
    required this.status,
    this.settlements = const <ReceiptRefundSettlementPayload>[],
    this.processedAt,
  });

  factory ReceiptRefundPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptRefundPayload(
      refundId: (json['refundId'] ?? '').toString(),
      reasonCode: (json['reasonCode'] ?? '').toString(),
      reasonLabel: (json['reasonLabel'] ?? '').toString(),
      operatorId: _nullableString(json['operatorId']),
      operatorName: _nullableString(json['operatorName']),
      requestedTotalMinor: _toInt(json['requestedTotalMinor']),
      approvedTotalMinor: _toIntOrNull(json['approvedTotalMinor']),
      status: ReceiptRefundStatusX.fromWireValue(
        (json['status'] ?? 'failed').toString(),
      ),
      settlements: (json['settlements'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptRefundSettlementPayload.fromJson)
          .toList(growable: false),
      processedAt: _nullableString(json['processedAt']),
    );
  }

  final String refundId;
  final String reasonCode;
  final String reasonLabel;
  final String? operatorId;
  final String? operatorName;
  final int requestedTotalMinor;
  final int? approvedTotalMinor;
  final ReceiptRefundStatus status;
  final List<ReceiptRefundSettlementPayload> settlements;
  final String? processedAt;
}

class ReceiptRefundSettlementPayload {
  ReceiptRefundSettlementPayload({
    required this.channel,
    required this.amountMinor,
    required this.payAmountMinor,
    required this.executeMark,
  });

  factory ReceiptRefundSettlementPayload.fromJson(Map<String, dynamic> json) {
    return ReceiptRefundSettlementPayload(
      channel: (json['channel'] ?? 'unknown').toString(),
      amountMinor: _toInt(json['amountMinor']),
      payAmountMinor: _toInt(json['payAmountMinor']),
      executeMark: json['executeMark'] == true,
    );
  }

  final String channel;
  final int amountMinor;
  final int payAmountMinor;
  final bool executeMark;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final raw = value.toString();
  return raw.isEmpty ? null : raw;
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _toIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
