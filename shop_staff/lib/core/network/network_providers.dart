import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/auth/auth_token_store.dart';
import 'package:shop_staff/core/auth/authentication_change_notifier.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'app_environment.dart';
import 'dio_client.dart';
import 'endpoints.dart';

final environmentProvider = Provider<AppEnvironment>((ref) {
  return appEnvironmentFromDartDefine();
});

final appConfigProvider = Provider<AppConfig>((ref) {
  final env = ref.watch(environmentProvider);
  return AppConfig.forEnv(env);
});

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return AuthTokenStore(ref.watch(keyValueStoreProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return DioClient.create(
    cfg,
    authTokenStore: ref.watch(authTokenStoreProvider),
    onAuthenticationRequired: () async {
      authenticationChangeNotifier.notifyAuthenticationChanged();
    },
  );
});

final endpointsProvider = Provider<Endpoints>((ref) {
  return ref.watch(dioClientProvider).endpoints;
});
