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
