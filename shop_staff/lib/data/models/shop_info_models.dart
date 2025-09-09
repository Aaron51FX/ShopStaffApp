import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_info_models.freezed.dart';
part 'shop_info_models.g.dart';

@freezed
class LanguageModel with _$LanguageModel {
  const factory LanguageModel({
    required String val,
    required String name,
  }) = _LanguageModel;
  factory LanguageModel.fromJson(Map<String, dynamic> json) => _$LanguageModelFromJson(json);
}

@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String categoryCode,
    required String categoryName,
    required String showType,
    String? color,
    String? background,
    String? image,
    int? printReceipt,
    @Default(<dynamic>[]) List<dynamic> menuVoList,
  }) = _CategoryModel;
  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);
}

@freezed
class RecommendMenuModel with _$RecommendMenuModel {
  const factory RecommendMenuModel({
    required String menuCode,
    String? barCode,
    required int type,
    required String categoryCode,
    required String mainTitle,
    List<String>? subtitle,
    required String printText,
    required int price,
    required int currentPrice,
    String? homeImage,
    String? homeImageHttp,
    dynamic images,
    required int qtyBounds,
    String? extend1,
    required String tax,
    int? boundsPrice,
    @Default(<int>[]) List<int> timeBoundsStart,
    @Default(<int>[]) List<int> timeBoundsEnd,
    @Default(<dynamic>[]) List<dynamic> optionGroupVoList,
  }) = _RecommendMenuModel;
  factory RecommendMenuModel.fromJson(Map<String, dynamic> json) => _$RecommendMenuModelFromJson(json);
}

@freezed
class ShopInfoModel with _$ShopInfoModel {
  const factory ShopInfoModel({
    required String shopCode,
    String? machineCode,
    @Default(<LanguageModel>[]) List<LanguageModel> languages,
    required String shopName,
    String? ntaNo,
    String? stationMachineCode,
    required String language,
    String? shopAddress,
    String? shopTelephone,
    String? businessTime,
    String? seatNumber,
    @Default(<CategoryModel>[]) List<CategoryModel> categoryVoList,
    bool? onlineCall,
    bool? taxSystem,
    bool? dynamicCode,
    bool? multiplayer,
    String? canToOrder,
    String? uniqueOrderKey,
    Map<String, dynamic>? linePayChannelMap,
    @Default(<int>[]) List<int> recommends,
    @Default(<RecommendMenuModel>[]) List<RecommendMenuModel> recommendMenus,
  }) = _ShopInfoModel;

  factory ShopInfoModel.fromJson(Map<String, dynamic> json) => _$ShopInfoModelFromJson(json);
}
