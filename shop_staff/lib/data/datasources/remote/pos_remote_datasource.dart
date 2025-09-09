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

  Endpoints get _e => _client.endpoints;

  Future<dynamic> fetchHomeMenu() async => _client.getJson(_e.bootIndexV1);

  Future<dynamic> fetchCategoriesV2() async => _client.getJson(_e.bootIndexCategoryV2);

  // Activate (V3) - returns shop info with categories etc.
  Future<dynamic> activateBoot({required String code, String? machineCode}) async {
    // Assuming POST with code; adjust if GET contract differs
    final payload = {'code': code, if (machineCode != null) 'machineCode': machineCode};
    return _client.postJson(_e.activateV3, body: payload);
  }

  Future<dynamic> fetchMenuByCategoryV2(String categoryId) async =>
      _client.getJson(_e.bootIndexMenuV2, query: {'categoryId': categoryId});

  Future<dynamic> submitOrderV4(Map<String, dynamic> payload) async =>
      _client.postJson(_e.orderV4, body: payload);

  Future<dynamic> calculateOrder(Map<String, dynamic> payload) async =>
      _client.postJson(_e.calculateOrder, body: payload);
}