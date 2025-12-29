import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  runApp(const ProviderScope(child: ShopStaffApp()));
}

class ShopStaffApp extends ConsumerWidget {
  const ShopStaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp.router(
          //useInheritedMediaQuery: true,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
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
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
