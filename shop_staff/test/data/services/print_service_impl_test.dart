import 'package:flutter_test/flutter_test.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/services/print_service_impl.dart';
import 'package:shop_staff/domain/entities/receipt_document.dart';
import 'package:shop_staff/domain/services/native_receipt_printer.dart';
import 'package:shop_staff/domain/services/receipt_renderer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

void main() {
  group('PrintServiceImpl', () {
    test(
      'routes receipt jobs to native printer when StarXpand printer is configured',
      () async {
        final nativePrinter = _FakeNativeReceiptPrinter();
        final service = PrintServiceImpl(
          renderer: _ThrowingReceiptRenderer(),
          nativeReceiptPrinter: nativePrinter,
        );

        final printers = <PrinterSettings>[
          const PrinterSettings(
            name: 'Star BLE',
            type: 0,
            backend: PrinterBackend.starXpandNative,
            connectionType: PrinterConnectionType.bluetoothLe,
            isOn: true,
            deviceIdentifier: 'BLE:STAR:001',
          ),
        ];

        final results = await service.enqueueReceiptJobs(
          document: _sampleDocument(),
          printers: printers,
        );

        expect(results, hasLength(1));
        expect(results.single.isSuccess, isTrue);
        expect(nativePrinter.calls, hasLength(1));
        expect(nativePrinter.calls.single.printer, same(printers.single));
        expect(
          nativePrinter.calls.single.document.kind,
          ReceiptDocumentKind.sale,
        );
        expect(
          nativePrinter.calls.single.document.lines.single.name,
          'Fried Rice',
        );
      },
    );

    test(
      'does not select a native receipt printer without a usable identifier',
      () async {
        final nativePrinter = _FakeNativeReceiptPrinter();
        final service = PrintServiceImpl(
          renderer: _ThrowingReceiptRenderer(),
          nativeReceiptPrinter: nativePrinter,
        );

        final results = await service.enqueueReceiptJobs(
          document: _sampleDocument(),
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Broken Star BLE',
              type: 0,
              backend: PrinterBackend.starXpandNative,
              connectionType: PrinterConnectionType.bluetoothLe,
              isOn: true,
            ),
          ],
        );

        expect(results, isEmpty);
        expect(nativePrinter.calls, isEmpty);
      },
    );

    test('prefers the local printer over legacy receipt printers', () async {
      final nativePrinter = _FakeNativeReceiptPrinter();
      final service = PrintServiceImpl(
        renderer: _ThrowingReceiptRenderer(),
        nativeReceiptPrinter: nativePrinter,
      );

      final printers = <PrinterSettings>[
        const PrinterSettings(
          name: 'Legacy Receipt',
          type: 10,
          backend: PrinterBackend.widgetRaster,
          connectionType: PrinterConnectionType.network,
          isOn: true,
          printIp: '192.168.1.20',
          printPort: '9100',
        ),
        const PrinterSettings(
          name: 'Star BLE',
          type: 0,
          backend: PrinterBackend.starXpandNative,
          connectionType: PrinterConnectionType.bluetoothLe,
          isOn: true,
          deviceIdentifier: 'BLE:STAR:002',
        ),
      ];

      final results = await service.enqueueReceiptJobs(
        document: _sampleDocument(),
        printers: printers,
      );

      expect(results, hasLength(1));
      expect(nativePrinter.calls, hasLength(1));
      expect(nativePrinter.calls.single.printer.type, 0);
    });
  });
}

PrintInfoDocument _sampleDocument() {
  const line = PrintOrderLine(
    name: 'Fried Rice',
    qty: 2,
    price: 580,
    options: <String, List<PrintOrderOption>>{
      'Spice': <PrintOrderOption>[PrintOrderOption(name: 'Mild', qty: 1)],
    },
  );

  return const PrintInfoDocument(
    shopName: 'Shop Staff',
    address: 'Tokyo',
    telNo: '03-0000-0000',
    order: 'A-102',
    orderDate: '2026-04-13 10:30',
    serialNumber: '102',
    price: 1160,
    payPrice: 1160,
    payMethod: 'Cash',
    printInfo: PrintTicketInfo(
      orderType: 'Shop_In',
      orderLines: <PrintOrderLine>[line],
      orderLinesMap: <String, List<PrintOrderLine>>{
        '10': <PrintOrderLine>[line],
      },
    ),
  );
}

class _FakeNativeReceiptPrinter implements NativeReceiptPrinter {
  final List<_NativePrintCall> calls = <_NativePrintCall>[];

  @override
  Future<void> printReceipt({
    required ReceiptDocument document,
    required PrinterSettings printer,
  }) async {
    calls.add(_NativePrintCall(document: document, printer: printer));
  }
}

class _NativePrintCall {
  const _NativePrintCall({required this.document, required this.printer});

  final ReceiptDocument document;
  final PrinterSettings printer;
}

class _ThrowingReceiptRenderer implements ReceiptRenderer {
  Never _unexpected() {
    fail('Widget raster renderer should not be used for native receipt jobs.');
  }

  @override
  ATempWidget? buildLabelHead({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  }) => _unexpected();

  @override
  List<ATempWidget> buildLabels({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  }) => _unexpected();

  @override
  ATempWidget buildContinuousReceipt({
    required PrintTicketInfo info,
    required List<Map<String, dynamic>> items,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
    bool isCenterPrint = false,
  }) => _unexpected();

  @override
  ATempWidget buildHReceipt({
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
  }) => _unexpected();

  @override
  ATempWidget buildReceipt({
    required String shopName,
    required String shopIcon,
    required String address,
    required String orderSnCode,
    required String telephone,
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
    required bool isTakeOut,
    required String payPrice,
    required String change,
    required String paymentMethod,
    required String tax1,
    required String baseTax1,
    required String tax2,
    required String baseTax2,
    required String total,
    String discount = '0',
    String voucherAmount = '0',
    String cardNumber = '',
  }) => _unexpected();

  @override
  ATempWidget buildSingleReceipt({
    required PrintTicketInfo info,
    required Map<String, dynamic> item,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
  }) => _unexpected();
}
