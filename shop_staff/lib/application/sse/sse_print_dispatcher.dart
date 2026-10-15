import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/services/receipt_renderer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class SsePrintTask {
  SsePrintTask(this.widget, this.printer, this.type);
  final ATempWidget widget;
  final PrinterSettings printer;
  final PrintTypeEnum type;
}

/// Build first, claim on the server second, submit last.
class SsePrintDispatcher {
  const SsePrintDispatcher(this.renderer);
  final ReceiptRenderer renderer;

  List<SsePrintTask> prepare(
    String event,
    Map<String, dynamic> data,
    List<PrinterSettings> printers, {
    bool center = false,
    bool seat = false,
  }) {
    final available = printers
        .where(
          (p) =>
              p.isOn &&
              !p.usesNativeSdk &&
              (p.printIp?.trim().isNotEmpty ?? false),
        )
        .toList();
    if (event == 'print' || event == 'expiryPrint') {
      if (event == 'print' && !seat) return [];
      final target = event == 'print' ? 11 : 10;
      final matches = available.where((p) => p.type == target).toList();
      if (matches.isEmpty) throw StateError('未配置可用打印机: $target');
      final printer = matches.first;
      if (event == 'expiryPrint' && printer.receipt) {
        throw StateError('效期打印机 (10) 需要设置为标签模式');
      }
      final size = printer.labelSize.split('x').map(int.tryParse).toList();
      final width = event == 'print'
          ? (printer.receiptPaperWidthMm == 58 ? 384 : 576)
          : (size.length == 2 ? size[0] : null);
      final height = event == 'print'
          ? null
          : (size.length == 2 ? size[1] : null);
      if (width == null ||
          width <= 0 ||
          (event == 'expiryPrint' && (height == null || height <= 0))) {
        throw StateError('请设置标签纸尺寸');
      }
      final lines = event == 'print'
          ? ['line1', 'line2', 'description']
          : [
              'name',
              'saveMethod',
              'expiredTimeStr',
              'printTimeStr',
              'operatorName',
            ];
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final key in lines)
            Text(
              '${data[key] ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: key == lines.first ? 28 : 20,
                color: Colors.black,
              ),
            ),
          if (event == 'print' &&
              (data['qrCode']?.toString().isNotEmpty ?? false))
            BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: data['qrCode'].toString(),
              width: 180,
              height: 180,
            ),
        ],
      );
      return [
        SsePrintTask(
          _SseTicket(width, height, printer.direction, content),
          printer,
          event == 'print' ? PrintTypeEnum.receipt : PrintTypeEnum.label,
        ),
      ];
    }
    if (event != 'message' && event != 'rePrint') {
      throw UnsupportedError('暂不支持事件: $event');
    }
    final info = PrintTicketInfo.fromJson(data);
    if (info.orderLinesMap.isEmpty) {
      throw const FormatException('orderLinesMap 为空');
    }
    final tasks = <SsePrintTask>[];
    final all = <PrintOrderLine>[];
    for (final entry in info.orderLinesMap.entries) {
      if (entry.value.isEmpty) continue;
      all.addAll(entry.value);
      final matches = available
          .where((p) => p.type.toString() == entry.key)
          .toList();
      if (matches.isEmpty) throw StateError('未配置可用打印机: ${entry.key}');
      final printer = matches.first;
      final document = PrintInfoDocument(
        serialNumber: info.orderSnCode,
        orderTime: info.orderTime,
        printInfo: info.copyWith(
          orderLines: entry.value,
          orderLinesMap: {entry.key: entry.value},
        ),
      );
      if (!printer.receipt) {
        final size = printer.labelSize.split('x').map(int.tryParse).toList();
        if (size.length != 2 || size.any((v) => v == null || v <= 0)) {
          throw StateError('请设置标签纸尺寸: ${printer.name}');
        }
        final head = info.orderType == 'Shop_In'
            ? null
            : renderer.buildLabelHead(
                document: document,
                printer: printer,
                rotate: printer.direction,
              );
        if (head != null) {
          tasks.add(SsePrintTask(head, printer, PrintTypeEnum.label));
        }
        for (final widget in renderer.buildLabels(
          document: document,
          printer: printer,
          rotate: printer.direction,
        )) {
          tasks.add(SsePrintTask(widget, printer, PrintTypeEnum.label));
        }
      } else {
        final items = _items(entry.value);
        if (printer.continuous) {
          tasks.add(
            SsePrintTask(
              renderer.buildContinuousReceipt(
                info: info,
                items: items,
                printer: printer,
                rotate: printer.direction,
                isTakeOut: info.orderType != 'Shop_In',
              ),
              printer,
              PrintTypeEnum.receipt,
            ),
          );
        } else {
          for (final item in items) {
            tasks.add(
              SsePrintTask(
                renderer.buildSingleReceipt(
                  info: info,
                  item: item,
                  printer: printer,
                  rotate: printer.direction,
                  isTakeOut: info.orderType != 'Shop_In',
                ),
                printer,
                PrintTypeEnum.receipt,
              ),
            );
          }
        }
      }
    }
    if (center && info.orderType != 'Shop_In' && all.isNotEmpty) {
      final matches = available.where((p) => p.type == 11).toList();
      if (matches.isEmpty) throw StateError('未配置中央打印机 (11)');
      final printer = matches.first;
      tasks.add(
        SsePrintTask(
          renderer.buildContinuousReceipt(
            info: info,
            items: _items(all),
            printer: printer,
            isTakeOut: true,
            rotate: printer.direction,
            isCenterPrint: true,
          ),
          printer,
          PrintTypeEnum.receipt,
        ),
      );
    }
    if (tasks.isEmpty) throw StateError('没有可打印内容');
    return tasks;
  }

  List<Map<String, dynamic>> _items(List<PrintOrderLine> lines) => lines
      .map(
        (line) => <String, dynamic>{
          'name': line.name,
          'qty': line.qty,
          'price': line.price,
          'categoryName': line.categoryName,
          'bizId': line.bizId,
          'options': line.options.map(
            (key, values) => MapEntry(
              key,
              values
                  .map((v) => <String, dynamic>{'name': v.name, 'qty': v.qty})
                  .toList(),
            ),
          ),
        },
      )
      .toList();

  Future<void> submit(SsePrintTask task) async {
    final completion = Completer<void>();
    // Attach the error listener before the image generator can complete.
    final done = completion.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        final error = TimeoutException('Print generation or transport timeout');
        if (!completion.isCompleted) completion.completeError(error);
        throw error;
      },
    );
    PictureGeneratorProvider.instance.addPicGeneratorTask(
      PicGenerateTask<PrinterInfo>(
        tempWidget: task.widget,
        printTypeEnum: task.type,
        params: PrinterInfo(
          ip: task.printer.printIp,
          port: int.tryParse(task.printer.printPort ?? '') ?? 9100,
          completion: completion,
        ),
      ),
    );
    await done;
  }
}

class _SseTicket extends StatelessWidget with ATempWidget {
  const _SseTicket(this.width, this.height, this.rotate, this.content);
  final int width;
  final int? height;
  final bool rotate;
  final Widget content;
  @override
  int get pixelPagerWidth => width;
  @override
  int get pixelPagerHeight => height ?? -1;
  @override
  double get pixelRatio => 1;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    width: width.toDouble(),
    height: height?.toDouble(),
    padding: const EdgeInsets.all(8),
    child: RotatedBox(
      quarterTurns: rotate ? 2 : 0,
      child: height == null
          ? content
          : FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(width: width - 16.0, child: content),
            ),
    ),
  );
}
