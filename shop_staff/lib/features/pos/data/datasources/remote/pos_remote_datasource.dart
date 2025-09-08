import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/network/app_environment.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final config = AppConfig.forEnv(AppEnvironment.production); // TODO: inject env
  return DioClient.create(config);
});

final posRemoteDataSourceProvider = Provider<PosRemoteDataSource>((ref) {
  return PosRemoteDataSource(ref.watch(dioClientProvider));
});

class PosRemoteDataSource {
  final DioClient _client;
  PosRemoteDataSource(this._client);

  Endpoints get _e => _client.endpoints;

  Future<dynamic> fetchHomeMenu() async => _client.getJson(_e.bootIndex);

  Future<dynamic> fetchCategoriesV2() async => _client.getJson(_e.bootIndexCategoryV2);

  Future<dynamic> fetchMenuByCategoryV2(String categoryId) async =>
      _client.getJson(_e.bootIndexMenuV2, query: {'categoryId': categoryId});

  Future<dynamic> submitOrderV4(Map<String, dynamic> payload) async =>
      _client.postJson(_e.orderV4, body: payload);

  Future<dynamic> calculateOrder(Map<String, dynamic> payload) async =>
      _client.postJson(_e.calculateOrder, body: payload);
}
