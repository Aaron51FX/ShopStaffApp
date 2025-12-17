import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:flutter_printer_plus/flutter_printer_plus.dart' as printerPlus;
import 'package:shop_staff/core/config/print_info.dart';
import 'core/router/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/dialog/dialog_service.dart';
import 'core/localization/locale_providers.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // if (!kIsWeb &&
  //     (defaultTargetPlatform == TargetPlatform.windows ||
  //         defaultTargetPlatform == TargetPlatform.linux ||
  //         defaultTargetPlatform == TargetPlatform.macOS)) {
  //   await windowManager.ensureInitialized();
  //   const options = WindowOptions(
  //     fullScreen: true,
  //     titleBarStyle: TitleBarStyle.hidden,
  //   );
  //   await windowManager.waitUntilReadyToShow(options, () async {
  //     await windowManager.setFullScreen(true);
  //     await windowManager.show();
  //     await windowManager.focus();
  //   });
  // }

  await Hive.initFlutter();
  runApp(ProviderScope(child: ShopStaffApp()));
}

class ShopStaffApp extends ConsumerWidget {
  ShopStaffApp({super.key});
  final printerController = printerPlus.PrinterJobController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GlobalDialogHost(
          child: 
            PrintImageGenerateWidget(
            contentBuilder: (context) {
              return child ?? const SizedBox.shrink();
            },
            onPictureGenerated: _onPictureGenerated,
          ));
      },
    );
  }

    //打印图层生成成功
  Future<void> _onPictureGenerated(PicGenerateResult imgData) async {
    //final imageBytes = imgdata.data;
      final printTask = imgData.taskItem;

    //指定的打印机
      final printerInfo = printTask.params as PrinterInfo;
      //print('printerInfo: $printerInfo');
      //打印票据类型（标签、小票）
      final printTypeEnum = printTask.printTypeEnum;

      final imageBytes =
          await imgData.convertUint8List(imageByteFormat: ImageByteFormat.rawRgba);
      //也可以使用 ImageByteFormat.png
      final argbWidth = imgData.imageWidth;
      final argbHeight = imgData.imageHeight;
      if (imageBytes == null) {
        return;
      }

      var printData = await printerPlus.PrinterCommandTool.generatePrintCmd(
        imgData: imageBytes,
        printType: printTypeEnum,
        argbWidthPx: argbWidth,
        argbHeightPx: argbHeight,
      );

      if (printerInfo.isUsbPrinter) {
        // usb 打印
        final conn = printerPlus.UsbConn(printerInfo.usbDevice!);
        conn.writeMultiBytes(printData, 1024 * 8);
      } else if (printerInfo.isNetPrinter) {
        // 网络 打印
        // final conn = printerPlus.NetConn(printerInfo.ip!);
        // conn.writeMultiBytes(printData);
        debugPrint('开始网络打印，IP：${printerInfo.ip}');

        try {
          await printerController.enqueue(printerInfo.ip!, printData, timeout: Duration(seconds: 12));
          // final conn = printerPlus.NetConn(printerInfo.ip!);
          // conn.writeMultiBytes(printData);
        } catch (e) {
          debugPrint('打印失败: $e');
          throw Exception('打印失败: $e');
        }
      }

      // // 网络 打印
      // final conn = printerPlus.NetConn(printerInfo.ip!);
      // conn.writeMultiBytes(printData);
    }
}
