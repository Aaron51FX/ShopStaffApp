import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/services/receipt_document_adapters.dart';
import 'package:shop_staff/domain/entities/receipt_document.dart';
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
    bool includeKitchenJobs = true,
    bool includeOrderTicket = true,
    String? logoImageBase64,
  }) async {
    final results = <PrintJobResult>[];
    final info = document.printInfo;
    if (info == null || printers.isEmpty) {
      return results;
    }

    _logPrintFlow(
      document: document,
      printers: printers,
      includeKitchenJobs: includeKitchenJobs,
      includeOrderTicket: includeOrderTicket,
      hasLogoImage: logoImageBase64?.trim().isNotEmpty ?? false,
    );

    final isTakeOut = info.orderType != 'Shop_In';

    if (info.orderLines.isNotEmpty) {
      final receiptPrinter = _pickLocalDefaultReceiptPrinter(printers);
      if (receiptPrinter != null) {
        final result = await _printReceipt(
          document,
          receiptPrinter,
          includeOrderTicket: includeOrderTicket,
          logoImageBase64: logoImageBase64,
        );
        if (result != null) {
          results.add(result);
        }
      }
    }

    if (includeKitchenJobs && info.orderLinesMap.isNotEmpty) {
      results.addAll(
        await enqueueKitchenJobs(document: document, printers: printers),
      );
    }

    // Center consolidated receipt (type 11) when enabled and takeout
    final centerPrinter = printers.firstWhere(
      (p) => p.type == 11 && _isWidgetPrinterAvailable(p),
      orElse: () => const PrinterSettings(name: '', type: -1),
    );

    if (includeKitchenJobs &&
        info.orderLines.isNotEmpty &&
        centerPrinter.type == 11 &&
        isTakeOut) {
      final centerDocument = _documentForLines(
        document,
        info.orderLines,
        PrinterSettings.centerType,
      );
      _enqueueReceipt(centerDocument, centerPrinter, forceContinuous: true);
      results.add(PrintJobResult(printer: centerPrinter));
    }

    return results;
  }

  @override
  Future<List<PrintJobResult>> enqueueReceiptJobs({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
    String? logoImageBase64,
  }) async {
    final results = <PrintJobResult>[];
    final info = document.printInfo;
    if (info == null || info.orderLines.isEmpty || printers.isEmpty) {
      return results;
    }

    final printer = _pickLocalDefaultReceiptPrinter(printers);
    if (printer == null) return results;

    final result = await _printReceipt(
      document,
      printer,
      includeOrderTicket: false,
      logoImageBase64: logoImageBase64,
    );
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

  PrinterSettings? _pickLocalDefaultReceiptPrinter(
    List<PrinterSettings> printers,
  ) {
    final localPrinters = printers
        .where(
          (printer) =>
              printer.type == PrinterSettings.localType &&
              printer.receipt &&
              _isReceiptPrinterAvailable(printer),
        )
        .toList(growable: false);
    if (localPrinters.isEmpty) return null;

    for (final printer in localPrinters) {
      if (printer.isDefault) return printer;
    }
    return localPrinters.first;
  }

  Future<PrintJobResult?> _printReceipt(
    PrintInfoDocument document,
    PrinterSettings printer, {
    bool includeOrderTicket = true,
    String? logoImageBase64,
  }) async {
    final info = document.printInfo;
    if (info == null) return null;

    if (printer.usesNativeSdk) {
      return _printReceiptNative(
        document,
        printer,
        includeOrderTicket: includeOrderTicket,
        logoImageBase64: logoImageBase64,
      );
    }

    final isTakeOut = document.takeOut;
    final items = _toLegacyItems(info.orderLines);
    if (items.isEmpty) return null;

    if (includeOrderTicket) {
      final hReceiptWidget = _renderer.buildHReceipt(
        number: document.serialNumber ?? '',
        items: items,
        timeStamp: document.orderDate,
      );
      _submitTask(
        hReceiptWidget,
        printer,
        PrintTypeEnum.receipt,
        jobKind: 'local_h_receipt',
        document: document,
        items: items,
      );
    }

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

    _submitTask(
      receiptWidget,
      printer,
      PrintTypeEnum.receipt,
      jobKind: 'local_customer_receipt',
      document: document,
      items: items,
    );

    return PrintJobResult(printer: printer);
  }

  Future<PrintJobResult> _printReceiptNative(
    PrintInfoDocument document,
    PrinterSettings printer, {
    required bool includeOrderTicket,
    String? logoImageBase64,
  }) async {
    final nativePrinter = _nativeReceiptPrinter;
    if (nativePrinter == null) {
      return PrintJobResult(
        printer: printer,
        error: 'StarXpand native printer is not configured.',
      );
    }

    try {
      final receipt = _withLogoImage(
        SaleReceiptDocumentAdapter.fromPrintInfo(document),
        logoImageBase64,
      );
      if (includeOrderTicket) {
        _logPrintTask(
          jobKind: 'local_h_receipt_native',
          printer: printer,
          document: document,
          items: _toLegacyItems(document.printInfo?.orderLines ?? const []),
        );
        await nativePrinter.printReceipt(
          document: _buildNativeOrderTicket(
            receipt,
            serialNumber: document.serialNumber ?? '',
          ),
          printer: printer,
        );
      }
      _logPrintTask(
        jobKind: 'local_customer_receipt_native',
        printer: printer,
        document: document,
        items: _toLegacyItems(document.printInfo?.orderLines ?? const []),
      );
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
    final kitchenInfo = info.copyWith(orderSnCode: document.serialNumber ?? '');
    final rotate = printer.direction;
    final isTakeOut = info.orderType != 'Shop_In';
    final mappedLines = _linesFromMap(info);
    final items = _toLegacyItems(mappedLines);
    if (items.isEmpty) return;

    if (printer.continuous || forceContinuous) {
      final printWidget = _renderer.buildContinuousReceipt(
        info: kitchenInfo,
        items: items,
        printer: printer,
        rotate: rotate,
        isTakeOut: isTakeOut,
      );
      _submitTask(
        printWidget,
        printer,
        PrintTypeEnum.receipt,
        jobKind: printer.type == PrinterSettings.centerType
            ? 'external_center_total'
            : 'external_kitchen_continuous',
        document: document,
        items: items,
      );
    } else {
      for (final item in items) {
        final printWidget = _renderer.buildSingleReceipt(
          info: kitchenInfo,
          item: item,
          printer: printer,
          rotate: rotate,
          isTakeOut: isTakeOut,
        );
        _submitTask(
          printWidget,
          printer,
          PrintTypeEnum.receipt,
          jobKind: 'external_kitchen_single',
          document: document,
          items: <Map<String, dynamic>>[item],
        );
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
    final hasHead =
        info.orderType != 'Shop_In' && queue.length > widgets.length;
    for (var index = 0; index < queue.length; index++) {
      _submitTask(
        queue[index],
        printer,
        PrintTypeEnum.label,
        jobKind: hasHead && index == 0
            ? 'external_label_head'
            : 'external_label',
        document: document,
        items: _toLegacyItems(info.orderLines),
      );
    }
  }

  void _submitTask(
    ATempWidget widget,
    PrinterSettings printer,
    PrintTypeEnum type, {
    required String jobKind,
    required PrintInfoDocument document,
    required List<Map<String, dynamic>> items,
  }) {
    final ip = printer.printIp;
    if (ip == null || ip.isEmpty) return;
    _logPrintTask(
      jobKind: jobKind,
      printer: printer,
      document: document,
      items: items,
    );
    PictureGeneratorProvider.instance.addPicGeneratorTask(
      PicGenerateTask<PrinterInfo>(
        tempWidget: widget,
        printTypeEnum: type,
        params: PrinterInfo.fromIp(ip),
      ),
    );
  }

  void _logPrintFlow({
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
    required bool includeKitchenJobs,
    required bool includeOrderTicket,
    required bool hasLogoImage,
  }) {
    final info = document.printInfo;
    _debugPrintJson('PRINT_FLOW', <String, dynamic>{
      'orderId': document.orderId,
      'order': document.order,
      'serialNumber': document.serialNumber ?? '',
      'includeKitchenJobs': includeKitchenJobs,
      'includeOrderTicket': includeOrderTicket,
      'hasLogoImage': hasLogoImage,
      'orderLinesCount': info?.orderLines.length ?? 0,
      'orderLinesMapCounts': <String, int>{
        for (final entry
            in info?.orderLinesMap.entries ??
                const Iterable<MapEntry<String, List<PrintOrderLine>>>.empty())
          entry.key: entry.value.length,
      },
      'printers': printers.map(_printerLogData).toList(growable: false),
    });
  }

  void _logPrintTask({
    required String jobKind,
    required PrinterSettings printer,
    required PrintInfoDocument document,
    required List<Map<String, dynamic>> items,
  }) {
    final info = document.printInfo;
    _debugPrintJson('PRINT_TASK', <String, dynamic>{
      'jobKind': jobKind,
      'printer': _printerLogData(printer),
      'order': <String, dynamic>{
        'orderId': document.orderId,
        'order': document.order,
        'serialNumber': document.serialNumber ?? '',
        'orderType': info?.orderType ?? '',
      },
      'source': <String, dynamic>{
        'orderLinesCount': info?.orderLines.length ?? 0,
        'orderLinesMapCounts': <String, int>{
          for (final entry
              in info?.orderLinesMap.entries ??
                  const Iterable<
                    MapEntry<String, List<PrintOrderLine>>
                  >.empty())
            entry.key: entry.value.length,
        },
      },
      'items': items,
    });
  }

  Map<String, dynamic> _printerLogData(PrinterSettings printer) {
    return <String, dynamic>{
      'name': printer.name,
      'type': printer.type,
      'receipt': printer.receipt,
      'isOn': printer.isOn,
      'isDefault': printer.isDefault,
      'backend': printer.backend.wireValue,
      'connectionType': printer.connectionType.wireValue,
      'printIp': printer.printIp ?? '',
      'printPort': printer.printPort ?? '',
      'deviceIdentifier': printer.deviceIdentifier ?? '',
      'continuous': printer.continuous,
    };
  }

  void _debugPrintJson(String tag, Map<String, dynamic> payload) {
    debugPrint(
      '[$tag]\n${const JsonEncoder.withIndent('  ').convert(payload)}',
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

ReceiptDocument _buildNativeOrderTicket(
  ReceiptDocument receipt, {
  required String serialNumber,
}) {
  final transaction = receipt.transaction;
  return ReceiptDocument(
    kind: receipt.kind,
    detailLevel: receipt.detailLevel,
    shop: receipt.shop,
    transaction: ReceiptTransactionInfo(
      receiptId: transaction.receiptId,
      orderId: transaction.orderId,
      displayOrderNo: serialNumber,
      serialNumber: serialNumber,
      occurredAt: transaction.occurredAt,
      businessDateLabel: transaction.businessDateLabel,
      orderMode: transaction.orderMode,
      machineCode: transaction.machineCode,
      locale: transaction.locale,
      currency: transaction.currency,
    ),
    originalTransaction: receipt.originalTransaction,
    lines: receipt.lines,
    totals: receipt.totals,
    payment: receipt.payment,
    refund: receipt.refund,
    extras: <String, dynamic>{...receipt.extras, 'documentType': 'h_receipt'},
  );
}

ReceiptDocument _withLogoImage(
  ReceiptDocument receipt,
  String? logoImageBase64,
) {
  final logo = logoImageBase64?.trim() ?? '';
  if (logo.isEmpty) return receipt;
  return ReceiptDocument(
    kind: receipt.kind,
    detailLevel: receipt.detailLevel,
    shop: receipt.shop,
    transaction: receipt.transaction,
    originalTransaction: receipt.originalTransaction,
    lines: receipt.lines,
    totals: receipt.totals,
    payment: receipt.payment,
    refund: receipt.refund,
    extras: <String, dynamic>{...receipt.extras, 'logoBase64': logo},
  );
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
