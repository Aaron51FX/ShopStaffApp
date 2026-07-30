import '../models/receipt_document_payload.dart';
import 'receipt_print_plan.dart';
import 'cash_register_closure_print_plan_builder.dart';

class ReceiptPrintPlanBuilder {
  const ReceiptPrintPlanBuilder._();

  static ReceiptPrintPlanDocument build(
    ReceiptDocumentPayload document, {
    String? logoAssetKey,
    String? footerNote,
    int paperWidthMm = 72,
    bool includeCut = true,
  }) {
    final closurePlan = CashRegisterClosurePrintPlanBuilder.tryBuild(
      document,
      paperWidthMm: paperWidthMm,
      includeCut: includeCut,
    );
    if (closurePlan != null) {
      return closurePlan;
    }

    if (_stringExtra(document.extras['documentType']) == 'h_receipt') {
      return _buildHReceiptPlan(
        document,
        paperWidthMm: paperWidthMm,
        includeCut: includeCut,
      );
    }

    final labels = _labelsForLocale(document.transaction.locale);
    final nodes = <ReceiptPrintPlanNode>[];
    final resolvedLogoAssetKey =
        logoAssetKey ?? _stringExtra(document.extras['logoAssetKey']);
    final resolvedLogoBase64 = _stringExtra(document.extras['logoBase64']);
    final resolvedFooterNote =
        footerNote ?? _stringExtra(document.extras['footerNote']);

    final hasLogoAsset =
        resolvedLogoAssetKey != null && resolvedLogoAssetKey.isNotEmpty;
    final hasLogoBase64 =
        resolvedLogoBase64 != null && resolvedLogoBase64.isNotEmpty;
    if (hasLogoAsset) {
      nodes.add(ReceiptPrintPlanNode.imageAsset(resolvedLogoAssetKey));
      nodes.add(ReceiptPrintPlanNode.spacer());
    } else if (hasLogoBase64) {
      nodes.add(ReceiptPrintPlanNode.imageBase64(resolvedLogoBase64));
      nodes.add(ReceiptPrintPlanNode.spacer());
    }

    if (!hasLogoAsset && !hasLogoBase64) {
      nodes.add(
        ReceiptPrintPlanNode.text(
          document.shop.name,
          align: ReceiptPrintPlanAlign.center,
          bold: true,
          widthScale: 2,
          heightScale: 2,
        ),
      );
    }

    for (final line in _multiline(document.shop.address)) {
      nodes.add(ReceiptPrintPlanNode.text(line));
    }
    if (_hasValue(document.shop.phone)) {
      nodes.add(
        ReceiptPrintPlanNode.text('${labels.phone}: ${document.shop.phone}'),
      );
    }
    if (_hasValue(document.shop.taxRegistrationNo)) {
      nodes.add(
        ReceiptPrintPlanNode.text(
          '${labels.taxRegistrationNo}: ${document.shop.taxRegistrationNo}',
        ),
      );
    }

    nodes.add(ReceiptPrintPlanNode.spacer());
    nodes.add(
      ReceiptPrintPlanNode.text(
        document.kind == ReceiptDocumentKind.refund
            ? labels.refundTitle
            : labels.saleTitle,
        align: ReceiptPrintPlanAlign.center,
        bold: true,
        heightScale: 2,
      ),
    );
    nodes.add(ReceiptPrintPlanNode.divider());

    _addTransactionRows(nodes, document, labels);

    if (document.lines.isNotEmpty) {
      nodes.add(ReceiptPrintPlanNode.divider());
      nodes.add(
        ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
          ReceiptPrintPlanColumn(text: labels.item, flex: 4, bold: true),
          ReceiptPrintPlanColumn(
            text: labels.amount,
            align: ReceiptPrintPlanAlign.right,
            flex: 2,
            bold: true,
          ),
        ]),
      );

      for (final line in document.lines) {
        nodes.add(ReceiptPrintPlanNode.text(_buildLineTitle(line), bold: true));
        nodes.add(
          ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
            ReceiptPrintPlanColumn(
              text:
                  '${labels.quantityShort}${line.quantity} x ${_formatMoney(line.unitPriceMinor, document.transaction.currency)}',
              flex: 4,
            ),
            ReceiptPrintPlanColumn(
              text: _formatMoney(
                line.lineTotalMinor,
                document.transaction.currency,
              ),
              align: ReceiptPrintPlanAlign.right,
              flex: 2,
              bold: true,
            ),
          ]),
        );

        for (final option in line.options) {
          nodes.add(ReceiptPrintPlanNode.text('  ${_buildOptionText(option)}'));
        }

        if (_hasValue(line.note)) {
          nodes.add(
            ReceiptPrintPlanNode.text('  ${labels.note}: ${line.note}'),
          );
        }
      }
    }

    nodes.add(ReceiptPrintPlanNode.divider());
    _addTotals(nodes, document, labels);

    if (document.payment != null) {
      nodes.add(ReceiptPrintPlanNode.divider());
      _addKeyValue(nodes, labels.paymentMethod, document.payment!.methodLabel);
      if (_hasValue(document.payment!.memberNo)) {
        _addKeyValue(nodes, labels.memberNo, document.payment!.memberNo!);
      }
    }

    if (document.refund != null) {
      nodes.add(ReceiptPrintPlanNode.divider());
      _addKeyValue(nodes, labels.refundReason, document.refund!.reasonLabel);
      _addKeyValue(
        nodes,
        labels.refundStatus,
        _refundStatusText(document.refund!.status, labels),
      );
      if (_hasValue(document.refund!.operatorName)) {
        _addKeyValue(nodes, labels.operator, document.refund!.operatorName!);
      }
      if (_hasValue(document.refund!.processedAt)) {
        _addKeyValue(nodes, labels.processedAt, document.refund!.processedAt!);
      }

      for (final settlement in document.refund!.settlements) {
        nodes.add(
          ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
            ReceiptPrintPlanColumn(text: settlement.channel, flex: 4),
            ReceiptPrintPlanColumn(
              text: _formatMoney(
                settlement.payAmountMinor > 0
                    ? settlement.payAmountMinor
                    : settlement.amountMinor,
                document.transaction.currency,
              ),
              align: ReceiptPrintPlanAlign.right,
              flex: 2,
              bold: true,
            ),
          ]),
        );
      }
    }

    final qrPaymentCode = _stringExtra(document.extras['qrPaymentCode']);
    if (qrPaymentCode != null && qrPaymentCode.isNotEmpty) {
      nodes.add(ReceiptPrintPlanNode.divider());
      nodes.add(ReceiptPrintPlanNode.qrCode(qrPaymentCode));
    }

    if (resolvedFooterNote != null && resolvedFooterNote.isNotEmpty) {
      nodes.add(ReceiptPrintPlanNode.spacer());
      for (final line in _multiline(resolvedFooterNote)) {
        nodes.add(
          ReceiptPrintPlanNode.text(line, align: ReceiptPrintPlanAlign.center),
        );
      }
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
        if (_hasValue(document.transaction.receiptId))
          'receiptId': document.transaction.receiptId,
      },
    );
  }
}

ReceiptPrintPlanDocument _buildHReceiptPlan(
  ReceiptDocumentPayload document, {
  required int paperWidthMm,
  required bool includeCut,
}) {
  final serialNumber = document.transaction.serialNumber ?? '';
  final nodes = <ReceiptPrintPlanNode>[
    ReceiptPrintPlanNode.text(
      'お客様番号',
      align: ReceiptPrintPlanAlign.center,
      bold: true,
      widthScale: 2,
      heightScale: 2,
    ),
    ReceiptPrintPlanNode.text(
      serialNumber,
      align: ReceiptPrintPlanAlign.center,
      bold: true,
      widthScale: 2,
      heightScale: 2,
    ),
    ReceiptPrintPlanNode.divider(),
  ];

  for (final line in document.lines) {
    nodes.add(
      ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
        ReceiptPrintPlanColumn(text: line.name, flex: 5, bold: true),
        ReceiptPrintPlanColumn(
          text: 'x${line.quantity}',
          align: ReceiptPrintPlanAlign.right,
          flex: 1,
          bold: true,
        ),
      ]),
    );
    for (final option in line.options) {
      final quantity = option.quantity > 1 ? ' x${option.quantity}' : '';
      nodes.add(
        ReceiptPrintPlanNode.text('  ${option.group}: ${option.name}$quantity'),
      );
    }
  }

  final time =
      document.transaction.businessDateLabel ?? document.transaction.occurredAt;
  if (_hasValue(time)) {
    nodes.add(ReceiptPrintPlanNode.spacer());
    nodes.add(
      ReceiptPrintPlanNode.text(time!, align: ReceiptPrintPlanAlign.right),
    );
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
      'documentType': 'h_receipt',
    },
  );
}

void _addTransactionRows(
  List<ReceiptPrintPlanNode> nodes,
  ReceiptDocumentPayload document,
  _ReceiptLabels labels,
) {
  if (_hasValue(document.transaction.orderId)) {
    _addKeyValue(nodes, labels.orderId, document.transaction.orderId!);
  }
  if (_hasValue(document.transaction.displayOrderNo)) {
    _addKeyValue(
      nodes,
      labels.displayOrderNo,
      document.transaction.displayOrderNo!,
    );
  }
  if (_hasValue(document.transaction.businessDateLabel)) {
    _addKeyValue(
      nodes,
      labels.datetime,
      document.transaction.businessDateLabel!,
    );
  }
  if (_hasValue(document.transaction.machineCode)) {
    _addKeyValue(nodes, labels.machineCode, document.transaction.machineCode!);
  }
  if (document.originalTransaction != null) {
    if (_hasValue(document.originalTransaction!.orderIdStr)) {
      _addKeyValue(
        nodes,
        labels.originalOrderId,
        document.originalTransaction!.orderIdStr!,
      );
    } else if (_hasValue(document.originalTransaction!.orderId)) {
      _addKeyValue(
        nodes,
        labels.originalOrderId,
        document.originalTransaction!.orderId!,
      );
    }
  }
}

void _addTotals(
  List<ReceiptPrintPlanNode> nodes,
  ReceiptDocumentPayload document,
  _ReceiptLabels labels,
) {
  _addAmountRow(
    nodes,
    labels.subtotal,
    document.totals.subtotalMinor,
    document.transaction.currency,
  );

  if (document.totals.discountMinor > 0) {
    _addAmountRow(
      nodes,
      labels.discount,
      document.totals.discountMinor,
      document.transaction.currency,
    );
  }

  for (final tax in document.totals.taxLines) {
    _addAmountRow(
      nodes,
      '${labels.tax} ${tax.label}',
      tax.taxMinor,
      document.transaction.currency,
    );
  }

  _addAmountRow(
    nodes,
    labels.total,
    document.totals.grandTotalMinor,
    document.transaction.currency,
    bold: true,
  );

  if (document.totals.paidMinor != null) {
    _addAmountRow(
      nodes,
      labels.paid,
      document.totals.paidMinor!,
      document.transaction.currency,
    );
  }
  if (document.totals.changeMinor != null && _isCashPayment(document)) {
    _addAmountRow(
      nodes,
      labels.change,
      document.totals.changeMinor!,
      document.transaction.currency,
    );
  }
}

bool _isCashPayment(ReceiptDocumentPayload document) {
  final payment = document.payment;
  if (payment == null) return false;
  final methodCode = payment.methodCode.trim().toLowerCase();
  return methodCode == 'cash' || payment.methodLabel.contains('現金');
}

void _addAmountRow(
  List<ReceiptPrintPlanNode> nodes,
  String label,
  int value,
  String currency, {
  bool bold = false,
}) {
  nodes.add(
    ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
      ReceiptPrintPlanColumn(text: label, flex: 4, bold: bold),
      ReceiptPrintPlanColumn(
        text: _formatMoney(value, currency),
        align: ReceiptPrintPlanAlign.right,
        flex: 2,
        bold: bold,
      ),
    ]),
  );
}

void _addKeyValue(
  List<ReceiptPrintPlanNode> nodes,
  String label,
  String value,
) {
  nodes.add(
    ReceiptPrintPlanNode.row(<ReceiptPrintPlanColumn>[
      ReceiptPrintPlanColumn(text: label, flex: 2, bold: true),
      ReceiptPrintPlanColumn(
        text: value,
        align: ReceiptPrintPlanAlign.right,
        flex: 4,
      ),
    ]),
  );
}

String _buildLineTitle(ReceiptLinePayload line) {
  if (_hasValue(line.categoryName)) {
    return '${line.name} (${line.categoryName})';
  }
  return line.name;
}

String _buildOptionText(ReceiptLineOptionPayload option) {
  final prefix = option.group.isEmpty
      ? option.name
      : '${option.group}: ${option.name}';
  if (option.quantity > 1) {
    return '$prefix x${option.quantity}';
  }
  return prefix;
}

bool _hasValue(String? value) => value != null && value.isNotEmpty;

String _formatMoney(int value, String currency) {
  switch (currency.toUpperCase()) {
    case 'JPY':
      return '¥$value';
    default:
      return '${currency.toUpperCase()} $value';
  }
}

List<String> _multiline(String? raw) {
  if (!_hasValue(raw)) return const <String>[];
  return raw!
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String? _stringExtra(Object? value) {
  if (value == null) return null;
  final raw = value.toString();
  return raw.isEmpty ? null : raw;
}

_ReceiptLabels _labelsForLocale(String? locale) {
  final normalized = (locale ?? '').toLowerCase();
  if (normalized.startsWith('zh')) {
    return const _ReceiptLabels(
      saleTitle: '购物小票',
      refundTitle: '退款小票',
      orderId: '订单号',
      originalOrderId: '原订单号',
      displayOrderNo: '取餐号',
      datetime: '时间',
      machineCode: '机号',
      item: '商品',
      amount: '金额',
      quantityShort: 'x',
      subtotal: '小计',
      discount: '折扣',
      tax: '税额',
      total: '合计',
      paid: '实付',
      change: '找零',
      paymentMethod: '支付方式',
      memberNo: '会员号',
      refundReason: '退款原因',
      refundStatus: '退款状态',
      processedAt: '退款时间',
      operator: '操作员',
      note: '备注',
      phone: '电话',
      taxRegistrationNo: '税号',
      refundStatusSuccess: '成功',
      refundStatusPartial: '部分成功',
      refundStatusFailed: '失败',
    );
  }
  if (normalized.startsWith('en')) {
    return const _ReceiptLabels(
      saleTitle: 'Sales Receipt',
      refundTitle: 'Refund Receipt',
      orderId: 'Order ID',
      originalOrderId: 'Original Order',
      displayOrderNo: 'Display No.',
      datetime: 'Date Time',
      machineCode: 'Machine',
      item: 'Item',
      amount: 'Amount',
      quantityShort: 'x',
      subtotal: 'Subtotal',
      discount: 'Discount',
      tax: 'Tax',
      total: 'Total',
      paid: 'Paid',
      change: 'Change',
      paymentMethod: 'Payment',
      memberNo: 'Member No.',
      refundReason: 'Refund Reason',
      refundStatus: 'Refund Status',
      processedAt: 'Processed At',
      operator: 'Operator',
      note: 'Note',
      phone: 'Phone',
      taxRegistrationNo: 'Tax ID',
      refundStatusSuccess: 'Success',
      refundStatusPartial: 'Partial',
      refundStatusFailed: 'Failed',
    );
  }
  return const _ReceiptLabels(
    saleTitle: '領収書',
    refundTitle: '返金伝票',
    orderId: '注文番号',
    originalOrderId: '元注文',
    displayOrderNo: 'お客様番号',
    datetime: '日時',
    machineCode: '端末',
    item: '商品',
    amount: '金額',
    quantityShort: 'x',
    subtotal: '小計',
    discount: '割引',
    tax: '税額',
    total: '合計',
    paid: '支払',
    change: '釣銭',
    paymentMethod: '支払方法',
    memberNo: '会員番号',
    refundReason: '返金理由',
    refundStatus: '返金状態',
    processedAt: '返金日時',
    operator: '担当者',
    note: '備考',
    phone: '電話',
    taxRegistrationNo: '登録番号',
    refundStatusSuccess: '成功',
    refundStatusPartial: '一部成功',
    refundStatusFailed: '失敗',
  );
}

String _refundStatusText(ReceiptRefundStatus status, _ReceiptLabels labels) {
  switch (status) {
    case ReceiptRefundStatus.success:
      return labels.refundStatusSuccess;
    case ReceiptRefundStatus.partial:
      return labels.refundStatusPartial;
    case ReceiptRefundStatus.failed:
      return labels.refundStatusFailed;
  }
}

class _ReceiptLabels {
  const _ReceiptLabels({
    required this.saleTitle,
    required this.refundTitle,
    required this.orderId,
    required this.originalOrderId,
    required this.displayOrderNo,
    required this.datetime,
    required this.machineCode,
    required this.item,
    required this.amount,
    required this.quantityShort,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.paymentMethod,
    required this.memberNo,
    required this.refundReason,
    required this.refundStatus,
    required this.processedAt,
    required this.operator,
    required this.note,
    required this.phone,
    required this.taxRegistrationNo,
    required this.refundStatusSuccess,
    required this.refundStatusPartial,
    required this.refundStatusFailed,
  });

  final String saleTitle;
  final String refundTitle;
  final String orderId;
  final String originalOrderId;
  final String displayOrderNo;
  final String datetime;
  final String machineCode;
  final String item;
  final String amount;
  final String quantityShort;
  final String subtotal;
  final String discount;
  final String tax;
  final String total;
  final String paid;
  final String change;
  final String paymentMethod;
  final String memberNo;
  final String refundReason;
  final String refundStatus;
  final String processedAt;
  final String operator;
  final String note;
  final String phone;
  final String taxRegistrationNo;
  final String refundStatusSuccess;
  final String refundStatusPartial;
  final String refundStatusFailed;
}
