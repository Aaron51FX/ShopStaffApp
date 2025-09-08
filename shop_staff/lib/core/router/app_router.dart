import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/pos/presentation/pages/pos_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/pos',
    routes: [
      GoRoute(
        path: '/pos',
        name: 'pos',
        builder: (context, state) => const PosPage(),
      ),
    ],
  );
});
