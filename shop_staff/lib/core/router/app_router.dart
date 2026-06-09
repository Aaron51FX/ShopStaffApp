import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/cash_register_closure/pages/cash_register_closure_detail_page.dart';
import 'package:shop_staff/presentations/cash_register_closure/pages/cash_register_closure_page.dart';
import 'package:shop_staff/presentations/cash_register_closure/pages/cash_register_closure_route_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_selection_page_args.dart';
import 'package:shop_staff/presentations/settings/pages/settings_page.dart';
import 'package:shop_staff/presentations/settings/sections/business_info/pages/shop_info_detail_page.dart';
import '../../presentations/pos/pages/pos_page.dart';
import '../../presentations/auth/pages/login_page.dart';
import '../../presentations/splash/pages/splash_page.dart';
import '../../presentations/pos/pages/suspended_orders_page.dart';
import '../../presentations/order/pages/local_orders_page.dart';
import '../../presentations/payment/pages/payment_flow_page.dart';
import '../../presentations/payment/pages/payment_selection_page.dart';
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
        '/payment-selection',
        '/payment',
      };
      final needsGuard =
          protectedPaths.contains(loc) ||
          loc.startsWith('/pos/') ||
          loc.startsWith('/settings/') ||
          loc.startsWith('/cash-register-closure');
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
            path: '/settings/shop-info',
            name: 'settings-shop-info',
            builder: (context, state) => const ShopInfoDetailPage(),
          ),
          GoRoute(
            path: '/cash-register-closure',
            name: 'cash-register-closure',
            builder: (context, state) {
              final args = state.extra;
              if (args is! CashRegisterClosurePageArgs) {
                final t = AppLocalizations.of(context);
                return Scaffold(body: Center(child: Text(t.routeArgsMissing)));
              }
              return CashRegisterClosurePage(
                machineCode: args.machineCode,
                shopName: args.shopName,
              );
            },
          ),
          GoRoute(
            path: '/cash-register-closure/detail',
            name: 'cash-register-closure-detail',
            builder: (context, state) {
              final args = state.extra;
              if (args is! CashRegisterClosureDetailPageArgs) {
                final t = AppLocalizations.of(context);
                return Scaffold(body: Center(child: Text(t.routeArgsMissing)));
              }
              return CashRegisterClosureDetailPage(
                machineCode: args.machineCode,
                shopName: args.shopName,
                summary: args.summary,
                input: args.input,
                mail: args.mail,
                isHistory: args.isHistory,
              );
            },
          ),
          GoRoute(
            path: '/payment-selection',
            name: 'payment-selection',
            builder: (context, state) {
              final args = state.extra;
              if (args is! PaymentSelectionPageArgs) {
                final t = AppLocalizations.of(context);
                return Scaffold(body: Center(child: Text(t.routeArgsMissing)));
              }
              return PaymentSelectionPage(args: args);
            },
          ),
          GoRoute(
            path: '/payment',
            name: 'payment',
            builder: (context, state) {
              final args = state.extra;
              if (args is! PaymentFlowPageArgs) {
                final t = AppLocalizations.of(context);
                return Scaffold(body: Center(child: Text(t.routeArgsMissing)));
              }
              return PaymentFlowPage(args: args);
            },
          ),
        ],
      ),
    ],
  );
});
