import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/network/app_environment.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/core/network/endpoints.dart';


final dioClientProvider = Provider<DioClient>((ref) {
  final config = AppConfig.forEnv(AppEnvironment.staging); // TODO: inject env
  return DioClient.create(config);
});

final posRemoteDataSourceProvider = Provider<PosRemoteDataSource>((ref) {
  return PosRemoteDataSource(ref.watch(dioClientProvider));
});

class PosRemoteDataSource {
  final DioClient _client;
  PosRemoteDataSource(this._client);

  // Simple in-flight de-duplication: avoid firing same endpoint concurrently.
  final Map<String, Future<dynamic>> _inFlight = {};

  Future<T> _dedupe<T>(String key, Future<T> Function() run) {
    final existing = _inFlight[key];
    if (existing != null) return existing as Future<T>;
    final future = run();
    _inFlight[key] = future as Future<dynamic>;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  Endpoints get _e => _client.endpoints;

  Future<dynamic> fetchHomeMenu() async => _dedupe('GET:${_e.bootIndexV1}', () => _client.getJson(_e.bootIndexV1));

  Future<dynamic> fetchCategoriesV2() async => _dedupe('GET:${_e.bootIndexCategoryV2}', () => _client.getJson(_e.bootIndexCategoryV2));

  /// Activate (V3) - backend now expects only machineCode + version.
  /// Returns shop info payload.
  Future<dynamic> activateBoot({required String machineCode, required String version}) async {
    final payload = {'machineCode': machineCode, 'version': version};
    final key = 'POST:${_e.activateV3}:${machineCode}_$version';
    return _dedupe(key, () => _client.postJson(_e.activateV3, body: payload));
  }

  Future<dynamic> fetchMenuByCategoryV2(String categoryId) async =>
      _client.getJson(_e.bootIndexMenuV2, query: {'categoryId': categoryId});

  Future<dynamic> submitOrderV4(Map<String, dynamic> payload) async =>
      _client.postJson(_e.orderV4, body: payload);

  Future<dynamic> calculateOrder(Map<String, dynamic> payload) async =>
      _client.postJson(_e.calculateOrder, body: payload);
}