import 'dart:async';
import 'package:shop_staff/application/sse/sse_runtime.dart';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_printer_plus/flutter_printer_plus.dart' as printer_plus;
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';

/// Root view to anchor print instrumentation across the app.
class PrintRootView extends ConsumerStatefulWidget {
  const PrintRootView({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PrintRootView> createState() => _PrintRootViewState();
}

class _PrintRootViewState extends ConsumerState<PrintRootView> {
  final printerController = printer_plus.PrinterJobController(
    maxRetriesPerJob: 1,
  );

  late final SseRuntime _sse;
  final Map<String, Future<void>> _networkTails = {};

  @override
  void initState() {
    super.initState();
    _sse = ref.read(sseRuntimeProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sse.setHostReady(true);
    });
  }

  @override
  void dispose() {
    _sse.setHostReady(false);
    printerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrintImageGenerateWidget(
      onPictureGenerated: _onPictureGenerated,
      contentBuilder: (context) {
        return widget.child;
      },
    );
  }

  // Mirrors entry view printing pipeline to capture print tasks.
  Future<void> _onPictureGenerated(PicGenerateResult imgData) async {
    final printTask = imgData.taskItem;
    final printerInfo = printTask.params as PrinterInfo;
    try {
      if (printerInfo.completion?.isCompleted ?? false) return;
      await _sendPicture(imgData, printerInfo);
      if (!(printerInfo.completion?.isCompleted ?? true)) {
        printerInfo.completion!.complete();
      }
    } catch (error, stack) {
      if (!(printerInfo.completion?.isCompleted ?? true)) {
        printerInfo.completion!.completeError(error, stack);
      } else {
        debugPrint('Print transport failed: $error');
      }
    }
  }

  Future<void> _sendPicture(
    PicGenerateResult imgData,
    PrinterInfo printerInfo,
  ) async {
    final printTask = imgData.taskItem;
    final printTypeEnum = printTask.printTypeEnum;

    final imageBytes = await imgData.convertUint8List(
      imageByteFormat: ImageByteFormat.rawRgba,
    );
    if (imageBytes == null) throw StateError('Image generation failed');

    final argbWidth = imgData.imageWidth;
    final argbHeight = imgData.imageHeight;

    final printData = await printer_plus.PrinterCommandTool.generatePrintCmd(
      imgData: imageBytes,
      printType: printTypeEnum,
      argbWidthPx: argbWidth,
      argbHeightPx: argbHeight,
    );
    if (!mounted || (printerInfo.completion?.isCompleted ?? false)) {
      throw StateError('Print task cancelled');
    }

    if (printerInfo.isUsbPrinter) {
      final conn = printer_plus.UsbConn(printerInfo.usbDevice!);
      await conn.writeMultiBytes(printData, 1024 * 8);
    } else if (printerInfo.isNetPrinter) {
      await _sendNetwork(printerInfo, printData);
    } else {
      throw StateError('Missing printer target');
    }
  }

  Future<void> _sendNetwork(PrinterInfo info, List<List<int>> data) {
    final key = '${info.ip}:${info.port}';
    final previous = _networkTails[key] ?? Future<void>.value();
    final job = previous.then((_) async {
      if (!mounted || (info.completion?.isCompleted ?? false)) {
        throw StateError('Print task cancelled');
      }
      if (info.port == 9100) {
        await printerController.enqueue(
          info.ip!,
          data,
          timeout: const Duration(seconds: 12),
        );
      } else {
        final socket = await Socket.connect(
          info.ip!,
          info.port,
          timeout: const Duration(seconds: 12),
        );
        try {
          for (final chunk in data) {
            socket.add(chunk);
          }
          await socket.flush().timeout(const Duration(seconds: 12));
        } finally {
          socket.destroy();
        }
      }
    });
    // A failed job must not poison the next job on this endpoint.
    final tail = job.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _networkTails[key] = tail;
    unawaited(
      tail.then((_) {
        if (identical(_networkTails[key], tail)) _networkTails.remove(key);
      }),
    );
    return job;
  }
}
