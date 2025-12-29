import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/data/repositories_impl/activation_repository_impl.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/data/services/cash_machine_service_impl.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';
import 'package:shop_staff/domain/services/cash_machine_service.dart';
import '../core/app_role.dart';
import '../core/network/app_environment.dart';
import '../core/network/dio_client.dart';
import '../core/storage/key_value_store.dart';
import 'datasources/local/suspended_order_local_data_source.dart';

// Data source (unified export stub)
import 'datasources/remote/pos_remote_datasource.dart';

// Repository implementations (new centralized path)
import 'repositories_impl/menu_repository_impl.dart';
import 'repositories_impl/order_repository_impl.dart';
import 'services/payment_backend_gateway.dart';
import 'services/payment_channel_support.dart';
import 'services/payment_flows/card_payment_flow.dart';
import 'services/payment_flows/cash_payment_flow.dart';
import 'services/payment_flows/qr_payment_flow.dart';
import 'services/key_value_app_settings_service.dart';
import 'services/app_role_service_impl.dart';
import 'services/pos_card_payment_gateway.dart';
import 'services/pos_payment_orchestrator.dart';
import 'services/pos_payment_service_impl.dart';
import 'services/print_service_impl.dart';

// Public repository interfaces
import '../domain/repositories/menu_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/payments/payment_models.dart';
import '../domain/services/pos_payment_service.dart';
import '../domain/services/payment_orchestrator.dart';
import '../domain/services/print_service.dart';
import '../domain/services/app_settings_service.dart';
import '../domain/services/app_role_service.dart';
import '../domain/services/startup_service.dart';
import '../data/models/shop_info_models.dart';
import 'services/startup_service_impl.dart';
import '../domain/settings/app_settings_models.dart';
import 'repositories_impl/print_repository_impl.dart';
import '../domain/repositories/print_repository.dart';

// Environment / Config provider (can later be overridden in tests)
final appEnvironmentProvider = Provider<AppEnvironment>((_) => AppEnvironment.production);

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

final posPaymentServiceProvider = Provider<PosPaymentService>((ref) {
  return PosPaymentServiceImpl(
    cardGateway: ref.watch(posCardPaymentGatewayProvider),
    logger: Logger('PosPaymentService'),
  );
});

final posCardPaymentGatewayProvider = Provider<PosCardPaymentGateway>((ref) {
  final remote = ref.watch(posRemoteDataSourceProvider);
  return PosCardPaymentGateway(remote, logger: Logger('PosCardPaymentGateway'));
});

final paymentBackendGatewayProvider = Provider<PaymentBackendGateway>((ref) {
  return StubPaymentBackendGateway(logger: Logger('PaymentBackendGatewayStub'));
});

final printRepositoryProvider = Provider<PrintRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return PrintRepositoryImpl(ds);
});

final printServiceProvider = Provider<PrintService>((ref) {
  return PrintServiceImpl();
});

final dialogDrivenQrScannerProvider = ChangeNotifierProvider<DialogDrivenQrScannerService>((ref) {
  final service = DialogDrivenQrScannerService(logger: Logger('QrScannerService'));
  ref.onDispose(service.dispose);
  return service;
});

final qrScannerServiceProvider = Provider<QrScannerService>((ref) {
  return ref.watch(dialogDrivenQrScannerProvider);
});

final qrScanUiStateProvider = Provider<QrScanUiState>((ref) {
  return ref.watch(dialogDrivenQrScannerProvider).state;
});

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  return KeyValueAppSettingsService(store, logger: Logger('AppSettingsService'));
});

final appRoleServiceProvider = Provider<AppRoleService>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  return AppRoleServiceImpl(store, logger: Logger('AppRoleService'));
});

final cashMachineServiceProvider = Provider<CashMachineService>((ref) {
  final service = CashMachineServiceImpl(Logger('CashMachine'));
  ref.onDispose(service.dispose);
  return service;
});

const _appVersion = '1.0.0';

final startupServiceProvider = Provider<StartupService>((ref) {
  return StartupServiceImpl(
    store: ref.watch(keyValueStoreProvider),
    activationRepository: ref.watch(activationRepositoryProvider),
    appSettingsService: ref.watch(appSettingsServiceProvider),
    appVersion: _appVersion,
    logger: Logger('StartupService'),
  );
});

final cardPaymentFlowProvider = Provider<CardPaymentFlow>((ref) {
  return CardPaymentFlow(
    posPaymentService: ref.watch(posPaymentServiceProvider),
    logger: Logger('CardPaymentFlow'),
  );
});

final cashPaymentFlowProvider = Provider<CashPaymentFlow>((ref) {
  return CashPaymentFlow(
    cashMachine: ref.watch(cashMachineServiceProvider),
    backendGateway: ref.watch(paymentBackendGatewayProvider),
    logger: Logger('CashPaymentFlow'),
  );
});

final qrPaymentFlowProvider = Provider<QrPaymentFlow>((ref) {
  return QrPaymentFlow(
    scannerService: ref.watch(qrScannerServiceProvider),
    backendGateway: ref.watch(paymentBackendGatewayProvider),
    posPaymentService: ref.watch(posPaymentServiceProvider),
    cardGateway: ref.watch(posCardPaymentGatewayProvider),
    logger: Logger('QrPaymentFlow'),
  );
});

final paymentFlowsProvider = Provider<Map<String, PaymentFlow>>((ref) {
  return {
    PaymentChannels.card: ref.watch(cardPaymentFlowProvider),
    PaymentChannels.cash: ref.watch(cashPaymentFlowProvider),
    PaymentChannels.qr: ref.watch(qrPaymentFlowProvider),
  };
});

final paymentOrchestratorProvider = Provider<PaymentOrchestrator>((ref) {
  final flows = ref.watch(paymentFlowsProvider);
  return PosPaymentOrchestrator(flows: flows, logger: Logger('PosPaymentOrchestrator'));
});

final activationRepositoryProvider = Provider<ActivationRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return ActivationRepositoryImpl(ds);
});

// Local data source for suspended orders (Hive)
final suspendedOrderLocalDataSourceProvider = Provider<SuspendedOrderLocalDataSource>((ref) {
  return SuspendedOrderLocalDataSource();
});

// Global in-memory ShopInfo (single source of truth after activation)
final shopInfoProvider = StateProvider<ShopInfoModel?>((_) => null);

final appSettingsSnapshotProvider = StateProvider<AppSettingsSnapshot?>((_) => null);

// Current app role (staff/customer). Default to staff until loaded from storage.
final appRoleProvider = StateProvider<AppRole>((_) => AppRole.staff);

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
