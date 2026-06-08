import 'package:shop_staff/core/network/api_exception.dart';
import 'package:shop_staff/core/network/models/api_response.dart';
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/domain/repositories/cash_register_closure_repository.dart';

class CashRegisterClosureRepositoryImpl
    implements CashRegisterClosureRepository {
  CashRegisterClosureRepositoryImpl(this._remote);

  final PosRemoteDataSource _remote;

  @override
  Future<List<CashRegisterClosureMailAccount>> fetchMailList({
    required String machineCode,
  }) async {
    final response = _parseResponse<List<CashRegisterClosureMailAccount>>(
      await _remote.fetchRejishimeMailList({'machineCode': machineCode}),
      (raw) {
        if (raw is! List) return const <CashRegisterClosureMailAccount>[];
        return raw
            .whereType<Map>()
            .map(
              (item) => CashRegisterClosureMailAccount.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.verifyEmail.trim().isNotEmpty)
            .toList(growable: false);
      },
    );
    return response.data ?? const <CashRegisterClosureMailAccount>[];
  }

  @override
  Future<void> sendAdminVerify({
    required String machineCode,
    required String verifyEmail,
    required String verifyUserName,
  }) async {
    _ensureOk(
      _parseResponse<dynamic>(
        await _remote.sendRejishimeAdminVerify({
          'machineCode': machineCode,
          'verifyEmail': verifyEmail,
          'verifyUserName': verifyUserName,
        }),
        (raw) => raw,
      ),
    );
  }

  @override
  Future<CashRegisterClosureSummary> fetchStaffRejishime(
    CashRegisterClosureVerifyInput input,
  ) async {
    final rawResponse = await _remote.fetchStaffRejishime(input.toJson());
    if (rawResponse is! Map) {
      throw ApiException('API response is not an object', data: rawResponse);
    }
    final response = ApiResponse<dynamic>.fromJson(
      Map<String, dynamic>.from(rawResponse),
    );
    _ensureOk(response);

    final rawData = response.data;
    if (rawData == null) {
      throw const NoLatestCashRegisterClosureDataException();
    }
    if (rawData is! Map) {
      throw ApiException(
        'Cash register closure data is missing',
        data: rawData,
      );
    }
    return CashRegisterClosureSummary.fromJson(
      Map<String, dynamic>.from(rawData),
    );
  }

  @override
  Future<void> confirm(CashRegisterClosureVerifyInput input) async {
    _ensureOk(
      _parseResponse<dynamic>(
        await _remote.confirmRejishime(input.toJson()),
        (raw) => raw,
      ),
    );
  }

  ApiResponse<T> _parseResponse<T>(
    dynamic raw,
    T Function(dynamic data) dataParser,
  ) {
    if (raw is! Map) {
      throw ApiException('API response is not an object', data: raw);
    }
    final response = ApiResponse<T>.fromJson(
      Map<String, dynamic>.from(raw),
      dataParser: dataParser,
    );
    _ensureOk(response);
    return response;
  }

  void _ensureOk(ApiResponse<dynamic> response) {
    if (!response.isOk) {
      throw ApiException(
        response.message.isEmpty ? 'API request failed' : response.message,
        statusCode: response.code,
      );
    }
  }
}
