import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/services/print_service.dart';
import 'package:shop_staff/domain/services/receipt_renderer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class PrintServiceImpl implements PrintService {
  PrintServiceImpl({required ReceiptRenderer renderer}) : _renderer = renderer;

  final ReceiptRenderer _renderer;

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

    for (final entry in info.orderLinesMap.entries) {
      final typeKey = int.tryParse(entry.key);
      if (typeKey == null) continue;
      final printer = printers.firstWhere(
        (p) => p.type == typeKey && p.isOn && (p.printIp?.isNotEmpty ?? false),
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

    // Center consolidated receipt (type 11) when enabled and takeout
    final centerPrinter = printers.firstWhere(
      (p) => p.type == 11 && p.isOn && (p.printIp?.isNotEmpty ?? false),
      orElse: () => const PrinterSettings(name: '', type: -1),
    );

    if (centerPrinter.type == 11 && isTakeOut) {
      _enqueueReceipt(document, centerPrinter, forceContinuous: true);
      results.add(PrintJobResult(printer: centerPrinter));
    }

    return results;
  }

    void _enqueueReceipt(PrintInfoDocument document, PrinterSettings printer, {bool forceContinuous = false}) {
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
      .map((line) => {
            'qty': line.qty,
            'name': line.name,
            'options': _toLegacyOptions(line.options),
            'categoryName': line.categoryName,
          })
      .toList(growable: false);
}

Map<String, List<Map<String, dynamic>>> _toLegacyOptions(
  Map<String, List<PrintOrderOption>> options,
) {
  return options.map((key, value) {
    final opts = value
        .map((opt) => {
              'name': opt.name,
              'qty': opt.qty,
            })
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

  void _enqueueLabelTickets(PrintInfoDocument document, PrinterSettings printer) {
    final info = document.printInfo;
    if (info == null) return;
    final rotate = printer.direction;
    final queue = <ATempWidget>[];
    if (info.orderType != 'Shop_In') {
      final head = _renderer.buildLabelHead(document: document, printer: printer, rotate: rotate);
      if (head != null) queue.add(head);
      //_submitTask(head, printer, PrintTypeEnum.label);
    }
    final widgets = _renderer.buildLabels(document: document, printer: printer, rotate: rotate);
    for (final widget in widgets) {
      queue.add(widget);
      //_submitTask(widget, printer, PrintTypeEnum.label);
    }
    for (final widget in queue) {
      _submitTask(widget, printer, PrintTypeEnum.label);
    }
  }

  void _submitTask(ATempWidget widget, PrinterSettings printer, PrintTypeEnum type) {
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
}

PrintInfoDocument _documentForLines(PrintInfoDocument base, List<PrintOrderLine> lines, int type) {
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