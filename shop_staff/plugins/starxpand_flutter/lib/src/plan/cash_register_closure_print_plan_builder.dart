import '../models/receipt_document_payload.dart';
import 'receipt_print_plan.dart';

class CashRegisterClosurePrintPlanBuilder {
  const CashRegisterClosurePrintPlanBuilder._();

  static ReceiptPrintPlanDocument? tryBuild(
    ReceiptDocumentPayload document, {
    required int paperWidthMm,
    required bool includeCut,
  }) {
    final summary = _cashRegisterClosureSummaryFromExtras(document.extras);
    if (summary == null) {
      return null;
    }

    return _buildCashRegisterClosurePlan(
      document: document,
      summary: summary,
      labels: _closureLabelsForLocale(document.transaction.locale),
      paperWidthMm: paperWidthMm,
      includeCut: includeCut,
    );
  }
}

ReceiptPrintPlanDocument _buildCashRegisterClosurePlan({
  required ReceiptDocumentPayload document,
  required _CashRegisterClosurePrintSummary summary,
  required _ClosureLabels labels,
  required int paperWidthMm,
  required bool includeCut,
}) {
  final nodes = <ReceiptPrintPlanNode>[];
  final shopName = summary.shopName.isNotEmpty
      ? summary.shopName
      : document.shop.name;

  nodes.add(
    ReceiptPrintPlanNode.text(
      shopName,
      align: ReceiptPrintPlanAlign.center,
      bold: true,
      widthScale: 2,
      heightScale: 2,
    ),
  );
  nodes.add(ReceiptPrintPlanNode.spacer());
  _addKeyValue(nodes, labels.machineCode, _fallback(summary.machineCode));
  _addKeyValue(nodes, labels.printTime, _fallback(summary.printTime));
  _addKeyValue(nodes, labels.staff, _fallback(summary.verifyUserName));
  nodes.add(
    ReceiptPrintPlanNode.text(
      labels.period(summary.startTime, summary.endTime),
      align: ReceiptPrintPlanAlign.center,
    ),
  );

  nodes.add(ReceiptPrintPlanNode.divider());
  nodes.add(
    ReceiptPrintPlanNode.text(
      labels.settlementInfo,
      align: ReceiptPrintPlanAlign.center,
      bold: true,
    ),
  );

  _addClosureAmountRow(nodes, labels.sales, summary.total);
  _addClosureAmountRow(nodes, labels.taxExcluded, summary.noTaxTotal);
  _addClosureAmountRow(nodes, labels.tax, summary.taxTotal);
  _addClosureAmountRow(nodes, labels.tax8Target, summary.taxTotalB, indent: 2);
  _addClosureAmountRow(nodes, labels.tax10Target, summary.taxTotalA, indent: 2);
  if (summary.discountTotal > 0) {
    _addClosureAmountRow(nodes, labels.discount, summary.discountTotal);
  }
  _addClosureNumberRow(nodes, labels.orderCount, summary.qty);
  if (summary.repaymentTotal > 0) {
    _addClosureAmountRow(nodes, labels.refundAmount, summary.repaymentTotal);
  }
  _addClosureNumberRow(nodes, labels.refundCount, summary.repaymentQty);

  nodes.add(ReceiptPrintPlanNode.divider());
  _addClosureAmountRow(nodes, labels.cash, summary.cashTotal);
  if (summary.voucherAmountTotal > 0) {
    _addClosureAmountRow(nodes, labels.voucher, summary.voucherAmountTotal);
  }
  _addClosureAmountRow(nodes, labels.creditCard, summary.creditCardTotal);
  _addClosureAmountRow(nodes, 'PayPay', summary.payPayTotal);
  _addClosureAmountRow(nodes, 'AliPay', summary.aliPayTotal);
  _addClosureAmountRow(nodes, 'WeChatPay', summary.wechatTotal);
  _addClosureAmountRow(nodes, 'r_Pay', summary.rPayTotal);
  _addClosureAmountRow(nodes, 'au_Pay', summary.auPayTotal);
  _addClosureAmountRow(nodes, 'd_Pay', summary.dPayTotal);
  _addClosureAmountRow(nodes, 'm_Pay', summary.mPayTotal);
  if (summary.trafficTotal > 0) {
    _addClosureAmountRow(nodes, labels.traffic, summary.trafficTotal);
  }

  if (includeCut) {
    nodes.add(ReceiptPrintPlanNode.spacer());
    nodes.add(ReceiptPrintPlanNode.cut());
  }

  return ReceiptPrintPlanDocument(
    kind: document.kind,
    paperWidthMm: paperWidthMm,
    nodes: nodes,
    extras: <String, dynamic>{
      'sourceSchema': document.schema,
      'documentType': 'cash_register_closure',
      if (_hasValue(document.transaction.receiptId))
        'receiptId': document.transaction.receiptId,
    },
  );
}

void _addClosureAmountRow(
  List<ReceiptPrintPlanNode> nodes,
  String label,
  int value, {
  int indent = 0,
}) {
  _addTitleValueRow(
    nodes,
    '${''.padLeft(indent)}$label',
    _formatClosureMoney(value),
  );
}

void _addClosureNumberRow(
  List<ReceiptPrintPlanNode> nodes,
  String label,
  int value,
) {
  _addTitleValueRow(nodes, label, _formatNumber(value));
}

void _addKeyValue(
  List<ReceiptPrintPlanNode> nodes,
  String label,
  String value,
) {
  _addTitleValueRow(nodes, label, value, titleBold: true);
}

void _addTitleValueRow(
  List<ReceiptPrintPlanNode> nodes,
  String title,
  String value, {
  bool titleBold = false,
}) {
  nodes.add(
    ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
      ReceiptPrintPlanColumn(text: title, flex: 1, bold: titleBold),
      ReceiptPrintPlanColumn(
        text: value,
        align: ReceiptPrintPlanAlign.right,
        flex: 2,
      ),
    ]),
  );
}

_CashRegisterClosurePrintSummary? _cashRegisterClosureSummaryFromExtras(
  Map<String, dynamic> extras,
) {
  final directType = _stringExtra(extras['documentType']);
  if (directType == 'cash_register_closure') {
    final directSummary = _mapFromDynamic(extras['summary']);
    if (directSummary != null) {
      return _CashRegisterClosurePrintSummary.fromJson(directSummary);
    }
  }

  final details = extras['details'];
  if (details is! List) {
    return null;
  }

  for (final rawDetail in details) {
    final detail = _mapFromDynamic(rawDetail);
    if (detail == null) continue;
    if (_stringExtra(detail['documentType']) != 'cash_register_closure') {
      continue;
    }
    final summary = _mapFromDynamic(detail['summary']) ?? detail;
    return _CashRegisterClosurePrintSummary.fromJson(summary);
  }
  return null;
}

bool _hasValue(String? value) => value != null && value.isNotEmpty;

String? _stringExtra(Object? value) {
  if (value == null) return null;
  final raw = value.toString();
  return raw.isEmpty ? null : raw;
}

Map<String, dynamic>? _mapFromDynamic(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _fallback(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '-' : trimmed;
}

String _formatClosureMoney(int value) => '¥ ${_formatNumber(value)}';

String _formatNumber(int value) {
  final sign = value < 0 ? '-' : '';
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '$sign$buffer';
}

int _toClosureInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return num.tryParse(value.trim())?.round() ?? 0;
  return 0;
}

String _toClosureString(Object? value) => (value ?? '').toString();

_ClosureLabels _closureLabelsForLocale(String? locale) {
  final normalized = (locale ?? '').toLowerCase();
  if (normalized.startsWith('zh')) {
    return const _ClosureLabels(
      machineCode: '机器码',
      printTime: '打印时间',
      staff: '工作人员',
      periodFrom: '从',
      periodTo: '到',
      settlementInfo: '结算信息',
      sales: '销售额',
      taxExcluded: '不含税',
      tax: '消费税',
      tax8Target: '8%对象',
      tax10Target: '10%对象',
      discount: '优惠',
      orderCount: '订单件数',
      refundAmount: '退款金额',
      refundCount: '退款件数',
      cash: '现金',
      voucher: '代金券/赊账',
      creditCard: '信用卡',
      traffic: '交通系',
    );
  }
  if (normalized.startsWith('en')) {
    return const _ClosureLabels(
      machineCode: 'Register No.',
      printTime: 'Print time',
      staff: 'Staff',
      periodFrom: 'From',
      periodTo: 'To',
      settlementInfo: 'Closing summary',
      sales: 'Sales',
      taxExcluded: 'Tax excl.',
      tax: 'Tax',
      tax8Target: '8% target',
      tax10Target: '10% target',
      discount: 'Discount',
      orderCount: 'Orders',
      refundAmount: 'Refund amount',
      refundCount: 'Refunds',
      cash: 'Cash',
      voucher: 'Voucher/AR',
      creditCard: 'Credit card',
      traffic: 'Transit IC',
    );
  }
  return const _ClosureLabels(
    machineCode: 'レジ番号',
    printTime: '印字日時',
    staff: 'スタッフ',
    periodFrom: 'から',
    periodTo: 'まで',
    settlementInfo: '精算情報',
    sales: '売上',
    taxExcluded: '税抜',
    tax: '消費税',
    tax8Target: '8%対象',
    tax10Target: '10%対象',
    discount: '割引',
    orderCount: '注文件数',
    refundAmount: '返金額',
    refundCount: '返金件数',
    cash: '現金',
    voucher: '代金券・売掛',
    creditCard: 'クレジット',
    traffic: '交通系',
  );
}

class _CashRegisterClosurePrintSummary {
  const _CashRegisterClosurePrintSummary({
    required this.machineCode,
    required this.shopName,
    required this.startTime,
    required this.endTime,
    required this.printTime,
    required this.verifyUserName,
    required this.aliPayTotal,
    required this.auPayTotal,
    required this.cashTotal,
    required this.creditCardTotal,
    required this.dPayTotal,
    required this.discountTotal,
    required this.mPayTotal,
    required this.noTaxTotal,
    required this.payPayTotal,
    required this.qty,
    required this.rPayTotal,
    required this.repaymentTotal,
    required this.repaymentQty,
    required this.taxTotal,
    required this.taxTotalA,
    required this.taxTotalB,
    required this.total,
    required this.trafficTotal,
    required this.voucherAmountTotal,
    required this.wechatTotal,
  });

  factory _CashRegisterClosurePrintSummary.fromJson(Map<String, dynamic> json) {
    return _CashRegisterClosurePrintSummary(
      machineCode: _toClosureString(json['machineCode']),
      shopName: _toClosureString(json['shopName']),
      startTime: _toClosureString(json['startTime']),
      endTime: _toClosureString(json['endTime']),
      printTime: _toClosureString(json['printTime']),
      verifyUserName: _toClosureString(json['verifyUserName']),
      aliPayTotal: _toClosureInt(json['aliPayTotal']),
      auPayTotal: _toClosureInt(json['au_PayTotal']),
      cashTotal: _toClosureInt(json['cashTotal']),
      creditCardTotal: _toClosureInt(json['creditCardTotal']),
      dPayTotal: _toClosureInt(json['d_PayTotal']),
      discountTotal: _toClosureInt(json['discountTotal']),
      mPayTotal: _toClosureInt(json['m_PayTotal']),
      noTaxTotal: _toClosureInt(json['noTaxTotal']),
      payPayTotal: _toClosureInt(json['payPayTotal']),
      qty: _toClosureInt(json['qty']),
      rPayTotal: _toClosureInt(json['r_PayTotal']),
      repaymentTotal: _toClosureInt(json['repaymentTotal']),
      repaymentQty: _toClosureInt(json['repaymentQty']),
      taxTotal: _toClosureInt(json['taxTotal']),
      taxTotalA: _toClosureInt(json['taxTotalA']),
      taxTotalB: _toClosureInt(json['taxTotalB']),
      total: _toClosureInt(json['total']),
      trafficTotal: _toClosureInt(json['trafficTotal']),
      voucherAmountTotal: _toClosureInt(json['voucherAmountTotal']),
      wechatTotal: _toClosureInt(json['wechatTotal']),
    );
  }

  final String machineCode;
  final String shopName;
  final String startTime;
  final String endTime;
  final String printTime;
  final String verifyUserName;
  final int aliPayTotal;
  final int auPayTotal;
  final int cashTotal;
  final int creditCardTotal;
  final int dPayTotal;
  final int discountTotal;
  final int mPayTotal;
  final int noTaxTotal;
  final int payPayTotal;
  final int qty;
  final int rPayTotal;
  final int repaymentTotal;
  final int repaymentQty;
  final int taxTotal;
  final int taxTotalA;
  final int taxTotalB;
  final int total;
  final int trafficTotal;
  final int voucherAmountTotal;
  final int wechatTotal;
}

class _ClosureLabels {
  const _ClosureLabels({
    required this.machineCode,
    required this.printTime,
    required this.staff,
    required this.periodFrom,
    required this.periodTo,
    required this.settlementInfo,
    required this.sales,
    required this.taxExcluded,
    required this.tax,
    required this.tax8Target,
    required this.tax10Target,
    required this.discount,
    required this.orderCount,
    required this.refundAmount,
    required this.refundCount,
    required this.cash,
    required this.voucher,
    required this.creditCard,
    required this.traffic,
  });

  final String machineCode;
  final String printTime;
  final String staff;
  final String periodFrom;
  final String periodTo;
  final String settlementInfo;
  final String sales;
  final String taxExcluded;
  final String tax;
  final String tax8Target;
  final String tax10Target;
  final String discount;
  final String orderCount;
  final String refundAmount;
  final String refundCount;
  final String cash;
  final String voucher;
  final String creditCard;
  final String traffic;

  String period(String start, String end) {
    return '${_fallback(start)} $periodFrom\n${_fallback(end)} $periodTo';
  }
}
