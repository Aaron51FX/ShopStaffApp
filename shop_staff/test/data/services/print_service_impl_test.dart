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

    test(
      'settlement skips HReceipt and prints only the customer receipt',
      () async {
        final renderer = _RecordingReceiptRenderer();
        final service = PrintServiceImpl(renderer: renderer);
        final document = _sampleDocument().copyWith(
          printInfo: _sampleDocument().printInfo!.copyWith(
            orderLinesMap: const <String, List<PrintOrderLine>>{},
          ),
        );

        final results = await service.enqueuePrintJobs(
          document: document,
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Legacy Local Receipt',
              type: PrinterSettings.localType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: true,
              isDefault: true,
              printIp: '192.168.1.20',
              printPort: '9100',
            ),
            PrinterSettings(
              name: 'Disabled Wi-Fi Kitchen',
              type: PrinterSettings.kitchenType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: false,
              printIp: '192.168.1.20',
              printPort: '9100',
            ),
          ],
          includeKitchenJobs: false,
          includeOrderTicket: false,
        );

        expect(results, hasLength(1));
        expect(renderer.orderTicketCalls, 0);
        expect(renderer.receiptCalls, 1);
        expect(renderer.printSequence, ['customer']);
      },
    );

    test('shopping prints HReceipt before the customer receipt', () async {
      final renderer = _RecordingReceiptRenderer();
      final service = PrintServiceImpl(renderer: renderer);

      final results = await service.enqueuePrintJobs(
        document: _sampleDocument(),
        printers: const <PrinterSettings>[
          PrinterSettings(
            name: 'Local Receipt',
            type: PrinterSettings.localType,
            backend: PrinterBackend.widgetRaster,
            connectionType: PrinterConnectionType.network,
            isOn: true,
            isDefault: true,
            printIp: '192.168.1.20',
            printPort: '9100',
          ),
        ],
        includeKitchenJobs: false,
      );

      expect(results, hasLength(1));
      expect(renderer.printSequence, ['h_receipt', 'customer']);
    });

    test('native local network printers remain supported', () async {
      final nativePrinter = _FakeNativeReceiptPrinter();
      final service = PrintServiceImpl(
        renderer: _ThrowingReceiptRenderer(),
        nativeReceiptPrinter: nativePrinter,
      );

      final results = await service.enqueuePrintJobs(
        document: _sampleDocument(),
        printers: const <PrinterSettings>[
          PrinterSettings(
            name: 'Star LAN',
            type: PrinterSettings.localType,
            backend: PrinterBackend.starXpandNative,
            connectionType: PrinterConnectionType.network,
            isOn: true,
            isDefault: true,
            printIp: '192.168.1.30',
            printPort: '9100',
          ),
        ],
        includeKitchenJobs: false,
        logoImageBase64: 'AQIDBA==',
      );

      expect(results, hasLength(1));
      expect(nativePrinter.calls, hasLength(2));
      expect(
        nativePrinter.calls.first.document.extras['documentType'],
        'h_receipt',
      );
      expect(nativePrinter.calls.last.printer.name, 'Star LAN');
      expect(
        nativePrinter.calls.last.document.extras['logoBase64'],
        'AQIDBA==',
      );
    });

    test('native settlement prints only the customer receipt', () async {
      final nativePrinter = _FakeNativeReceiptPrinter();
      final service = PrintServiceImpl(
        renderer: _ThrowingReceiptRenderer(),
        nativeReceiptPrinter: nativePrinter,
      );

      final results = await service.enqueuePrintJobs(
        document: _sampleDocument(),
        printers: const <PrinterSettings>[
          PrinterSettings(
            name: 'Star BLE',
            type: PrinterSettings.localType,
            backend: PrinterBackend.starXpandNative,
            connectionType: PrinterConnectionType.bluetoothLe,
            isOn: true,
            isDefault: true,
            deviceIdentifier: 'BLE:STAR:SETTLEMENT',
          ),
        ],
        includeKitchenJobs: false,
        includeOrderTicket: false,
      );

      expect(results, hasLength(1));
      expect(nativePrinter.calls, hasLength(1));
      expect(
        nativePrinter.calls.single.document.extras['documentType'],
        isNot('h_receipt'),
      );
    });

    test(
      'orderLines-only documents print on the local default printer',
      () async {
        final nativePrinter = _FakeNativeReceiptPrinter();
        final service = PrintServiceImpl(
          renderer: _ThrowingReceiptRenderer(),
          nativeReceiptPrinter: nativePrinter,
        );
        final document = _sampleDocument().copyWith(
          printInfo: _sampleDocument().printInfo!.copyWith(
            orderLinesMap: const <String, List<PrintOrderLine>>{},
          ),
        );

        final results = await service.enqueuePrintJobs(
          document: document,
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Wi-Fi Kitchen',
              type: PrinterSettings.kitchenType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: true,
              isDefault: true,
              printIp: '192.168.1.21',
              printPort: '9100',
            ),
            PrinterSettings(
              name: 'Local Default',
              type: PrinterSettings.localType,
              backend: PrinterBackend.starXpandNative,
              connectionType: PrinterConnectionType.bluetoothLe,
              isOn: true,
              isDefault: true,
              deviceIdentifier: 'BLE:STAR:LOCAL',
            ),
          ],
          includeKitchenJobs: false,
        );

        expect(results, hasLength(1));
        expect(results.single.printer.name, 'Local Default');
        expect(nativePrinter.calls, hasLength(2));
        expect(
          nativePrinter.calls.last.document.lines.single.name,
          'Fried Rice',
        );
      },
    );

    test(
      'orderLines-only documents do not fall back to Wi-Fi kitchen printers',
      () async {
        final service = PrintServiceImpl(renderer: _RecordingReceiptRenderer());
        final document = _sampleDocument().copyWith(
          printInfo: _sampleDocument().printInfo!.copyWith(
            orderLinesMap: const <String, List<PrintOrderLine>>{},
          ),
        );

        final results = await service.enqueuePrintJobs(
          document: document,
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Wi-Fi Kitchen',
              type: PrinterSettings.kitchenType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: true,
              isDefault: true,
              printIp: '192.168.1.21',
              printPort: '9100',
            ),
          ],
        );

        expect(results, isEmpty);
      },
    );

    test(
      'orderLinesMap-only documents create external jobs but no local receipt',
      () async {
        final renderer = _RecordingReceiptRenderer();
        final nativePrinter = _FakeNativeReceiptPrinter();
        final service = PrintServiceImpl(
          renderer: renderer,
          nativeReceiptPrinter: nativePrinter,
        );
        final document = _sampleDocument().copyWith(
          printInfo: _sampleDocument().printInfo!.copyWith(
            orderLines: const <PrintOrderLine>[],
          ),
        );

        final results = await service.enqueuePrintJobs(
          document: document,
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Local Default',
              type: PrinterSettings.localType,
              backend: PrinterBackend.starXpandNative,
              connectionType: PrinterConnectionType.bluetoothLe,
              isOn: true,
              isDefault: true,
              deviceIdentifier: 'BLE:STAR:LOCAL',
            ),
            PrinterSettings(
              name: 'Wi-Fi Kitchen',
              type: PrinterSettings.kitchenType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: true,
              printIp: '192.168.1.21',
              printPort: '9100',
            ),
          ],
        );

        expect(results, hasLength(1));
        expect(results.single.printer.name, 'Wi-Fi Kitchen');
        expect(nativePrinter.calls, isEmpty);
        expect(renderer.kitchenNumbers, ['102']);
      },
    );

    test(
      'shopping jobs keep local receipt and Wi-Fi kitchen printing',
      () async {
        final renderer = _RecordingReceiptRenderer();
        final nativePrinter = _FakeNativeReceiptPrinter();
        final service = PrintServiceImpl(
          renderer: renderer,
          nativeReceiptPrinter: nativePrinter,
        );

        final results = await service.enqueuePrintJobs(
          document: _sampleDocument(),
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Local Default',
              type: PrinterSettings.localType,
              backend: PrinterBackend.starXpandNative,
              connectionType: PrinterConnectionType.bluetoothLe,
              isOn: true,
              isDefault: true,
              deviceIdentifier: 'BLE:STAR:LOCAL',
            ),
            PrinterSettings(
              name: 'Wi-Fi Kitchen',
              type: PrinterSettings.kitchenType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: true,
              printIp: '192.168.1.21',
              printPort: '9100',
            ),
          ],
        );

        expect(results, hasLength(2));
        expect(nativePrinter.calls, hasLength(2));
        expect(
          nativePrinter.calls.first.document.extras['documentType'],
          'h_receipt',
        );
        expect(
          nativePrinter.calls.last.document.extras['documentType'],
          isNot('h_receipt'),
        );
        expect(renderer.kitchenNumbers, ['102']);
      },
    );

    test(
      'center total ticket uses orderLines instead of orderLinesMap',
      () async {
        final renderer = _RecordingReceiptRenderer();
        final service = PrintServiceImpl(renderer: renderer);
        final document = _sampleDocument().copyWith(
          printInfo: _sampleDocument().printInfo!.copyWith(
            orderType: 'Take_Out',
            orderLinesMap: const <String, List<PrintOrderLine>>{
              '10': <PrintOrderLine>[
                PrintOrderLine(name: 'Kitchen-only Dish', qty: 1, price: 300),
              ],
            },
          ),
        );

        final results = await service.enqueuePrintJobs(
          document: document,
          printers: const <PrinterSettings>[
            PrinterSettings(
              name: 'Center',
              type: PrinterSettings.centerType,
              backend: PrinterBackend.widgetRaster,
              connectionType: PrinterConnectionType.network,
              isOn: true,
              printIp: '192.168.1.22',
              printPort: '9100',
            ),
          ],
        );

        expect(results, hasLength(1));
        expect(results.single.printer.name, 'Center');
        expect(renderer.continuousItemNames, ['Fried Rice']);
      },
    );

    test('kitchen tickets display serial number instead of order id', () async {
      final renderer = _RecordingReceiptRenderer();
      final service = PrintServiceImpl(renderer: renderer);
      final document = _sampleDocument().copyWith(
        order: 'ORDER-ID',
        serialNumber: 'S-102',
        printInfo: _sampleDocument().printInfo!.copyWith(
          orderSnCode: 'ORDER-ID',
        ),
      );

      final results = await service.enqueueKitchenJobs(
        document: document,
        printers: const <PrinterSettings>[
          PrinterSettings(
            name: 'Kitchen',
            type: PrinterSettings.kitchenType,
            backend: PrinterBackend.widgetRaster,
            connectionType: PrinterConnectionType.network,
            isOn: true,
            printIp: '192.168.1.21',
            printPort: '9100',
          ),
        ],
      );

      expect(results, hasLength(1));
      expect(renderer.kitchenNumbers, ['S-102']);
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

class _RecordingReceiptRenderer extends _ThrowingReceiptRenderer {
  int orderTicketCalls = 0;
  int receiptCalls = 0;
  final List<String> kitchenNumbers = <String>[];
  final List<String> continuousItemNames = <String>[];
  final List<String> printSequence = <String>[];

  @override
  ATempWidget buildHReceipt({
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
  }) {
    orderTicketCalls++;
    printSequence.add('h_receipt');
    return _FakePrintable();
  }

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
  }) {
    receiptCalls++;
    printSequence.add('customer');
    return _FakePrintable();
  }

  @override
  ATempWidget buildContinuousReceipt({
    required PrintTicketInfo info,
    required List<Map<String, dynamic>> items,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
    bool isCenterPrint = false,
  }) {
    continuousItemNames.addAll(items.map((item) => item['name'] as String));
    return _FakePrintable();
  }

  @override
  ATempWidget buildSingleReceipt({
    required PrintTicketInfo info,
    required Map<String, dynamic> item,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
  }) {
    kitchenNumbers.add(info.orderSnCode);
    return _FakePrintable();
  }
}

class _FakePrintable with ATempWidget {
  @override
  int get pixelPagerWidth => 550;
}
