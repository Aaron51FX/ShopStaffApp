import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/services/receipt_document_adapters.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/domain/entities/receipt_document.dart';
import 'package:shop_staff/domain/entities/refund_receipt_source.dart';

void main() {
  group('SaleReceiptDocumentAdapter', () {
    test('maps print info into canonical sale receipt document', () {
      const document = PrintInfoDocument(
        shopName: 'Tokyo Shop',
        shopCode: 'SHOP-01',
        address: 'Tokyo\nChiyoda',
        telNo: '03-0000-0000',
        ntaNo: 'T123456789',
        orderDate: '2026-04-13 12:30',
        orderTime: '12:30',
        orderId: 9001,
        language: 'JP',
        price: 220,
        payPrice: 220,
        change: 30,
        payMethod: 'cash',
        serialNumberText: 'A001',
        numberTip: 'お客様番号',
        printInfo: PrintTicketInfo(
          orderType: 'Shop_In',
          paymentCode: 'PAY-QR',
          orderLines: <PrintOrderLine>[
            PrintOrderLine(
              bizId: 11,
              categoryName: 'Noodle',
              name: 'Beef Noodle',
              price: 100,
              qty: 2,
              options: <String, List<PrintOrderOption>>{
                'Size': <PrintOrderOption>[
                  PrintOrderOption(name: 'Large', price: 10, qty: 1),
                ],
              },
            ),
          ],
        ),
      );

      final receipt = SaleReceiptDocumentAdapter.fromPrintInfo(document);

      expect(receipt.kind, ReceiptDocumentKind.sale);
      expect(receipt.detailLevel, ReceiptDetailLevel.itemized);
      expect(receipt.shop.name, 'Tokyo Shop');
      expect(receipt.shop.address, 'Tokyo\nChiyoda');
      expect(receipt.transaction.orderMode, ReceiptOrderMode.dineIn);
      expect(receipt.lines, hasLength(1));
      expect(receipt.lines.single.lineTotalMinor, 220);
      expect(receipt.totals.grandTotalMinor, 220);
      expect(receipt.payment?.methodCode, 'cash');
      expect(receipt.extras['qrPaymentCode'], 'PAY-QR');
    });
  });

  group('RefundReceiptDocumentAdapter', () {
    test('builds refund receipt from original order and settlements', () {
      const originalPrintInfo = PrintInfoDocument(
        shopName: 'Tokyo Shop',
        shopCode: 'SHOP-01',
        address: 'Tokyo\nChiyoda',
        telNo: '03-0000-0000',
        ntaNo: 'T123456789',
        price: 220,
        tax2: 16,
        baseTax2: 204,
        payDate: '2026-04-13 12:30',
        serialNumberText: 'A001',
      );

      final source = RefundReceiptSource(
        originalOrder: _localOrderRecord(),
        originalPrintInfo: originalPrintInfo,
        refundedLines: <RefundLineSelection>[
          RefundLineSelection.fromCartItem(_cartItem(), quantity: 1),
        ],
        settlements: const <RefundSettlementRecord>[
          RefundSettlementRecord(
            address: 'Tokyo Chiyoda',
            amountMinor: 220,
            changeMinor: 0,
            couponMinor: 0,
            executeMark: true,
            machineCode: 'M001',
            orderId: 9001,
            orderIdStr: '9001',
            payAmountMinor: 220,
            payChannel: 'cash',
            payTime: '2026-04-13 13:10',
            requestMessage: 'REQ',
            responseMessage: 'OK',
            serialNumber: 'A001',
            shopName: 'Tokyo Shop',
            telNo: '03-0000-0000',
          ),
        ],
        refundId: 'RF-1',
        reasonCode: 'customer_cancel',
        reasonLabel: 'Customer Cancel',
        operatorId: 'staff-1',
        operatorName: 'Aaron',
        requestedTotalMinor: 220,
      );

      final receipt = RefundReceiptDocumentAdapter.fromSource(source);

      expect(receipt.kind, ReceiptDocumentKind.refund);
      expect(receipt.transaction.receiptId, 'RF-1');
      expect(receipt.originalTransaction?.orderId, '9001');
      expect(receipt.lines, hasLength(1));
      expect(receipt.totals.grandTotalMinor, 220);
      expect(receipt.totals.paidMinor, 220);
      expect(receipt.totals.taxLines, hasLength(1));
      expect(receipt.refund?.status, ReceiptRefundStatus.success);
      expect(receipt.refund?.settlements.single.channel, 'cash');
      expect(receipt.refund?.settlements.single.gateway?.responseMessage, 'OK');
    });
  });

  group('ReceiptDocument', () {
    test('round-trips via json', () {
      final original = ReceiptDocument(
        kind: ReceiptDocumentKind.sale,
        shop: const ReceiptShopInfo(name: 'Tokyo Shop'),
        transaction: const ReceiptTransactionInfo(
          receiptId: 'sale-1',
          currency: 'JPY',
        ),
        lines: const <ReceiptLine>[
          ReceiptLine(
            name: 'Tea',
            quantity: 1,
            unitPriceMinor: 100,
            lineTotalMinor: 100,
          ),
        ],
        totals: const ReceiptTotals(
          subtotalMinor: 100,
          discountMinor: 0,
          grandTotalMinor: 100,
        ),
        extras: const <String, dynamic>{'note': 'hello'},
      );

      final decoded = ReceiptDocument.fromJson(original.toJson());

      expect(decoded, original);
    });
  });
}

LocalOrderRecord _localOrderRecord() {
  return LocalOrderRecord(
    orderId: '9001',
    createdAt: DateTime(2026, 4, 13, 12, 30),
    isPaid: true,
    payMethod: 'cash',
    items: <CartItem>[_cartItem()],
    machineCode: 'M001',
    language: 'JP',
    takeout: false,
    discount: 0,
    clientTotal: 220,
    orderResult: const OrderSubmissionResult(
      orderId: '9001',
      tax1: 0,
      baseTax1: 0,
      tax2: 16,
      baseTax2: 204,
      total: 220,
    ),
  );
}

CartItem _cartItem() {
  return CartItem(
    id: 'line-1',
    product: const Product(
      id: 1,
      name: 'Beef Noodle',
      categoryId: 'noodle',
      price: 200,
      originalPrice: 200,
      tax: 8,
      imageUrl: '',
    ),
    options: const <SelectedOption>[
      SelectedOption(
        groupCode: 'size',
        groupName: 'Size',
        optionCode: 'large',
        optionName: 'Large',
        extraPrice: 20,
        quantity: 1,
      ),
    ],
    quantity: 1,
  );
}
