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
  factory LanguageModel.fromJsonSafe(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return LanguageModel(
      val: (j['val'] ?? j['value'] ?? '') as String? ?? '',
      name: (j['name'] ?? j['label'] ?? '') as String? ?? '',
    );
  }
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
  factory CategoryModel.fromJsonSafe(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return CategoryModel(
      categoryCode: (j['categoryCode'] ?? j['code'] ?? '') as String? ?? '',
      categoryName: (j['categoryName'] ?? j['name'] ?? '') as String? ?? '',
      showType: (j['showType'] ?? '') as String? ?? '',
      color: j['color'] as String?,
      background: j['background'] as String?,
      image: j['image'] as String?,
      printReceipt: j['printReceipt'] as int?,
      menuVoList: (j['menuVoList'] as List?)?.toList() ?? const [],
    );
  }
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
  factory RecommendMenuModel.fromJsonSafe(Map<String, dynamic>? json) {
    final j = json ?? const {};
    List<int> _listInt(dynamic v) => (v is List)
        ? v.whereType<num>().map((e) => e.toInt()).toList()
        : <int>[];
    return RecommendMenuModel(
      menuCode: (j['menuCode'] ?? '') as String? ?? '',
      barCode: j['barCode'] as String?,
      type: (j['type'] as num?)?.toInt() ?? 0,
      categoryCode: (j['categoryCode'] ?? '') as String? ?? '',
      mainTitle: (j['mainTitle'] ?? '') as String? ?? '',
      subtitle: (j['subtitle'] as List?)?.whereType<String>().toList(),
      printText: (j['printText'] ?? '') as String? ?? '',
      price: (j['price'] as num?)?.toInt() ?? 0,
      currentPrice: (j['currentPrice'] as num?)?.toInt() ?? 0,
      homeImage: j['homeImage'] as String?,
      homeImageHttp: j['homeImageHttp'] as String?,
      images: j['images'],
      qtyBounds: (j['qtyBounds'] as num?)?.toInt() ?? 0,
      extend1: j['extend1'] as String?,
      tax: (j['tax'] ?? '') as String? ?? '',
      boundsPrice: (j['boundsPrice'] as num?)?.toInt(),
      timeBoundsStart: _listInt(j['timeBoundsStart']),
      timeBoundsEnd: _listInt(j['timeBoundsEnd']),
      optionGroupVoList: (j['optionGroupVoList'] as List?)?.toList() ?? const [],
    );
  }
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
  factory ShopInfoModel.fromJsonSafe(Map<String, dynamic>? json) {
    final j = json ?? const {};
    List<int> _listInt(dynamic v) => (v is List)
        ? v.whereType<num>().map((e) => e.toInt()).toList()
        : <int>[];
    List<LanguageModel> _langs(dynamic v) {
      if (v is List) {
        return v.map<LanguageModel>((e) {
          if (e is String) {
            return LanguageModel(val: e, name: e);
          } else if (e is Map) {
            return LanguageModel.fromJsonSafe(e.cast<String, dynamic>());
          }
          return const LanguageModel(val: '', name: '');
        }).toList();
      }
      return const [];
    }
    return ShopInfoModel(
      shopCode: (j['shopCode'] ?? '') as String? ?? '',
      machineCode: j['machineCode'] as String?,
      languages: _langs(j['languages']),
      shopName: (j['shopName'] ?? '') as String? ?? '',
      ntaNo: j['ntaNo'] as String?,
      stationMachineCode: j['stationMachineCode'] as String?,
      language: (j['language'] ?? '') as String? ?? '',
      shopAddress: j['shopAddress'] as String?,
      shopTelephone: j['shopTelephone'] as String?,
      businessTime: j['businessTime'] as String?,
      seatNumber: j['seatNumber'] as String?,
  categoryVoList: (j['categoryVoList'] as List?)
      ?.map((e) => CategoryModel.fromJsonSafe((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      onlineCall: j['onlineCall'] as bool?,
      taxSystem: j['taxSystem'] as bool?,
      dynamicCode: j['dynamicCode'] as bool?,
      multiplayer: j['multiplayer'] as bool?,
      canToOrder: j['canToOrder'] as String?,
      uniqueOrderKey: j['uniqueOrderKey'] as String?,
      linePayChannelMap: j['linePayChannelMap'] != null
          ? Map<String, dynamic>.from(j['linePayChannelMap'] as Map)
          : null,
      recommends: _listInt(j['recommends']),
  recommendMenus: (j['recommendMenus'] as List?)
      ?.map((e) => RecommendMenuModel.fromJsonSafe((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
  static ShopInfoModel fromActivationResponse(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return ShopInfoModel.fromJsonSafe(data);
    }
    return ShopInfoModel.fromJsonSafe(raw);
  }
}
