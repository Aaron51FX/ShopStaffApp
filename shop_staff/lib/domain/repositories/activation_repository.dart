import '../../data/models/shop_info_models.dart';

/// Activation no longer uses an activation "code"; backend now expects
/// a device machineCode and app version. Returns ShopInfoModel on success.
abstract class ActivationRepository {
  Future<ShopInfoModel> activate({required String machineCode, required String version});
}
