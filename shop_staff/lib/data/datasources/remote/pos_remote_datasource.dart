import 'package:shop_staff/core/localization/shop_language_code.dart';
import 'package:shop_staff/core/network/dio_client.dart';
import 'package:shop_staff/core/network/endpoints.dart';

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

  Future<dynamic> fetchHomeMenu({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
  }) async {
    final requestLanguage = normalizeShopLanguageCode(language);
    // 与 fetchCategoriesV2 一致: POST 同一分类接口, 便于统一首批数据来源
    final payload = {
      'machineCode': machineCode,
      'language': requestLanguage,
      'takeout': takeout ? 0 : 2,
    };
    final key =
        'POST:HOME:${_e.bootIndexV1}:$machineCode:$requestLanguage:$takeout';
    return _dedupe(key, () => _client.postJson(_e.bootIndexV1, body: payload));
  }

  Future<dynamic> fetchCategoriesV2({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
  }) async {
    final requestLanguage = normalizeShopLanguageCode(language);
    final payload = {
      'machineCode': machineCode,
      'language': requestLanguage,
      'takeout': takeout ? 0 : 2,
    };
    final key =
        'POST:${_e.bootIndexCategoryV2}:$machineCode:$requestLanguage:$takeout';
    return _dedupe(
      key,
      () => _client.postJson(_e.bootIndexCategoryV2, body: payload),
    );
  }

  /// Activate (V3) - backend now expects only machineCode + version.
  /// Returns shop info payload.
  Future<dynamic> activateBoot({
    required String machineCode,
    required String version,
  }) async {
    final payload = {'machineCode': machineCode, 'version': version};
    final key = 'POST:${_e.activateV3}:${machineCode}_$version';
    return _dedupe(key, () => _client.postJson(_e.activateV3, body: payload));
  }

  Future<dynamic> fetchMenuByCategoryV2({
    required String machineCode,
    String language = 'JP',
    bool takeout = false,
    required String categoryCode,
  }) async {
    final requestLanguage = normalizeShopLanguageCode(language);
    final payload = {
      'machineCode': machineCode,
      'language': requestLanguage,
      'takeout': takeout ? 0 : 2,
      'categoryCode': categoryCode,
    };
    final key =
        'POST:${_e.bootIndexMenuV2}:$machineCode:$requestLanguage:$takeout:$categoryCode';
    return _dedupe(
      key,
      () => _client.postJson(_e.bootIndexMenuV2, body: payload),
    );
  }

  Future<dynamic> submitOrderV4(Map<String, dynamic> payload) async =>
      _client.postJson(_e.orderV4, body: payload);

  Future<dynamic> submitOfflineOrderV1(Map<String, dynamic> payload) async =>
      _client.postJson(_e.offlineOrderV1, body: payload);

  Future<dynamic> recordStaffOrderV1(Map<String, dynamic> payload) async =>
      _client.postJson(_e.staffOrderV1, body: payload);

  Future<dynamic> updateStaffOrderStateV1(Map<String, dynamic> payload) async =>
      _client.postJson(_e.orderStaffUpdateStateV1, body: payload);

  Future<dynamic> calculateOrder(Map<String, dynamic> payload) async =>
      _client.postJson(_e.calculateOrder, body: payload);

  Future<dynamic> fetchSettlementOrder({
    required String orderKey,
    required String language,
    required String machineCode,
  }) {
    final requestLanguage = normalizeShopLanguageCode(language);
    final payload = {
      'orderKey': orderKey,
      'language': requestLanguage,
      'machineCode': machineCode,
    };
    final key =
        'POST:${_e.bootCalculateV2}:$orderKey:$requestLanguage:$machineCode';
    return _dedupe(
      key,
      () => _client.postJson(_e.bootCalculateV2, body: payload),
    );
  }

  Future<dynamic> confirmSettlementOrder(String orderId) async =>
      _client.postJson(_e.calculateConfirm, body: {'orderId': orderId});

  Future<dynamic> requestPosPayment(Map<String, dynamic> payload) async =>
      _client.postJson(_e.toPayV2, body: payload);

  Future<dynamic> reportPosPayment(Map<String, dynamic> payload) async =>
      _client.postJson(_e.posPayReport, body: payload);

  Future<dynamic> cancelCreditCard(Map<String, dynamic> payload) async =>
      _client.postJson(_e.creditCardCancel, body: payload);

  Future<dynamic> fetchRejishimeMailList(Map<String, dynamic> payload) async =>
      _client.postJson(_e.rejishimeiMailList, body: payload);

  Future<dynamic> sendRejishimeAdminVerify(
    Map<String, dynamic> payload,
  ) async => _client.postJson(_e.rejishimeiAdminVerify, body: payload);

  Future<dynamic> fetchStaffRejishime(Map<String, dynamic> payload) async =>
      _client.postJson(_e.rejishimeiPrintInfo, body: payload);

  Future<dynamic> confirmRejishime(Map<String, dynamic> payload) async =>
      _client.postJson(_e.rejishimeiConfirm, body: payload);

  //print info
  Future<dynamic> printInfo(Map<String, dynamic> payload) async =>
      _client.postJson(_e.printV9, body: payload);
}
