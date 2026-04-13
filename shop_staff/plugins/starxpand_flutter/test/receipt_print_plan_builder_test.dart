import 'package:flutter_test/flutter_test.dart';
import 'package:starxpand_flutter/src/models/receipt_document_payload.dart';
import 'package:starxpand_flutter/src/plan/receipt_print_plan.dart';
import 'package:starxpand_flutter/src/plan/receipt_print_plan_builder.dart';

void main() {
  group('ReceiptPrintPlanBuilder', () {
    test('builds sales plan with logo and qr code', () {
      final payload = ReceiptDocumentPayload.fromJson(<String, dynamic>{
        'schema': 'shop_staff.receipt.v1',
        'kind': 'sale',
        'shop': <String, dynamic>{
          'name': 'Tokyo Shop',
          'address': 'Tokyo\nChiyoda',
          'phone': '03-0000-0000',
        },
        'transaction': <String, dynamic>{
          'receiptId': 'sale-9001',
          'orderId': '9001',
          'displayOrderNo': 'A001',
          'serialNumber': 'A001',
          'businessDateLabel': '2026-04-13 12:30',
          'machineCode': 'M001',
          'locale': 'ja-JP',
          'currency': 'JPY',
        },
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Beef Noodle',
            'categoryName': 'Noodle',
            'quantity': 2,
            'unitPriceMinor': 100,
            'lineTotalMinor': 220,
            'options': <Map<String, dynamic>>[
              <String, dynamic>{
                'group': 'Size',
                'name': 'Large',
                'quantity': 1,
                'priceDeltaMinor': 10,
              },
            ],
          },
        ],
        'totals': <String, dynamic>{
          'subtotalMinor': 220,
          'discountMinor': 0,
          'taxLines': <Map<String, dynamic>>[
            <String, dynamic>{'label': '8%', 'baseMinor': 204, 'taxMinor': 16},
          ],
          'grandTotalMinor': 220,
          'paidMinor': 220,
          'changeMinor': 0,
        },
        'payment': <String, dynamic>{'methodCode': 'cash', 'methodLabel': '現金'},
        'extras': <String, dynamic>{
          'logoAssetKey': 'assets/logo/shop.png',
          'qrPaymentCode': 'PAY-QR-001',
        },
      });

      final plan = ReceiptPrintPlanBuilder.build(payload);

      expect(plan.kind, ReceiptDocumentKind.sale);
      expect(plan.nodes.first.type, ReceiptPrintPlanNodeType.image);
      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.qrCode &&
              node.qrData == 'PAY-QR-001',
        ),
        isTrue,
      );
      expect(plan.nodes.last.type, ReceiptPrintPlanNodeType.cut);
    });

    test('builds refund plan without cut when disabled', () {
      final payload = ReceiptDocumentPayload.fromJson(<String, dynamic>{
        'schema': 'shop_staff.receipt.v1',
        'kind': 'refund',
        'shop': <String, dynamic>{'name': 'Tokyo Shop'},
        'transaction': <String, dynamic>{
          'receiptId': 'refund-1',
          'locale': 'zh-CN',
          'currency': 'JPY',
        },
        'originalTransaction': <String, dynamic>{
          'orderId': '9001',
          'orderIdStr': '9001',
        },
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Beef Noodle',
            'quantity': 1,
            'unitPriceMinor': 220,
            'lineTotalMinor': 220,
          },
        ],
        'totals': <String, dynamic>{
          'subtotalMinor': 220,
          'grandTotalMinor': 220,
          'paidMinor': 220,
        },
        'refund': <String, dynamic>{
          'refundId': 'RF-1',
          'reasonCode': 'customer_cancel',
          'reasonLabel': '顾客取消',
          'operatorName': 'Aaron',
          'requestedTotalMinor': 220,
          'approvedTotalMinor': 220,
          'status': 'success',
          'settlements': <Map<String, dynamic>>[
            <String, dynamic>{
              'channel': 'cash',
              'amountMinor': 220,
              'payAmountMinor': 220,
              'executeMark': true,
            },
          ],
          'processedAt': '2026-04-13 13:10',
        },
      });

      final plan = ReceiptPrintPlanBuilder.build(payload, includeCut: false);

      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.text && node.text == '退款小票',
        ),
        isTrue,
      );
      expect(
        plan.nodes.any((node) => node.type == ReceiptPrintPlanNodeType.cut),
        isFalse,
      );
    });
  });
}
