import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/settings/pages/settings_page.dart';
import '../../presentations/pos/pages/pos_page.dart';
import '../../presentations/auth/pages/login_page.dart';
import '../../presentations/splash/pages/splash_page.dart';
import '../../presentations/pos/pages/suspended_orders_page.dart';
import '../../presentations/order/pages/local_orders_page.dart';
import '../../presentations/payment/pages/payment_flow_page.dart';
import '../../presentations/entry/pages/entry_page.dart';
import '../../presentations/customer/pages/customer_page.dart';
import '../../presentations/printing/print_root_view.dart';
import '../storage/key_value_store.dart';

// Expose a root navigator key for global navigation/overlay usage
final rootNavigatorKey = GlobalKey<NavigatorState>();
// Removed providers.dart import (not needed here)

// Removed inline SplashPage class definition

final appRouterProvider = Provider<GoRouter>((ref) {
  final store = ref.read(keyValueStoreProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // always allow splash
      final hasCode = await store.contains(AppStorageKeys.activationCode);
      // ignore: avoid_print
      print('[RouterRedirect] hasCode=$hasCode location=$loc');
      final protectedPaths = {
        '/entry',
        '/customer',
        '/pos',
        '/pos/suspended',
        '/orders',
        '/settings',
        '/payment',
      };
      final needsGuard =
          protectedPaths.contains(loc) || loc.startsWith('/pos/');
      if (!hasCode && needsGuard) return '/login';
      if (hasCode && loc == '/login') return '/splash';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => PrintRootView(child: child),
        routes: [
          GoRoute(
            path: '/entry',
            name: 'entry',
            builder: (context, state) => const EntryPage(),
          ),
          GoRoute(
            path: '/customer',
            name: 'customer',
            builder: (context, state) => const CustomerPage(),
          ),
          GoRoute(
            path: '/pos',
            name: 'pos',
            builder: (context, state) => const PosPage(),
          ),
          GoRoute(
            path: '/pos/suspended',
            name: 'suspended',
            builder: (context, state) => const SuspendedOrdersPage(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const LocalOrdersPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/payment',
            name: 'payment',
            builder: (context, state) {
              final args = state.extra;
              if (args is! PaymentFlowPageArgs) {
                return const Scaffold(body: Center(child: Text('缺少支付参数')));
              }
              return PaymentFlowPage(args: args);
            },
          ),
        ],
      ),
    ],
  );
});
