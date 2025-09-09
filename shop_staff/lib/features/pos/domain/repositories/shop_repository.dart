import 'package:shop_staff/features/pos/data/models/shop_info_models.dart';

abstract class ShopInfoRepository {
  Future<ShopInfoModel> activate(String code, {String? machineCode});
}