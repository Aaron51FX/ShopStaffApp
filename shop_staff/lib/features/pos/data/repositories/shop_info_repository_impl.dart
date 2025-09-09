import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/features/pos/domain/repositories/shop_repository.dart';
import '../datasources/remote/pos_remote_datasource.dart';
import '../models/shop_info_models.dart';

final shopInfoRepositoryProvider = Provider<ShopInfoRepository>((ref) {
  final ds = ref.watch(posRemoteDataSourceProvider);
  return ShopInfoRepositoryImpl(ds);
});

class ShopInfoRepositoryImpl implements ShopInfoRepository {
  final PosRemoteDataSource _remote;
  ShopInfoRepositoryImpl(this._remote);

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