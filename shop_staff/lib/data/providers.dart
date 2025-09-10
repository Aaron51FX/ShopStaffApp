import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/data/repositories_impl/activation_repository_impl.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';
import '../core/network/app_environment.dart';
import '../core/network/dio_client.dart';

// Data source (unified export stub)
import 'datasources/remote/pos_remote_datasource.dart';

// Repository implementations (new centralized path)
import 'repositories_impl/menu_repository_impl.dart';
import 'repositories_impl/order_repository_impl.dart';

// Public repository interfaces
import '../domain/repositories/menu_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../data/models/shop_info_models.dart';

// Environment / Config provider (can later be overridden in tests)
final appEnvironmentProvider = Provider<AppEnvironment>((_) => AppEnvironment.staging);

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.forEnv(ref.watch(appEnvironmentProvider)));

// Core shared HTTP client
final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return DioClient.create(config);
});

// Remote datasource
final posRemoteDataSourceProvider = Provider<PosRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return PosRemoteDataSource(client);
});

// Repositories (unified naming: <feature><Repo>Provider kept backward compatible)
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return MenuRepositoryImpl(ds);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return OrderRepositoryImpl(ds);
});

final activationRepositoryProvider = Provider<ActivationRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return ActivationRepositoryImpl(ds);
});

// Global in-memory ShopInfo (single source of truth after activation)
final shopInfoProvider = StateProvider<ShopInfoModel?>((_) => null);

// Optional language override (user-chosen) distinct from backend default
final languageOverrideProvider = StateProvider<String?>((_) => null);

// Derived providers for convenience
final machineCodeProvider = Provider<String?>((ref) {
  final info = ref.watch(shopInfoProvider);
  return info?.machineCode ?? info?.stationMachineCode;
});

final shopLanguageProvider = Provider<String>((ref) {
  final override = ref.watch(languageOverrideProvider);
  if (override != null && override.isNotEmpty) return override;
  final info = ref.watch(shopInfoProvider);
  return info?.language.isNotEmpty == true ? info!.language : 'JP';
});

// 更新工具: 激活接口未返回 machineCode 时, 用已知值补齐
void updateShopInfoMachineCode(Ref ref, String machineCode) {
  if (machineCode.isEmpty) return;
  final current = ref.read(shopInfoProvider);
  if (current == null) return;
  if (current.machineCode == machineCode) return; // already correct
  ref.read(shopInfoProvider.notifier).state = current.copyWith(machineCode: machineCode);
}
