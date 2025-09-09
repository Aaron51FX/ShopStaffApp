import '../../data/models/shop_info_models.dart';

abstract class ActivationRepository {
  Future<ShopInfoModel> activate(String code, {String? machineCode});
}
