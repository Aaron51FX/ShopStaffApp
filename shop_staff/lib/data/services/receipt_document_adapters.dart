import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/receipt_document.dart';
import 'package:shop_staff/domain/entities/refund_receipt_source.dart';

class SaleReceiptDocumentAdapter {
  const SaleReceiptDocumentAdapter._();

  static ReceiptDocument fromPrintInfo(
    PrintInfoDocument document, {
    LocalOrderRecord? localOrder,
    String currency = 'JPY',
    String? locale,
  }) {
    final lines = _resolveSaleLines(document, localOrder: localOrder);
    final subtotal = document.originalPrice > 0
        ? document.originalPrice
        : _sumLineTotals(lines);
    final grandTotal = document.price > 0
        ? document.price
        : subtotal - document.discount;

    return ReceiptDocument(
      kind: ReceiptDocumentKind.sale,
      detailLevel: lines.isEmpty
          ? ReceiptDetailLevel.summary
          : ReceiptDetailLevel.itemized,
      shop: ReceiptShopInfo(
        name: document.shopName,
        code: _nullIfEmpty(document.shopCode),
        address: _nullIfEmpty(_normalizeAddress(document.address)),
        phone: _nullIfEmpty(document.telNo),
        taxRegistrationNo: _nullIfEmpty(document.ntaNo),
      ),
      transaction: ReceiptTransactionInfo(
        receiptId: 'sale-${document.orderId}',
        orderId: _nullIfEmpty(document.order),
        displayOrderNo: _firstNonEmpty(<String?>[
          document.serialNumberText,
          document.serialNumber,
          document.serialNo,
        ]),
        serialNumber: _firstNonEmpty(<String?>[
          document.serialNumberText,
          document.serialNumber,
          document.serialNo,
        ]),
        occurredAt: _firstNonEmpty(<String?>[
          document.payDate,
          document.orderDate,
        ]),
        businessDateLabel: _firstNonEmpty(<String?>[
          document.orderDate,
          document.orderTime,
        ]),
        orderMode: _saleOrderMode(document),
        machineCode: localOrder?.machineCode,
        locale: locale ?? _localeFromShopStaffLanguage(document.language),
        currency: currency,
      ),
      lines: lines,
      totals: ReceiptTotals(
        subtotalMinor: subtotal,
        discountMinor: document.discount,
        taxLines: _saleTaxLines(document),
        grandTotalMinor: grandTotal,
        paidMinor: document.payPrice > 0 ? document.payPrice : null,
        changeMinor: document.change,
      ),
      payment: ReceiptPaymentInfo(
        methodCode: _paymentMethodCode(document.payMethod),
        methodLabel: document.payMethod.isEmpty ? '未設定' : document.payMethod,
        memberNo: _nullIfEmpty(document.memberNo),
      ),
      extras: <String, dynamic>{
        if (document.numberTip.isNotEmpty) 'numberTip': document.numberTip,
        'takeOut': document.takeOut,
        if ((document.printInfo?.paymentCode ?? '').isNotEmpty)
          'qrPaymentCode': document.printInfo!.paymentCode,
        if (document.details != null) 'details': document.details,
      },
    );
  }
}

class RefundReceiptDocumentAdapter {
  const RefundReceiptDocumentAdapter._();

  static ReceiptDocument fromSource(
    RefundReceiptSource source, {
    String currency = 'JPY',
    String? locale,
  }) {
    final lines = source.refundedLines
        .map((line) => line.toReceiptLine())
        .toList(growable: false);
    final requestedTotal = source.resolvedRequestedTotalMinor;
    final approvedTotal = _approvedRefundTotalMinor(source.settlements);
    final saleDoc = source.originalPrintInfo;
    final firstSettlement = source.settlements.isNotEmpty
        ? source.settlements.first
        : null;
    final businessDateLabel = _firstNonEmpty(<String?>[
      source.processedAt,
      firstSettlement?.payTime,
    ]);

    return ReceiptDocument(
      kind: ReceiptDocumentKind.refund,
      detailLevel: lines.isEmpty
          ? ReceiptDetailLevel.summary
          : ReceiptDetailLevel.itemized,
      shop: ReceiptShopInfo(
        name:
            _firstNonEmpty(<String?>[
              saleDoc?.shopName,
              firstSettlement?.shopName,
            ]) ??
            '',
        code: _nullIfEmpty(saleDoc?.shopCode),
        address: _firstNonEmpty(<String?>[
          saleDoc != null ? _normalizeAddress(saleDoc.address) : null,
          firstSettlement?.address,
        ]),
        phone: _firstNonEmpty(<String?>[
          saleDoc?.telNo,
          firstSettlement?.telNo,
        ]),
        taxRegistrationNo: _nullIfEmpty(saleDoc?.ntaNo),
      ),
      transaction: ReceiptTransactionInfo(
        receiptId: source.refundId,
        orderId: source.originalOrder.orderId,
        displayOrderNo: _firstNonEmpty(<String?>[
          firstSettlement?.serialNumber,
          saleDoc?.serialNumberText,
          saleDoc?.serialNumber,
        ]),
        serialNumber: _firstNonEmpty(<String?>[
          firstSettlement?.serialNumber,
          saleDoc?.serialNumberText,
          saleDoc?.serialNumber,
        ]),
        occurredAt: businessDateLabel,
        businessDateLabel: businessDateLabel,
        orderMode: source.originalOrder.takeout
            ? ReceiptOrderMode.takeout
            : ReceiptOrderMode.dineIn,
        machineCode: _firstNonEmpty(<String?>[
          firstSettlement?.machineCode,
          source.originalOrder.machineCode,
        ]),
        locale:
            locale ??
            _localeFromShopStaffLanguage(source.originalOrder.language),
        currency: currency,
      ),
      originalTransaction: ReceiptOriginalTransactionInfo(
        orderId:
            _stringOrNull(firstSettlement?.orderId) ??
            source.originalOrder.orderId,
        orderIdStr: _firstNonEmpty(<String?>[
          firstSettlement?.orderIdStr,
          source.originalOrder.orderId,
        ]),
        serialNumber: _firstNonEmpty(<String?>[
          firstSettlement?.serialNumber,
          saleDoc?.serialNumberText,
          saleDoc?.serialNumber,
        ]),
        paidAt: _firstNonEmpty(<String?>[
          firstSettlement?.payTime,
          saleDoc?.payDate,
          saleDoc?.orderDate,
        ]),
      ),
      lines: lines,
      totals: ReceiptTotals(
        subtotalMinor: requestedTotal,
        discountMinor: 0,
        taxLines: _refundTaxLines(source),
        grandTotalMinor: requestedTotal,
        paidMinor: approvedTotal > 0 ? approvedTotal : null,
        changeMinor: _sumExecutedChangeMinor(source.settlements),
      ),
      payment: ReceiptPaymentInfo(
        methodCode: _paymentMethodCode(source.originalOrder.payMethod),
        methodLabel: source.originalOrder.payMethod.isEmpty
            ? '退款'
            : source.originalOrder.payMethod,
      ),
      refund: ReceiptRefundInfo(
        refundId: source.refundId,
        reasonCode: source.reasonCode,
        reasonLabel: source.reasonLabel,
        operatorId: _nullIfEmpty(source.operatorId),
        operatorName: _nullIfEmpty(source.operatorName),
        requestedTotalMinor: requestedTotal,
        approvedTotalMinor: approvedTotal,
        status: _refundStatus(source.settlements),
        settlements: source.settlements
            .map(
              (record) => ReceiptRefundSettlement(
                channel: record.payChannel ?? 'unknown',
                amountMinor: record.amountMinor,
                payAmountMinor: record.payAmountMinor,
                changeMinor: record.changeMinor,
                couponMinor: record.couponMinor,
                couponType: record.couponType,
                executeMark: record.executeMark,
                gateway: ReceiptGatewayTrace(
                  requestMessage: record.requestMessage,
                  responseMessage: record.responseMessage,
                ),
              ),
            )
            .toList(growable: false),
        processedAt: businessDateLabel,
      ),
      extras: <String, dynamic>{
        if (source.originalOrder.abnormalExit) 'abnormalExit': true,
        if ((source.originalOrder.abnormalReason ?? '').isNotEmpty)
          'abnormalReason': source.originalOrder.abnormalReason,
      },
    );
  }
}

List<ReceiptLine> _resolveSaleLines(
  PrintInfoDocument document, {
  LocalOrderRecord? localOrder,
}) {
  final info = document.printInfo;
  final source = <PrintOrderLine>[
    ...(info?.orderLines ?? const <PrintOrderLine>[]),
    if ((info?.orderLines ?? const <PrintOrderLine>[]).isEmpty)
      ...(info?.orderLinesMap.values.expand((lines) => lines) ??
          const Iterable<PrintOrderLine>.empty()),
  ];

  if (source.isNotEmpty) {
    return source
        .map(
          (line) => ReceiptLine(
            lineId: line.bizId > 0 ? line.bizId.toString() : null,
            name: line.name,
            categoryName: _nullIfEmpty(line.categoryName),
            quantity: line.qty <= 0 ? 1 : line.qty,
            unitPriceMinor: line.price,
            lineTotalMinor: _lineTotalMinorFromPrintLine(line),
            options: line.options.entries
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
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  if (localOrder != null) {
    return localOrder.items
        .map(
          (item) => ReceiptLine(
            lineId: item.id,
            name: item.product.name,
            quantity: item.quantity <= 0 ? 1 : item.quantity,
            unitPriceMinor: item.product.price.round(),
            lineTotalMinor: item.lineTotal.round(),
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
          ),
        )
        .toList(growable: false);
  }

  return const <ReceiptLine>[];
}

int _lineTotalMinorFromPrintLine(PrintOrderLine line) {
  final qty = line.qty <= 0 ? 1 : line.qty;
  final optionDeltaPerUnit = line.options.values
      .expand((options) => options)
      .fold<int>(
        0,
        (sum, option) =>
            sum + (option.price ?? 0) * (option.qty <= 0 ? 1 : option.qty),
      );
  return (line.price + optionDeltaPerUnit) * qty;
}

ReceiptOrderMode _saleOrderMode(PrintInfoDocument document) {
  if (document.takeOut) {
    return ReceiptOrderMode.takeout;
  }
  final raw = document.printInfo?.orderType ?? '';
  if (raw == 'Shop_In') {
    return ReceiptOrderMode.dineIn;
  }
  if (raw.isNotEmpty) {
    return ReceiptOrderMode.takeout;
  }
  return ReceiptOrderMode.unknown;
}

List<ReceiptTaxLine> _saleTaxLines(PrintInfoDocument document) {
  final lines = <ReceiptTaxLine>[];
  if (document.baseTax1 > 0 || document.tax1 > 0) {
    lines.add(
      ReceiptTaxLine(
        label: '10%',
        baseMinor: document.baseTax1,
        taxMinor: document.tax1,
      ),
    );
  }
  if (document.baseTax2 > 0 || document.tax2 > 0) {
    lines.add(
      ReceiptTaxLine(
        label: '8%',
        baseMinor: document.baseTax2,
        taxMinor: document.tax2,
      ),
    );
  }
  return lines;
}

List<ReceiptTaxLine> _refundTaxLines(RefundReceiptSource source) {
  if (source.taxLines.isNotEmpty) {
    return source.taxLines;
  }

  final original = source.originalPrintInfo;
  if (original == null) {
    return const <ReceiptTaxLine>[];
  }

  final originalTotal = original.price > 0
      ? original.price
      : original.originalPrice;
  if (originalTotal <= 0) {
    return const <ReceiptTaxLine>[];
  }

  if (source.resolvedRequestedTotalMinor != originalTotal) {
    return const <ReceiptTaxLine>[];
  }

  return _saleTaxLines(original);
}

ReceiptRefundStatus _refundStatus(List<RefundSettlementRecord> settlements) {
  if (settlements.isEmpty) {
    return ReceiptRefundStatus.failed;
  }

  final successCount = settlements.where((record) => record.executeMark).length;
  if (successCount == settlements.length) {
    return ReceiptRefundStatus.success;
  }
  if (successCount > 0) {
    return ReceiptRefundStatus.partial;
  }
  return ReceiptRefundStatus.failed;
}

int _approvedRefundTotalMinor(List<RefundSettlementRecord> settlements) {
  return settlements.where((record) => record.executeMark).fold<int>(0, (
    sum,
    record,
  ) {
    final value = record.payAmountMinor > 0
        ? record.payAmountMinor
        : record.amountMinor;
    return sum + value;
  });
}

int? _sumExecutedChangeMinor(List<RefundSettlementRecord> settlements) {
  final executed = settlements.where((record) => record.executeMark).toList();
  if (executed.isEmpty) {
    return null;
  }
  return executed.fold<int>(0, (sum, record) => sum + record.changeMinor);
}

int _sumLineTotals(List<ReceiptLine> lines) {
  return lines.fold<int>(0, (sum, line) => sum + line.lineTotalMinor);
}

String _paymentMethodCode(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.contains('cash') || raw.contains('現金')) {
    return 'cash';
  }
  if (normalized.contains('card') || raw.contains('カード')) {
    return 'card';
  }
  if (normalized.contains('qr') || raw.contains('qr')) {
    return 'qr';
  }
  if (normalized.isEmpty) {
    return 'unknown';
  }
  return normalized.replaceAll(RegExp(r'\s+'), '_');
}

String _localeFromShopStaffLanguage(String raw) {
  switch (raw.toUpperCase()) {
    case 'JP':
    case 'JA':
      return 'ja-JP';
    case 'ZH':
    case 'CN':
      return 'zh-CN';
    case 'EN':
      return 'en-US';
    default:
      return raw.isEmpty ? 'ja-JP' : raw;
  }
}

String _normalizeAddress(String raw) {
  return raw.replaceAll('%%', '\n').trim();
}

String? _nullIfEmpty(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _stringOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  final raw = value.toString();
  return raw.isEmpty ? null : raw;
}
