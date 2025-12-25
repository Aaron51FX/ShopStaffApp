import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/services/print_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class PrintServiceImpl implements PrintService {
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

    return results;
  }

  void _enqueueReceipt(PrintInfoDocument document, PrinterSettings printer) {
    final info = document.printInfo;
    if (info == null) return;
    final rotate = printer.direction;
    final isTakeOut = info.orderType != 'Shop_In';
    final items = _toLegacyItems(info.orderLines);
    if (items.isEmpty) return;

    if (printer.continuous) {
      _printContinuous(
        info: info,
        items: items,
        printer: printer,
        rotate: rotate,
        isTakeOut: isTakeOut,
      );
    } else {
      _printSingle(
        info: info,
        items: items,
        printer: printer,
        rotate: rotate,
        isTakeOut: isTakeOut,
      );
    }
  }

  void _enqueueLabelTickets(PrintInfoDocument document, PrinterSettings printer) {
    final size = _ticketSize(printer.labelSize, true);
    final info = document.printInfo;
    if (info == null) return;
    final lines = _expandLinesForLabels(document);
    if (lines.isEmpty) return;

    final rotate = printer.direction;
    final isTakeOut = info.orderType != 'Shop_In';
    final fromPlate = info.fromPlate;
    final orderSnCode = info.orderSnCode;
    final orderTime = info.orderTime;
    final remark = info.remark;
    final timeTag = '${document.orderId}#${DateTime.now().toString().substring(5, 16)}';
    final totalQty = lines.fold<int>(0, (prev, e) => prev + (e.qty <= 0 ? 1 : e.qty));
    var itemCount = 0;

    final queue = <Widget>[];

    for (final line in lines) {
      final qty = line.qty <= 0 ? 1 : line.qty;
      final options = _toLegacyOptions(line.options);
      for (var i = 0; i < qty; i++) {
        itemCount += 1;
        queue.add(
          labelItem(
            line.name,
            orderSnCode,
            options,
            size.$1.toDouble(),
            size.$2.toDouble(),
            _labelMaxLine(size.$2),
            rotate,
            '$totalQty-$itemCount',
            timeTag,
          ),
        );
      }
    }

    if (isTakeOut) {
      queue.insert(
        0,
        headReceiptWidget(
          fromPlate,
          orderSnCode,
          orderTime,
          itemCount,
          remark,
          size.$1.toDouble(),
          size.$2.toDouble(),
          timeTag,
          rotate,
        ),
      );
    }

    for (final widget in queue) {
      PictureGeneratorProvider.instance.addPicGeneratorTask(
        PicGenerateTask<PrinterInfo>(
          tempWidget: widget as ATempWidget,
          printTypeEnum: PrintTypeEnum.label,
          params: PrinterInfo.fromIp(printer.printIp!),
        ),
      );
    }
  }

  /// Returns (width, height) in pixels. Height of -1 lets generator auto-size.
  (int, int) _ticketSize(String raw, bool isLabel) {
    if (!isLabel) return (550, -1); // default receipt width
    if (raw.isEmpty) return (384, 232); // fallback label size
    final parts = raw.toLowerCase().split('x');
    if (parts.length != 2) return (450, 300);
    final width = int.tryParse(parts[0]) ?? 450;
    final height = int.tryParse(parts[1]) ?? 300;
    return (width, height);
  }
}

/// Legacy receipt/label helpers migrated from print_service_old for layout parity.
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

int _labelMaxLine(int height) {
  if (height <= 0) return 2;
  // Mirror legacy heuristic: assume line height ~ 225 * 0.25.
  return (height / (225 * 0.25)).floor();
}

void _printContinuous({
  required PrintTicketInfo info,
  required List<Map<String, dynamic>> items,
  required PrinterSettings printer,
  required bool rotate,
  required bool isTakeOut,
}) {
  final widget = ReceiptConstrainedBox(
    Transform(
      transform: Matrix4.rotationZ(rotate ? pi : 0.0),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          receiptTitle(
            info.orderSnCode,
            info.orderTime,
            info.fromPlate,
            isTakeOut: isTakeOut,
            continuous: true,
            isCenterPrint: false,
          ),
          ...items.map((item) {
            return menuItem(
              item['name'] as String? ?? '',
              item['qty'] as int? ?? 1,
              item['options'] as Map<String, List<Map<String, dynamic>>>,
              isUnderLine: true,
              needOption: printer.option,
              isContinuous: true,
              categoryName: item['categoryName'] as String? ?? '',
            );
          }),
          Container(
            alignment: Alignment.centerRight,
            child: Text(
              info.orderTime,
              style: const TextStyle(fontSize: 45),
            ),
          ),
          if (info.remark.isNotEmpty) remarkTitle(info.remark),
          if (info.paymentCode.isNotEmpty)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'お会計について、QRコードを精算機にかざしていただき、お支払いくださいますようお願い申し上げます。\nご不明な点がございましたら、恐れ入りますがスタッフまでお声がけくださいませ。',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: BarcodeWidget(
                    height: 200,
                    width: 200,
                    barcode: Barcode.qrCode(),
                    data: info.paymentCode,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  PictureGeneratorProvider.instance.addPicGeneratorTask(
    PicGenerateTask<PrinterInfo>(
      tempWidget: widget,
      printTypeEnum: PrintTypeEnum.receipt,
      params: PrinterInfo.fromIp(printer.printIp!),
    ),
  );
}

void _printSingle({
  required PrintTicketInfo info,
  required List<Map<String, dynamic>> items,
  required PrinterSettings printer,
  required bool rotate,
  required bool isTakeOut,
}) {
  for (final item in items) {
    final widget = ReceiptConstrainedBox(
      Transform(
        transform: Matrix4.rotationZ(rotate ? pi : 0.0),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            receiptTitle(
              info.orderSnCode,
              info.orderTime,
              info.fromPlate,
              isTakeOut: isTakeOut,
              categoryName: printer.option ? (item['categoryName'] as String? ?? '') : '',
            ),
            menuItem(
              item['name'] as String? ?? '',
              item['qty'] as int? ?? 1,
              item['options'] as Map<String, List<Map<String, dynamic>>>,
              categoryName: printer.option ? (item['categoryName'] as String? ?? '') : '',
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Text(
                info.orderTime,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ],
        ),
      ),
    );

    PictureGeneratorProvider.instance.addPicGeneratorTask(
      PicGenerateTask<PrinterInfo>(
        tempWidget: widget,
        printTypeEnum: PrintTypeEnum.receipt,
        params: PrinterInfo.fromIp(printer.printIp!),
      ),
    );
  }
}

Widget labelItem(
  String name,
  String number,
  Map<String, List<Map<String, dynamic>>> options,
  double printWidth,
  double printHeight,
  int maxLines,
  bool rotate,
  String index,
  String time,
) {
  return LabelConstrainedBox(
    Transform(
      transform: Matrix4.rotationZ(rotate ? pi : 0.0),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.only(right: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      name,
                      maxLines: 2,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 23,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            ' # $number',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: AutoSizeText(
                            index,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.black, thickness: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.only(top: 5, left: 10),
                      width: double.infinity,
                      child: optionList(options, maxLines),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.only(top: 5),
                      child: Text(
                        time,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    pagerWidth: printWidth,
    pagerHeight: printHeight,
  );
}

Widget headReceiptWidget(
  String fromPlate,
  String orderSnCode,
  String orderTime,
  int itemCount,
  String remark,
  double printWidth,
  double printHeight,
  String time,
  bool rotate,
) {
  return LabelConstrainedBox(
    Transform(
      transform: Matrix4.rotationZ(rotate ? pi : 0.0),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.only(right: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AutoSizeText(
                      fromPlate,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 50,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            ' # $orderSnCode',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: AutoSizeText(
                            '$itemCount',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.black, thickness: 2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AutoSizeText(
                    remark,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.only(top: 5),
                    child: Text(
                      time,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    pagerWidth: printWidth,
    pagerHeight: printHeight,
  );
}

Widget optionList(Map<String, List<Map<String, dynamic>>> options, int maxLines) {
  if (options.isEmpty) return Container();

  final optionStrings = options.entries.map((entry) {
    final optionName = entry.key;
    final optionValues = entry.value;
    return optionItem(optionName, optionValues);
  }).join('、');

  return AutoSizeText(
    optionStrings,
    maxLines: maxLines,
    style: const TextStyle(
      fontSize: 28,
      color: Colors.black,
    ),
    overflow: TextOverflow.ellipsis,
  );
}

String optionItem(String optionName, List<Map<String, dynamic>> optionValues) {
  return "$optionName: " +
      optionValues.map((option) {
        final optionDetail = option['name']?.toString() ?? '';
        final optionQty = option['qty'] as int? ?? 1;
        final optionQtyString = optionQty == 1 ? '' : 'x $optionQty';
        return "$optionDetail $optionQtyString";
      }).join(', ');
}

Widget receiptTitle(
  String title,
  String orderTime,
  String fromPlate, {
  bool isTakeOut = false,
  bool continuous = false,
  bool isCenterPrint = false,
  String categoryName = '',
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: continuous ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isTakeOut && !isCenterPrint)
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 50,
                    color: Colors.black,
                  ),
                if (isTakeOut && isCenterPrint)
                  Text(
                    '$fromPlate # ',
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            if (categoryName.isNotEmpty)
              AutoSizeText(
                '[$categoryName]',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
              ),
          ],
        ),
        if (!continuous)
          const Divider(
            color: Colors.black,
            thickness: 1,
          ),
      ],
    ),
  );
}

Widget menuItem(
  String title,
  int qty,
  Map<String, List<Map<String, dynamic>>> option, {
  bool isUnderLine = false,
  bool needOption = true,
  bool isContinuous = false,
  String? categoryName,
}) {
  final optionQtyString = qty == 1 ? '' : 'x $qty';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryName != null && categoryName.isNotEmpty && isContinuous)
          Text(
            '【$categoryName】',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              optionQtyString,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.black,
              ),
            ),
          ],
        ),
        if (option.isNotEmpty && needOption)
          ...option.entries.map((entry) {
            final optionName = entry.key;
            final optionValues = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '  $optionName',
                      style: const TextStyle(fontSize: 36),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: optionValues.map((option) {
                          final optionDetail = option['name']?.toString() ?? '';
                          final optionQty = option['qty'] as int? ?? 1;
                          final optionQtyString = optionQty == 1 ? '' : 'x $optionQty';
                          return Text(
                            '    $optionDetail $optionQtyString',
                            maxLines: 3,
                            style: const TextStyle(fontSize: 36),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
        if (isUnderLine)
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: 1.5,
            color: Colors.black,
            width: double.infinity,
          ),
      ],
    ),
  );
}

Widget remarkTitle(String content) {
  return Text(
    content,
    style: const TextStyle(
      fontSize: 32,
      color: Colors.black,
    ),
  );
}

PrintInfoDocument _documentForLines(PrintInfoDocument base, List<PrintOrderLine> lines, int type) {
  final info = base.printInfo;
  final updatedInfo = (info ?? const PrintTicketInfo()).copyWith(
    orderLines: lines,
    orderLinesMap: {type.toString(): lines},
  );
  return base.copyWith(printInfo: updatedInfo);
}

class ReceiptConstrainedBox extends StatelessWidget with ATempWidget {
  const ReceiptConstrainedBox(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: 550.w,
      child: child,
    );
  }

  @override
  int get pixelPagerWidth => 550;

  @override
  double get pixelRatio => 1 / 1.w;
}

class LabelConstrainedBox extends StatelessWidget with ATempWidget {
  const LabelConstrainedBox(
    this.child, {
    super.key,
    this.pagerWidth = 384,
    this.pagerHeight = 232,
  });

  final Widget child;
  final double pagerWidth;
  final double pagerHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: ScreenUtil().setWidth(pagerWidth),
      height: pagerHeight.w,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        child: child,
      ),
    );
  }

  @override
  int get pixelPagerWidth => pagerWidth.toInt();

  @override
  int get pixelPagerHeight => pagerHeight.toInt();

  @override
  double get pixelRatio => 1 / 1.w;
}

List<PrintOrderLine> _expandLinesForLabels(PrintInfoDocument document) {
  final info = document.printInfo;
  if (info == null) return const <PrintOrderLine>[];
  final source = info.orderLines.isNotEmpty
      ? info.orderLines
      : info.orderLinesMap.values.expand((e) => e).toList();
  final expanded = <PrintOrderLine>[];
  for (final line in source) {
    final qty = line.qty <= 0 ? 1 : line.qty;
    for (var i = 0; i < qty; i++) {
      expanded.add(line.copyWith(qty: 1));
    }
  }
  return expanded;
}

class TicketCanvas extends StatelessWidget with ATempWidget {
  const TicketCanvas({
    super.key,
    required this.pageWidth,
    required this.child,
    this.pageHeight,
  });

  final int pageWidth;
  final int? pageHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: pageWidth.toDouble(),
      height: pageHeight == null || pageHeight == -1 ? null : pageHeight!.toDouble(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black, fontSize: 18),
        child: child,
      ),
    );
  }

  @override
  int get pixelPagerWidth => pageWidth;

  @override
  int get pixelPagerHeight => pageHeight ?? -1;

  @override
  double get pixelRatio => 1;
}

class TicketBody extends StatelessWidget {
  const TicketBody({super.key, required this.document, required this.isLabel});

  final PrintInfoDocument document;
  final bool isLabel;

  @override
  Widget build(BuildContext context) {
    final info = document.printInfo;
    final lines = info?.orderLines ?? const <PrintOrderLine>[];
    final orderLabel = document.order.isNotEmpty
        ? document.order
        : (document.serialNumber ?? document.serialNo ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document.shopName.isNotEmpty ? document.shopName : 'ORDER',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        const SizedBox(height: 4),
        if (document.serialNumber?.isNotEmpty == true)
          Text('No. ${document.serialNumber}'),
        if (orderLabel.isNotEmpty) Text('订单号: $orderLabel'),
        if (document.orderDate.isNotEmpty) Text(document.orderDate),
        const SizedBox(height: 12),
        ...lines.map((line) => _LineRow(line: line)),
        const Divider(height: 20, thickness: 1),
        _kv('数量', lines.fold<int>(0, (p, e) => p + e.qty).toString()),
        _kv('金额', '¥${document.price}'),
        _kv('税金', '¥${document.tax}'),
        _kv('合计', '¥${document.payPrice}'),
        if (document.change > 0) _kv('找零', '¥${document.change}'),
        if (document.discount > 0) _kv('折扣', '-¥${document.discount}'),
        if (isLabel) ...[
          const SizedBox(height: 8),
          Text('LABEL', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k), Text(v)],
      ),
    );
  }
}

/// 收据版式，参考旧版 print_service_old 结构，但使用系统字体简化。
class ReceiptBody extends StatelessWidget {
  const ReceiptBody({super.key, required this.document});

  final PrintInfoDocument document;

  @override
  Widget build(BuildContext context) {
    final info = document.printInfo;
    final lines = info?.orderLines ?? const <PrintOrderLine>[];
    final orderLabel = document.serialNumberText?.isNotEmpty == true
        ? document.serialNumberText!
        : (document.order.isNotEmpty ? document.order : (document.serialNumber ?? document.serialNo ?? ''));
    final totalQty = lines.fold<int>(0, (p, e) => p + e.qty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(document.shopName.isNotEmpty ? document.shopName : 'SHOP',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        if (document.address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(document.address, style: const TextStyle(fontSize: 14)),
        ],
        if (document.telNo.isNotEmpty) Text('TEL: ${document.telNo}', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('订单: $orderLabel', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (document.orderDate.isNotEmpty) Text(document.orderDate),
          ],
        ),
        if (document.orderTime.isNotEmpty) Text('下单时间: ${document.orderTime}'),
        if (document.memberNo != null && document.memberNo!.isNotEmpty)
          Text('会员: ${document.memberNo}'),
        if (info?.orderType.isNotEmpty == true) Text('类型: ${info!.orderType}'),
        if (document.payMethod.isNotEmpty) Text('支付: ${document.payMethod}'),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 6),
        ...lines.map((line) => _ReceiptLine(line: line)),
        const Divider(height: 18, thickness: 1),
        _kv('数量', '$totalQty'),
        _kv('原价', '¥${document.originalPrice}'),
        if (document.discount > 0) _kv('折扣', '-¥${document.discount}'),
        _kv('小计', '¥${document.price}'),
        if (document.tax > 0) _kv('税金', '¥${document.tax}'),
        _kv('应付', '¥${document.payPrice}', bold: true),
        if (document.change > 0) _kv('找零', '¥${document.change}'),
        if (info?.remark.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text('备注: ${info!.remark}'),
        ],
      ],
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.line});

  final PrintOrderLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text('x${line.qty}'),
              const SizedBox(width: 8),
              Text('¥${line.price}'),
            ],
          ),
          if (line.options.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...line.options.entries.map((entry) {
              final opts = entry.value;
              final optionText = opts
                  .map((o) => '${o.name}${o.price != null ? ' +¥${o.price}' : ''}${o.qty > 1 ? ' x${o.qty}' : ''}')
                  .join('，');
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text('• ${entry.key}: $optionText', style: const TextStyle(fontSize: 14)),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// 标签版式：每个菜品一张小票。
class LabelBody extends StatelessWidget {
  const LabelBody({
    super.key,
    required this.document,
    required this.line,
    required this.pageWidth,
    required this.pageHeight,
  });

  final PrintInfoDocument document;
  final PrintOrderLine line;
  final int pageWidth;
  final int pageHeight;

  @override
  Widget build(BuildContext context) {
    final orderLabel = document.serialNumberText?.isNotEmpty == true
        ? document.serialNumberText!
        : (document.order.isNotEmpty ? document.order : (document.serialNumber ?? document.serialNo ?? ''));
    final optionsText = line.options.entries
        .map((e) => '${e.key}: ${e.value.map((o) => o.name).join('、')}')
        .join('  ');

    return Container(
      width: pageWidth.toDouble(),
      height: pageHeight > 0 ? pageHeight.toDouble() : null,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orderLabel.isNotEmpty ? orderLabel : 'ORDER',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (document.orderTime.isNotEmpty) Text(document.orderTime, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('数量: ${line.qty}', style: const TextStyle(fontSize: 16)),
              if (optionsText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(optionsText, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final PrintOrderLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('x${line.qty}'),
              Text('¥${line.price}'),
            ],
          ),
          if (line.options.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...line.options.entries.map((entry) {
              final opts = entry.value;
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: opts
                      .map((o) => Text('• ${o.name}${o.price != null ? ' +¥${o.price}' : ''}${o.qty > 1 ? ' x${o.qty}' : ''}', style: const TextStyle(fontSize: 16)))
                      .toList(),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}