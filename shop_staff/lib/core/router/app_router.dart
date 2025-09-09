import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentations/pos/pages/pos_page.dart';
import '../../presentations/auth/pages/login_page.dart';
import '../storage/key_value_store.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final store = ref.read(keyValueStoreProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      // simple activation check
      final hasCode = await store.contains(AppStorageKeys.activationCode);
  // debug
  // ignore: avoid_print
  print('[RouterRedirect] hasCode=$hasCode location=${state.matchedLocation}');
      final loggingIn = state.matchedLocation == '/login';
      if (!hasCode && !loggingIn) return '/login';
      if (hasCode && loggingIn) return '/pos';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/pos',
        name: 'pos',
        builder: (context, state) => const PosPage(),
      ),
    ],
  );
});
