import 'package:flutter/material.dart';
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
    if (printers.isEmpty) return results;

    for (final printer in printers.where((p) => p.isOn)) {
      if (printer.printIp == null || printer.printIp!.isEmpty) {
        results.add(PrintJobResult(printer: printer, error: '缺少打印机 IP'));
        continue;
      }

      final isLabel = printer.receipt == false;
      final size = _ticketSize(printer.labelSize, isLabel);
      final canvas = TicketCanvas(
        pageWidth: size.$1,
        pageHeight: size.$2,
        child: TicketBody(document: document, isLabel: isLabel),
      );
      debugPrint('Enqueuing print job for printer ${printer.name} (IP: ${printer.printIp}), isLabel: $isLabel');

      PictureGeneratorProvider.instance.addPicGeneratorTask(
        PicGenerateTask<PrinterInfo>(
          tempWidget: canvas,
          printTypeEnum: isLabel ? PrintTypeEnum.label : PrintTypeEnum.receipt,
          params: PrinterInfo.fromIp(printer.printIp!),
        ),
      );

      results.add(PrintJobResult(printer: printer));
    }

    return results;
  }

  /// Returns (width, height) in pixels. Height of -1 lets generator auto-size.
  (int, int) _ticketSize(String raw, bool isLabel) {
    if (!isLabel) return (550, -1); // default 80mm receipt
    if (raw.isEmpty) return (450, 300); // fallback label size
    final parts = raw.toLowerCase().split('x');
    if (parts.length != 2) return (450, 300);
    final width = int.tryParse(parts[0]) ?? 450;
    final height = int.tryParse(parts[1]) ?? 300;
    return (width, height);
  }
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