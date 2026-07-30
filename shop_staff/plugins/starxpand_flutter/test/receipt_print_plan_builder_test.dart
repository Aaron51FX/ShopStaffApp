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
          'taxRegistrationNo': 'T1234567890123',
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
              node.type == ReceiptPrintPlanNodeType.text &&
              node.text == 'Tokyo Shop',
        ),
        isFalse,
      );
      for (final expected in <String>[
        'Tokyo',
        'Chiyoda',
        '電話: 03-0000-0000',
        '登録番号: T1234567890123',
      ]) {
        final node = plan.nodes.firstWhere((node) => node.text == expected);
        expect(node.align, ReceiptPrintPlanAlign.left);
      }
      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.qrCode &&
              node.qrData == 'PAY-QR-001',
        ),
        isTrue,
      );
      final transactionRows = plan.nodes
          .where((node) => node.type == ReceiptPrintPlanNodeType.row)
          .map((node) => node.columns.map((column) => column.text).toList())
          .toList();
      expect(
        transactionRows,
        anyElement(orderedEquals(<String>['注文番号', '9001'])),
      );
      expect(
        transactionRows,
        anyElement(orderedEquals(<String>['お客様番号', 'A001'])),
      );
      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.text && node.text == '領収書',
        ),
        isTrue,
      );
      expect(transactionRows.expand((row) => row), isNot(contains('レシートID')));
      expect(transactionRows.expand((row) => row), isNot(contains('伝票番号')));
      expect(plan.nodes.last.type, ReceiptPrintPlanNodeType.cut);
    });

    test('does not print change for non-cash payment', () {
      final payload = ReceiptDocumentPayload.fromJson(<String, dynamic>{
        'schema': 'shop_staff.receipt.v1',
        'kind': 'sale',
        'shop': <String, dynamic>{'name': 'Tokyo Shop'},
        'transaction': <String, dynamic>{
          'receiptId': 'sale-9002',
          'locale': 'ja-JP',
          'currency': 'JPY',
        },
        'totals': <String, dynamic>{
          'subtotalMinor': 220,
          'grandTotalMinor': 220,
          'paidMinor': 220,
          'changeMinor': 0,
        },
        'payment': <String, dynamic>{
          'methodCode': 'qr',
          'methodLabel': 'QR Code',
        },
      });

      final plan = ReceiptPrintPlanBuilder.build(payload);
      final rowLabels = plan.nodes
          .where((node) => node.type == ReceiptPrintPlanNodeType.row)
          .expand((node) => node.columns)
          .map((column) => column.text);

      expect(rowLabels, isNot(contains('釣銭')));
    });

    test('builds a compact HReceipt plan when requested', () {
      final payload = ReceiptDocumentPayload.fromJson(<String, dynamic>{
        'schema': 'shop_staff.receipt.v1',
        'kind': 'sale',
        'shop': <String, dynamic>{'name': 'Tokyo Shop'},
        'transaction': <String, dynamic>{
          'receiptId': 'sale-9001',
          'serialNumber': 'S-102',
          'businessDateLabel': '2026-07-29 12:30',
          'locale': 'ja-JP',
          'currency': 'JPY',
        },
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Beef Noodle',
            'quantity': 2,
            'unitPriceMinor': 100,
            'lineTotalMinor': 200,
            'options': <Map<String, dynamic>>[
              <String, dynamic>{
                'group': 'Size',
                'name': 'Large',
                'quantity': 1,
                'priceDeltaMinor': 0,
              },
            ],
          },
        ],
        'totals': <String, dynamic>{
          'subtotalMinor': 200,
          'grandTotalMinor': 200,
        },
        'extras': <String, dynamic>{'documentType': 'h_receipt'},
      });

      final plan = ReceiptPrintPlanBuilder.build(payload);
      final texts = plan.nodes
          .where((node) => node.type == ReceiptPrintPlanNodeType.text)
          .map((node) => node.text)
          .toList();

      expect(plan.extras['documentType'], 'h_receipt');
      expect(texts, containsAll(<String?>['お客様番号', 'S-102']));
      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.row &&
              node.columns.any((column) => column.text == 'Beef Noodle'),
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

    test('builds cash register closure plan from document details', () {
      final payload = ReceiptDocumentPayload.fromJson(<String, dynamic>{
        'schema': 'shop_staff.receipt.v1',
        'kind': 'sale',
        'shop': <String, dynamic>{'name': 'Tokyo Shop'},
        'transaction': <String, dynamic>{
          'receiptId': 'closure-M001',
          'locale': 'ja-JP',
          'currency': 'JPY',
        },
        'totals': <String, dynamic>{
          'subtotalMinor': 12345,
          'grandTotalMinor': 12345,
        },
        'extras': <String, dynamic>{
          'details': <Map<String, dynamic>>[
            <String, dynamic>{
              'documentType': 'cash_register_closure',
              'summary': <String, dynamic>{
                'machineCode': 'M001',
                'shopName': 'Tokyo Shop',
                'startTime': '2026-06-09 09:00',
                'endTime': '2026-06-09 21:00',
                'printTime': '2026-06-09 21:10',
                'verifyUserName': 'Aaron',
                'total': 12345,
                'noTaxTotal': 11223,
                'taxTotal': 1122,
                'taxTotalA': 1000,
                'taxTotalB': 122,
                'qty': 15,
                'repaymentQty': 1,
                'cashTotal': 5000,
                'creditCardTotal': 4000,
                'payPayTotal': 2000,
                'aliPayTotal': 1000,
                'wechatTotal': 345,
                'r_PayTotal': 0,
                'au_PayTotal': 0,
                'd_PayTotal': 0,
                'm_PayTotal': 0,
                'trafficTotal': 0,
                'voucherAmountTotal': 0,
              },
            },
          ],
        },
      });

      final plan = ReceiptPrintPlanBuilder.build(payload);

      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.text && node.text == '精算情報',
        ),
        isTrue,
      );
      final salesRow = plan.nodes.firstWhere(
        (node) =>
            node.type == ReceiptPrintPlanNodeType.row &&
            node.columns.any((column) => column.text == '売上'),
      );
      expect(salesRow.columns, hasLength(2));
      expect(salesRow.columns.first.text, '売上');
      expect(salesRow.columns.first.align, ReceiptPrintPlanAlign.left);
      expect(salesRow.columns.last.text, '¥ 12,345');
      expect(salesRow.columns.last.align, ReceiptPrintPlanAlign.right);
      expect(
        salesRow.columns.map((column) => column.flex).toList(growable: false),
        <int>[1, 1],
      );
      expect(
        plan.nodes.any((node) {
          final text = node.text ?? '';
          final columnTexts = node.columns.map((column) => column.text).join();
          return text.contains('釣銭機') || columnTexts.contains('金種');
        }),
        isFalse,
      );
      expect(
        plan.nodes.any(
          (node) =>
              node.type == ReceiptPrintPlanNodeType.text && node.text == '販売明細',
        ),
        isFalse,
      );
    });
  });
}
