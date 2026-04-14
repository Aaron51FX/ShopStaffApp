import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shop_staff/data/providers.dart';
import 'core/router/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/dialog/dialog_service.dart';
import 'core/localization/locale_providers.dart';
import 'domain/settings/app_settings_models.dart';
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
  runApp(const RestartableApp());
}

class RestartableApp extends StatefulWidget {
  const RestartableApp({super.key});

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_RestartableAppState>()?.restart();
  }

  @override
  State<RestartableApp> createState() => _RestartableAppState();
}

class _RestartableAppState extends State<RestartableApp> {
  int _restartCounter = 0;

  void restart() {
    setState(() {
      _restartCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey('provider-scope-$_restartCounter'),
      child: ShopStaffApp(key: ValueKey('shop-staff-$_restartCounter')),
    );
  }
}

class ShopStaffApp extends ConsumerStatefulWidget {
  const ShopStaffApp({super.key});

  @override
  ConsumerState<ShopStaffApp> createState() => _ShopStaffAppState();
}

class _ShopStaffAppState extends ConsumerState<ShopStaffApp> {
  ProviderSubscription<AppSettingsSnapshot?>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _settingsSubscription = ref.listenManual<AppSettingsSnapshot?>(
      appSettingsSnapshotProvider,
      (_, next) => _syncLocaleFromSettings(next),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncLocaleFromSettings(ref.read(appSettingsSnapshotProvider));
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.close();
    super.dispose();
  }

  void _syncLocaleFromSettings(AppSettingsSnapshot? snapshot) {
    final locale = localeFromSettingsCode(snapshot?.basic.displayLocaleCode);
    final localeController = ref.read(localeControllerProvider.notifier);
    final currentLocale = ref.read(localeControllerProvider);
    if (locale == null) {
      if (currentLocale != null) {
        localeController.useSystemLocale();
      }
    } else if (currentLocale?.languageCode != locale.languageCode) {
      localeController.update(locale);
    }

    final nextOverride = localeToShopLanguageOverride(locale);
    final overrideNotifier = ref.read(languageOverrideProvider.notifier);
    final currentOverride = ref.read(languageOverrideProvider);
    if (currentOverride != nextOverride) {
      overrideNotifier.state = nextOverride;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            return GlobalDialogHost(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
