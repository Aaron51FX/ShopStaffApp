import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/dialog/dialog_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: ShopStaffApp()));
}

class ShopStaffApp extends ConsumerWidget {
  const ShopStaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
   return MaterialApp.router(
     title: 'Shop Staff POS',
     theme: AppTheme.light,
     routerConfig: router,
     debugShowCheckedModeBanner: false,
     builder: (context, child) {
       return GlobalDialogHost(child: child ?? const SizedBox.shrink());
    },
   );
  }
}
