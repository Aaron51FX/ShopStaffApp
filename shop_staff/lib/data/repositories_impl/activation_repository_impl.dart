

import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/domain/repositories/activation_repository.dart';

class ActivationRepositoryImpl implements ActivationRepository {
  final PosRemoteDataSource _remote;
  ActivationRepositoryImpl(this._remote);
  ShopInfoModel? _cachedShop;
  String? _lastMachineCode;
  Future<ShopInfoModel>? _inFlight;

  @override
  Future<ShopInfoModel> activate({required String machineCode, required String version}) async {
    if (_cachedShop != null && _lastMachineCode == machineCode) {
      // debug
      // ignore: avoid_print
      print('[ActivationRepo] return cached for $machineCode');
      return _cachedShop!;
    }
    if (_inFlight != null) return _inFlight!;
    // ignore: avoid_print
    print('[ActivationRepo] firing network for $machineCode');
    _inFlight = _remote.activateBoot(machineCode: machineCode, version: version).then((raw) {
      if (raw is Map<String, dynamic>) {
        _cachedShop = ShopInfoModel.fromActivationResponse(raw);
        _lastMachineCode = machineCode;
        // ignore: avoid_print
        print('[ActivationRepo] network success cache set');
        return _cachedShop!;
      }
      throw Exception('Invalid activateBoot response');
    });
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }
}