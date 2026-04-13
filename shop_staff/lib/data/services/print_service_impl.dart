import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/services/receipt_document_adapters.dart';
import 'package:shop_staff/domain/services/native_receipt_printer.dart';
import 'package:shop_staff/domain/services/print_service.dart';
import 'package:shop_staff/domain/services/receipt_renderer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class PrintServiceImpl implements PrintService {
  PrintServiceImpl({
    required ReceiptRenderer renderer,
    NativeReceiptPrinter? nativeReceiptPrinter,
  }) : _renderer = renderer,
       _nativeReceiptPrinter = nativeReceiptPrinter;

  final ReceiptRenderer _renderer;
  final NativeReceiptPrinter? _nativeReceiptPrinter;

  @override
  Future<List<PrintJobResult>> enqueuePrintJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  }) async {
    final results = <PrintJobResult>[];
    final info = document.printInfo;
    if (info == null || info.orderLinesMap.isEmpty || printers.isEmpty) {
      return results;
    }

    final isTakeOut = info.orderType != 'Shop_In';

    final receiptPrinter = _pickReceiptPrinter(printers);
    if (receiptPrinter != null) {
      final result = await _printReceipt(document, receiptPrinter);
      if (result != null) {
        results.add(result);
      }
    }

    results.addAll(
      await enqueueKitchenJobs(document: document, printers: printers),
    );

    // Center consolidated receipt (type 11) when enabled and takeout
    final centerPrinter = printers.firstWhere(
      (p) => p.type == 11 && _isWidgetPrinterAvailable(p),
      orElse: () => const PrinterSettings(name: '', type: -1),
    );

    if (centerPrinter.type == 11 && isTakeOut) {
      _enqueueReceipt(document, centerPrinter, forceContinuous: true);
      results.add(PrintJobResult(printer: centerPrinter));
    }

    return results;
  }

  @override
  Future<List<PrintJobResult>> enqueueReceiptJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  }) async {
    final results = <PrintJobResult>[];
    final info = document.printInfo;
    if (info == null || info.orderLinesMap.isEmpty || printers.isEmpty) {
      return results;
    }

    final printer = _pickReceiptPrinter(printers);
    if (printer == null) return results;

    final result = await _printReceipt(document, printer);
    if (result != null) {
      results.add(result);
    }
    return results;
  }

  @override
  Future<List<PrintJobResult>> enqueueKitchenJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  }) async {
    final results = <PrintJobResult>[];
    final info = document.printInfo;
    if (info == null || info.orderLinesMap.isEmpty || printers.isEmpty) {
      return results;
    }

    for (final entry in info.orderLinesMap.entries) {
      final typeKey = int.tryParse(entry.key);
      if (typeKey == null) continue;

      final printer = printers.firstWhere(
        (p) => p.type == typeKey && _isWidgetPrinterAvailable(p),
        orElse: () => const PrinterSettings(name: '', type: -1),
      );
      if (printer.type != typeKey) continue;

      final lines = entry.value;
      if (lines.isEmpty) continue;

      final docForPrinter = _documentForLines(document, lines, typeKey);
      final isLabel = printer.receipt == false;

      if (isLabel) {
        _enqueueLabelTickets(docForPrinter, printer);
      } else {
        _enqueueReceipt(docForPrinter, printer);
      }

      results.add(PrintJobResult(printer: printer));
    }

    return results;
  }

  PrinterSettings? _pickReceiptPrinter(List<PrinterSettings> printers) {
    final active = printers
        .where(_isReceiptPrinterAvailable)
        .toList(growable: false);
    if (active.isEmpty) return null;

    final receiptCapable = active
        .where((p) => p.receipt != false)
        .toList(growable: false);
    if (receiptCapable.isEmpty) return null;

    for (final p in receiptCapable) {
      if (p.type == PrinterSettings.localType) return p;
    }

    for (final p in receiptCapable) {
      if (p.type == PrinterSettings.kitchenType) return p;
    }
    return receiptCapable.first;
  }

  Future<PrintJobResult?> _printReceipt(
    PrintInfoDocument document,
    PrinterSettings printer,
  ) async {
    final info = document.printInfo;
    if (info == null) return null;

    if (printer.usesNativeSdk) {
      return _printReceiptNative(document, printer);
    }

    final isTakeOut = document.takeOut;
    final mappedLines = _linesFromMap(info);
    final items = _toLegacyItems(mappedLines);
    if (items.isEmpty) return null;

    final hReceiptWidget = _renderer.buildHReceipt(
      number: document.serialNumber ?? '',
      items: items,
      timeStamp: document.orderDate,
    );

    _submitTask(hReceiptWidget, printer, PrintTypeEnum.receipt);

    final receiptWidget = _renderer.buildReceipt(
      shopName: document.shopName,
      shopIcon: '',
      address: document.address,
      orderSnCode: document.order,
      telephone: document.telNo,
      number: document.serialNumber ?? '',
      items: items,
      timeStamp: document.orderDate,
      isTakeOut: isTakeOut,
      payPrice: document.price.toString(),
      change: document.change.toString(),
      paymentMethod: document.payMethod,
      tax1: document.tax1.toString(),
      baseTax1: document.baseTax1.toString(),
      tax2: document.tax2.toString(),
      baseTax2: document.baseTax2.toString(),
      total: document.price.toString(),
      discount: document.discount.toString(),
      cardNumber: document.memberNo ?? '',
    );

    _submitTask(receiptWidget, printer, PrintTypeEnum.receipt);

    return PrintJobResult(printer: printer);
  }

  Future<PrintJobResult> _printReceiptNative(
    PrintInfoDocument document,
    PrinterSettings printer,
  ) async {
    final nativePrinter = _nativeReceiptPrinter;
    if (nativePrinter == null) {
      return PrintJobResult(
        printer: printer,
        error: 'StarXpand native printer is not configured.',
      );
    }

    try {
      final receipt = SaleReceiptDocumentAdapter.fromPrintInfo(document);
      await nativePrinter.printReceipt(document: receipt, printer: printer);
      return PrintJobResult(printer: printer);
    } catch (error) {
      return PrintJobResult(printer: printer, error: error.toString());
    }
  }

  void _enqueueReceipt(
    PrintInfoDocument document,
    PrinterSettings printer, {
    bool forceContinuous = false,
  }) {
    final info = document.printInfo;
    if (info == null) return;
    final rotate = printer.direction;
    final isTakeOut = info.orderType != 'Shop_In';
    final mappedLines = _linesFromMap(info);
    final items = _toLegacyItems(mappedLines);
    if (items.isEmpty) return;

    if (printer.continuous || forceContinuous) {
      final printWidget = _renderer.buildContinuousReceipt(
        info: info,
        items: items,
        printer: printer,
        rotate: rotate,
        isTakeOut: isTakeOut,
      );
      _submitTask(printWidget, printer, PrintTypeEnum.receipt);
    } else {
      for (final item in items) {
        final printWidget = _renderer.buildSingleReceipt(
          info: info,
          item: item,
          printer: printer,
          rotate: rotate,
          isTakeOut: isTakeOut,
        );
        _submitTask(printWidget, printer, PrintTypeEnum.receipt);
      }
    }
  }

  List<Map<String, dynamic>> _toLegacyItems(List<PrintOrderLine> lines) {
    return lines
        .map(
          (line) => {
            'qty': line.qty,
            'name': line.name,
            'price': line.price,
            'options': _toLegacyOptions(line.options),
            'categoryName': line.categoryName,
          },
        )
        .toList(growable: false);
  }

  Map<String, List<Map<String, dynamic>>> _toLegacyOptions(
    Map<String, List<PrintOrderOption>> options,
  ) {
    return options.map((key, value) {
      final opts = value
          .map((opt) => {'name': opt.name, 'qty': opt.qty})
          .toList(growable: false);
      return MapEntry(key, opts);
    });
  }

  // void _enqueueReceipt(PrintInfoDocument document, PrinterSettings printer, {bool isCenterPrint = false}) {
  //   final info = document.printInfo;
  //   if (info == null || info.orderLines.isEmpty) return;
  //   final widget = _renderer.buildReceipt(
  //     document: document,
  //     printer: printer,
  //     isTakeOut: info.orderType != 'Shop_In',
  //     rotate: printer.direction,
  //     continuous: printer.continuous,
  //     isCenterPrint: isCenterPrint,
  //   );
  //   _submitTask(widget, printer, PrintTypeEnum.receipt);
  // }

  void _enqueueLabelTickets(
    PrintInfoDocument document,
    PrinterSettings printer,
  ) {
    final info = document.printInfo;
    if (info == null) return;
    final rotate = printer.direction;
    final queue = <ATempWidget>[];
    if (info.orderType != 'Shop_In') {
      final head = _renderer.buildLabelHead(
        document: document,
        printer: printer,
        rotate: rotate,
      );
      if (head != null) queue.add(head);
      //_submitTask(head, printer, PrintTypeEnum.label);
    }
    final widgets = _renderer.buildLabels(
      document: document,
      printer: printer,
      rotate: rotate,
    );
    for (final widget in widgets) {
      queue.add(widget);
      //_submitTask(widget, printer, PrintTypeEnum.label);
    }
    for (final widget in queue) {
      _submitTask(widget, printer, PrintTypeEnum.label);
    }
  }

  void _submitTask(
    ATempWidget widget,
    PrinterSettings printer,
    PrintTypeEnum type,
  ) {
    final ip = printer.printIp;
    if (ip == null || ip.isEmpty) return;
    PictureGeneratorProvider.instance.addPicGeneratorTask(
      PicGenerateTask<PrinterInfo>(
        tempWidget: widget,
        printTypeEnum: type,
        params: PrinterInfo.fromIp(ip),
      ),
    );
  }

  bool _isReceiptPrinterAvailable(PrinterSettings printer) {
    if (!printer.isOn) {
      return false;
    }
    if (printer.usesNativeSdk) {
      return _hasNativeTarget(printer);
    }
    return _isWidgetPrinterAvailable(printer);
  }

  bool _isWidgetPrinterAvailable(PrinterSettings printer) {
    final ip = printer.printIp?.trim();
    return printer.isOn && ip != null && ip.isNotEmpty;
  }

  bool _hasNativeTarget(PrinterSettings printer) {
    if (printer.connectionType == PrinterConnectionType.network) {
      final host = printer.printIp?.trim();
      return host != null && host.isNotEmpty;
    }

    final identifier = printer.deviceIdentifier?.trim();
    return identifier != null && identifier.isNotEmpty;
  }
}

PrintInfoDocument _documentForLines(
  PrintInfoDocument base,
  List<PrintOrderLine> lines,
  int type,
) {
  final info = base.printInfo;
  final updatedInfo = (info ?? const PrintTicketInfo()).copyWith(
    orderLines: lines,
    orderLinesMap: {type.toString(): lines},
  );
  return base.copyWith(printInfo: updatedInfo);
}

List<PrintOrderLine> _linesFromMap(PrintTicketInfo info) {
  return info.orderLinesMap.values.expand((e) => e).toList(growable: false);
}
