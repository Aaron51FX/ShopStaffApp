import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_environment.dart';
import 'dio_client.dart';
import 'endpoints.dart';

final environmentProvider = Provider<AppEnvironment>((ref) {
  return AppEnvironment.production; // 切换为 staging 进行测试
});

final appConfigProvider = Provider<AppConfig>((ref) {
  final env = ref.watch(environmentProvider);
  return AppConfig.forEnv(env);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return DioClient.create(cfg);
});

final endpointsProvider = Provider<Endpoints>((ref) {
  return ref.watch(dioClientProvider).endpoints;
});
