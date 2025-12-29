
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_printer_plus/flutter_printer_plus.dart' as printerPlus;
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
	final printerController = printerPlus.PrinterJobController();

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
		final printTypeEnum = printTask.printTypeEnum;

		final imageBytes =
				await imgData.convertUint8List(imageByteFormat: ImageByteFormat.rawRgba);
		if (imageBytes == null) return;

		final argbWidth = imgData.imageWidth;
		final argbHeight = imgData.imageHeight;

		final printData = await printerPlus.PrinterCommandTool.generatePrintCmd(
			imgData: imageBytes,
			printType: printTypeEnum,
			argbWidthPx: argbWidth,
			argbHeightPx: argbHeight,
		);
    debugPrint('Printing to IP: ${printerInfo.ip}');

		if (printerInfo.isUsbPrinter) {
			final conn = printerPlus.UsbConn(printerInfo.usbDevice!);
			conn.writeMultiBytes(printData, 1024 * 8);
		} else if (printerInfo.isNetPrinter) {
			try {
				await printerController.enqueue(
					printerInfo.ip!,
					printData,
					timeout: const Duration(seconds: 12),
				);
			} catch (e) {
				debugPrint('打印失败: $e');
				throw Exception('打印失败: $e');
			}
		}
	}
}