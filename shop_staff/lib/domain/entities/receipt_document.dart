import 'package:equatable/equatable.dart';

enum ReceiptDocumentKind { sale, refund }

enum ReceiptDetailLevel { summary, itemized }

enum ReceiptOrderMode { dineIn, takeout, unknown }

enum ReceiptRefundStatus { success, partial, failed }

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

extension ReceiptDetailLevelX on ReceiptDetailLevel {
  String get wireValue {
    switch (this) {
      case ReceiptDetailLevel.summary:
        return 'summary';
      case ReceiptDetailLevel.itemized:
        return 'itemized';
    }
  }

  static ReceiptDetailLevel fromWireValue(String raw) {
    switch (raw) {
      case 'summary':
        return ReceiptDetailLevel.summary;
      case 'itemized':
      default:
        return ReceiptDetailLevel.itemized;
    }
  }
}

extension ReceiptOrderModeX on ReceiptOrderMode {
  String get wireValue {
    switch (this) {
      case ReceiptOrderMode.dineIn:
        return 'dine_in';
      case ReceiptOrderMode.takeout:
        return 'takeout';
      case ReceiptOrderMode.unknown:
        return 'unknown';
    }
  }

  static ReceiptOrderMode fromWireValue(String raw) {
    switch (raw) {
      case 'dine_in':
        return ReceiptOrderMode.dineIn;
      case 'takeout':
        return ReceiptOrderMode.takeout;
      default:
        return ReceiptOrderMode.unknown;
    }
  }
}

extension ReceiptRefundStatusX on ReceiptRefundStatus {
  String get wireValue {
    switch (this) {
      case ReceiptRefundStatus.success:
        return 'success';
      case ReceiptRefundStatus.partial:
        return 'partial';
      case ReceiptRefundStatus.failed:
        return 'failed';
    }
  }

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

class ReceiptDocument extends Equatable {
  const ReceiptDocument({
    this.schema = schemaV1,
    required this.kind,
    this.detailLevel = ReceiptDetailLevel.itemized,
    required this.shop,
    required this.transaction,
    this.originalTransaction,
    this.lines = const <ReceiptLine>[],
    required this.totals,
    this.payment,
    this.refund,
    this.extras = const <String, dynamic>{},
  });

  static const String schemaV1 = 'shop_staff.receipt.v1';

  final String schema;
  final ReceiptDocumentKind kind;
  final ReceiptDetailLevel detailLevel;
  final ReceiptShopInfo shop;
  final ReceiptTransactionInfo transaction;
  final ReceiptOriginalTransactionInfo? originalTransaction;
  final List<ReceiptLine> lines;
  final ReceiptTotals totals;
  final ReceiptPaymentInfo? payment;
  final ReceiptRefundInfo? refund;
  final Map<String, dynamic> extras;

  int get totalQuantity =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema': schema,
      'kind': kind.wireValue,
      'detailLevel': detailLevel.wireValue,
      'shop': shop.toJson(),
      'transaction': transaction.toJson(),
      if (originalTransaction != null)
        'originalTransaction': originalTransaction!.toJson(),
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
      'totals': totals.toJson(),
      if (payment != null) 'payment': payment!.toJson(),
      if (refund != null) 'refund': refund!.toJson(),
      'extras': Map<String, dynamic>.from(extras),
    };
  }

  factory ReceiptDocument.fromJson(Map<String, dynamic> json) {
    final lineList = (json['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ReceiptLine.fromJson)
        .toList(growable: false);

    return ReceiptDocument(
      schema: (json['schema'] ?? schemaV1).toString(),
      kind: ReceiptDocumentKindX.fromWireValue(
        (json['kind'] ?? 'sale').toString(),
      ),
      detailLevel: ReceiptDetailLevelX.fromWireValue(
        (json['detailLevel'] ?? 'itemized').toString(),
      ),
      shop: ReceiptShopInfo.fromJson(
        Map<String, dynamic>.from(
          json['shop'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{},
        ),
      ),
      transaction: ReceiptTransactionInfo.fromJson(
        Map<String, dynamic>.from(
          json['transaction'] as Map<dynamic, dynamic>? ??
              const <String, dynamic>{},
        ),
      ),
      originalTransaction: json['originalTransaction'] is Map
          ? ReceiptOriginalTransactionInfo.fromJson(
              Map<String, dynamic>.from(
                json['originalTransaction'] as Map<dynamic, dynamic>,
              ),
            )
          : null,
      lines: lineList,
      totals: ReceiptTotals.fromJson(
        Map<String, dynamic>.from(
          json['totals'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{},
        ),
      ),
      payment: json['payment'] is Map
          ? ReceiptPaymentInfo.fromJson(
              Map<String, dynamic>.from(
                json['payment'] as Map<dynamic, dynamic>,
              ),
            )
          : null,
      refund: json['refund'] is Map
          ? ReceiptRefundInfo.fromJson(
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

  @override
  List<Object?> get props => <Object?>[
    schema,
    kind,
    detailLevel,
    shop,
    transaction,
    originalTransaction,
    lines,
    totals,
    payment,
    refund,
    extras,
  ];
}

class ReceiptShopInfo extends Equatable {
  const ReceiptShopInfo({
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.taxRegistrationNo,
  });

  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final String? taxRegistrationNo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      if (code != null) 'code': code,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (taxRegistrationNo != null) 'taxRegistrationNo': taxRegistrationNo,
    };
  }

  factory ReceiptShopInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptShopInfo(
      name: (json['name'] ?? '').toString(),
      code: _nullableString(json['code']),
      address: _nullableString(json['address']),
      phone: _nullableString(json['phone']),
      taxRegistrationNo: _nullableString(json['taxRegistrationNo']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    name,
    code,
    address,
    phone,
    taxRegistrationNo,
  ];
}

class ReceiptTransactionInfo extends Equatable {
  const ReceiptTransactionInfo({
    required this.receiptId,
    this.orderId,
    this.displayOrderNo,
    this.serialNumber,
    this.occurredAt,
    this.businessDateLabel,
    this.orderMode = ReceiptOrderMode.unknown,
    this.machineCode,
    this.locale,
    this.currency = 'JPY',
  });

  final String receiptId;
  final String? orderId;
  final String? displayOrderNo;
  final String? serialNumber;
  final String? occurredAt;
  final String? businessDateLabel;
  final ReceiptOrderMode orderMode;
  final String? machineCode;
  final String? locale;
  final String currency;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiptId': receiptId,
      if (orderId != null) 'orderId': orderId,
      if (displayOrderNo != null) 'displayOrderNo': displayOrderNo,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (occurredAt != null) 'occurredAt': occurredAt,
      if (businessDateLabel != null) 'businessDateLabel': businessDateLabel,
      'orderMode': orderMode.wireValue,
      if (machineCode != null) 'machineCode': machineCode,
      if (locale != null) 'locale': locale,
      'currency': currency,
    };
  }

  factory ReceiptTransactionInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptTransactionInfo(
      receiptId: (json['receiptId'] ?? '').toString(),
      orderId: _nullableString(json['orderId']),
      displayOrderNo: _nullableString(json['displayOrderNo']),
      serialNumber: _nullableString(json['serialNumber']),
      occurredAt: _nullableString(json['occurredAt']),
      businessDateLabel: _nullableString(json['businessDateLabel']),
      orderMode: ReceiptOrderModeX.fromWireValue(
        (json['orderMode'] ?? 'unknown').toString(),
      ),
      machineCode: _nullableString(json['machineCode']),
      locale: _nullableString(json['locale']),
      currency: (json['currency'] ?? 'JPY').toString(),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    receiptId,
    orderId,
    displayOrderNo,
    serialNumber,
    occurredAt,
    businessDateLabel,
    orderMode,
    machineCode,
    locale,
    currency,
  ];
}

class ReceiptOriginalTransactionInfo extends Equatable {
  const ReceiptOriginalTransactionInfo({
    this.orderId,
    this.orderIdStr,
    this.serialNumber,
    this.paidAt,
  });

  final String? orderId;
  final String? orderIdStr;
  final String? serialNumber;
  final String? paidAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (orderId != null) 'orderId': orderId,
      if (orderIdStr != null) 'orderIdStr': orderIdStr,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (paidAt != null) 'paidAt': paidAt,
    };
  }

  factory ReceiptOriginalTransactionInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptOriginalTransactionInfo(
      orderId: _nullableString(json['orderId']),
      orderIdStr: _nullableString(json['orderIdStr']),
      serialNumber: _nullableString(json['serialNumber']),
      paidAt: _nullableString(json['paidAt']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    orderId,
    orderIdStr,
    serialNumber,
    paidAt,
  ];
}

class ReceiptLine extends Equatable {
  const ReceiptLine({
    this.lineId,
    required this.name,
    this.categoryName,
    required this.quantity,
    this.originalQuantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    this.options = const <ReceiptLineOption>[],
    this.note,
  });

  final String? lineId;
  final String name;
  final String? categoryName;
  final int quantity;
  final int? originalQuantity;
  final int unitPriceMinor;
  final int lineTotalMinor;
  final List<ReceiptLineOption> options;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (lineId != null) 'lineId': lineId,
      'name': name,
      if (categoryName != null) 'categoryName': categoryName,
      'quantity': quantity,
      if (originalQuantity != null) 'originalQuantity': originalQuantity,
      'unitPriceMinor': unitPriceMinor,
      'lineTotalMinor': lineTotalMinor,
      'options': options
          .map((option) => option.toJson())
          .toList(growable: false),
      if (note != null) 'note': note,
    };
  }

  factory ReceiptLine.fromJson(Map<String, dynamic> json) {
    return ReceiptLine(
      lineId: _nullableString(json['lineId']),
      name: (json['name'] ?? '').toString(),
      categoryName: _nullableString(json['categoryName']),
      quantity: _toInt(json['quantity']),
      originalQuantity: _toIntOrNull(json['originalQuantity']),
      unitPriceMinor: _toInt(json['unitPriceMinor']),
      lineTotalMinor: _toInt(json['lineTotalMinor']),
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptLineOption.fromJson)
          .toList(growable: false),
      note: _nullableString(json['note']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    lineId,
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

class ReceiptLineOption extends Equatable {
  const ReceiptLineOption({
    required this.group,
    required this.name,
    this.quantity = 1,
    this.priceDeltaMinor = 0,
  });

  final String group;
  final String name;
  final int quantity;
  final int priceDeltaMinor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'group': group,
      'name': name,
      'quantity': quantity,
      'priceDeltaMinor': priceDeltaMinor,
    };
  }

  factory ReceiptLineOption.fromJson(Map<String, dynamic> json) {
    return ReceiptLineOption(
      group: (json['group'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: _toInt(json['quantity'], fallback: 1),
      priceDeltaMinor: _toInt(json['priceDeltaMinor']),
    );
  }

  @override
  List<Object?> get props => <Object?>[group, name, quantity, priceDeltaMinor];
}

class ReceiptTotals extends Equatable {
  const ReceiptTotals({
    required this.subtotalMinor,
    this.discountMinor = 0,
    this.taxLines = const <ReceiptTaxLine>[],
    required this.grandTotalMinor,
    this.paidMinor,
    this.changeMinor,
  });

  final int subtotalMinor;
  final int discountMinor;
  final List<ReceiptTaxLine> taxLines;
  final int grandTotalMinor;
  final int? paidMinor;
  final int? changeMinor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subtotalMinor': subtotalMinor,
      'discountMinor': discountMinor,
      'taxLines': taxLines.map((line) => line.toJson()).toList(growable: false),
      'grandTotalMinor': grandTotalMinor,
      if (paidMinor != null) 'paidMinor': paidMinor,
      if (changeMinor != null) 'changeMinor': changeMinor,
    };
  }

  factory ReceiptTotals.fromJson(Map<String, dynamic> json) {
    return ReceiptTotals(
      subtotalMinor: _toInt(json['subtotalMinor']),
      discountMinor: _toInt(json['discountMinor']),
      taxLines: (json['taxLines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptTaxLine.fromJson)
          .toList(growable: false),
      grandTotalMinor: _toInt(json['grandTotalMinor']),
      paidMinor: _toIntOrNull(json['paidMinor']),
      changeMinor: _toIntOrNull(json['changeMinor']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    subtotalMinor,
    discountMinor,
    taxLines,
    grandTotalMinor,
    paidMinor,
    changeMinor,
  ];
}

class ReceiptTaxLine extends Equatable {
  const ReceiptTaxLine({
    required this.label,
    required this.baseMinor,
    required this.taxMinor,
  });

  final String label;
  final int baseMinor;
  final int taxMinor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'baseMinor': baseMinor,
      'taxMinor': taxMinor,
    };
  }

  factory ReceiptTaxLine.fromJson(Map<String, dynamic> json) {
    return ReceiptTaxLine(
      label: (json['label'] ?? '').toString(),
      baseMinor: _toInt(json['baseMinor']),
      taxMinor: _toInt(json['taxMinor']),
    );
  }

  @override
  List<Object?> get props => <Object?>[label, baseMinor, taxMinor];
}

class ReceiptPaymentInfo extends Equatable {
  const ReceiptPaymentInfo({
    required this.methodCode,
    required this.methodLabel,
    this.memberNo,
  });

  final String methodCode;
  final String methodLabel;
  final String? memberNo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'methodCode': methodCode,
      'methodLabel': methodLabel,
      if (memberNo != null) 'memberNo': memberNo,
    };
  }

  factory ReceiptPaymentInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptPaymentInfo(
      methodCode: (json['methodCode'] ?? '').toString(),
      methodLabel: (json['methodLabel'] ?? '').toString(),
      memberNo: _nullableString(json['memberNo']),
    );
  }

  @override
  List<Object?> get props => <Object?>[methodCode, methodLabel, memberNo];
}

class ReceiptRefundInfo extends Equatable {
  const ReceiptRefundInfo({
    required this.refundId,
    required this.reasonCode,
    required this.reasonLabel,
    this.operatorId,
    this.operatorName,
    required this.requestedTotalMinor,
    required this.approvedTotalMinor,
    required this.status,
    this.settlements = const <ReceiptRefundSettlement>[],
    this.processedAt,
  });

  final String refundId;
  final String reasonCode;
  final String reasonLabel;
  final String? operatorId;
  final String? operatorName;
  final int requestedTotalMinor;
  final int approvedTotalMinor;
  final ReceiptRefundStatus status;
  final List<ReceiptRefundSettlement> settlements;
  final String? processedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'refundId': refundId,
      'reasonCode': reasonCode,
      'reasonLabel': reasonLabel,
      if (operatorId != null) 'operatorId': operatorId,
      if (operatorName != null) 'operatorName': operatorName,
      'requestedTotalMinor': requestedTotalMinor,
      'approvedTotalMinor': approvedTotalMinor,
      'status': status.wireValue,
      'settlements': settlements
          .map((settlement) => settlement.toJson())
          .toList(growable: false),
      if (processedAt != null) 'processedAt': processedAt,
    };
  }

  factory ReceiptRefundInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptRefundInfo(
      refundId: (json['refundId'] ?? '').toString(),
      reasonCode: (json['reasonCode'] ?? '').toString(),
      reasonLabel: (json['reasonLabel'] ?? '').toString(),
      operatorId: _nullableString(json['operatorId']),
      operatorName: _nullableString(json['operatorName']),
      requestedTotalMinor: _toInt(json['requestedTotalMinor']),
      approvedTotalMinor: _toInt(json['approvedTotalMinor']),
      status: ReceiptRefundStatusX.fromWireValue(
        (json['status'] ?? 'failed').toString(),
      ),
      settlements: (json['settlements'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ReceiptRefundSettlement.fromJson)
          .toList(growable: false),
      processedAt: _nullableString(json['processedAt']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    refundId,
    reasonCode,
    reasonLabel,
    operatorId,
    operatorName,
    requestedTotalMinor,
    approvedTotalMinor,
    status,
    settlements,
    processedAt,
  ];
}

class ReceiptRefundSettlement extends Equatable {
  const ReceiptRefundSettlement({
    required this.channel,
    required this.amountMinor,
    required this.payAmountMinor,
    this.changeMinor = 0,
    this.couponMinor = 0,
    this.couponType,
    required this.executeMark,
    this.gateway,
  });

  final String channel;
  final int amountMinor;
  final int payAmountMinor;
  final int changeMinor;
  final int couponMinor;
  final int? couponType;
  final bool executeMark;
  final ReceiptGatewayTrace? gateway;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'channel': channel,
      'amountMinor': amountMinor,
      'payAmountMinor': payAmountMinor,
      'changeMinor': changeMinor,
      'couponMinor': couponMinor,
      if (couponType != null) 'couponType': couponType,
      'executeMark': executeMark,
      if (gateway != null) 'gateway': gateway!.toJson(),
    };
  }

  factory ReceiptRefundSettlement.fromJson(Map<String, dynamic> json) {
    return ReceiptRefundSettlement(
      channel: (json['channel'] ?? '').toString(),
      amountMinor: _toInt(json['amountMinor']),
      payAmountMinor: _toInt(json['payAmountMinor']),
      changeMinor: _toInt(json['changeMinor']),
      couponMinor: _toInt(json['couponMinor']),
      couponType: _toIntOrNull(json['couponType']),
      executeMark: json['executeMark'] == true,
      gateway: json['gateway'] is Map
          ? ReceiptGatewayTrace.fromJson(
              Map<String, dynamic>.from(
                json['gateway'] as Map<dynamic, dynamic>,
              ),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    channel,
    amountMinor,
    payAmountMinor,
    changeMinor,
    couponMinor,
    couponType,
    executeMark,
    gateway,
  ];
}

class ReceiptGatewayTrace extends Equatable {
  const ReceiptGatewayTrace({this.requestMessage, this.responseMessage});

  final String? requestMessage;
  final String? responseMessage;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (requestMessage != null) 'requestMessage': requestMessage,
      if (responseMessage != null) 'responseMessage': responseMessage,
    };
  }

  factory ReceiptGatewayTrace.fromJson(Map<String, dynamic> json) {
    return ReceiptGatewayTrace(
      requestMessage: _nullableString(json['requestMessage']),
      responseMessage: _nullableString(json['responseMessage']),
    );
  }

  @override
  List<Object?> get props => <Object?>[requestMessage, responseMessage];
}

String? _nullableString(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? fallback;
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
