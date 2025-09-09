

import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';

class ActivationRepositoryImpl implements ActivationRepository {
  final PosRemoteDataSource _remote;
  ActivationRepositoryImpl(this._remote);
  ShopInfoModel? _cachedShop;
  @override
  Future<ShopInfoModel> activate(String code, {String? machineCode}) async {
    final raw = await _remote.activateBoot(code: code, machineCode: machineCode);
    if (raw is Map<String, dynamic>) {
      _cachedShop = ShopInfoModel.fromJson(raw);
      return _cachedShop!;
    }
    throw Exception('Invalid activateBoot response');
  }
}