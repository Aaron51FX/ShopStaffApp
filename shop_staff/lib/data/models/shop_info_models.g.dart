// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_info_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LanguageModelImpl _$$LanguageModelImplFromJson(Map<String, dynamic> json) =>
    _$LanguageModelImpl(
      val: json['val'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$$LanguageModelImplToJson(_$LanguageModelImpl instance) =>
    <String, dynamic>{'val': instance.val, 'name': instance.name};

_$CategoryModelImpl _$$CategoryModelImplFromJson(Map<String, dynamic> json) =>
    _$CategoryModelImpl(
      categoryCode: json['categoryCode'] as String,
      categoryName: json['categoryName'] as String,
      showType: json['showType'] as String,
      color: json['color'] as String?,
      background: json['background'] as String?,
      image: json['image'] as String?,
      printReceipt: (json['printReceipt'] as num?)?.toInt(),
      menuVoList: json['menuVoList'] as List<dynamic>? ?? const <dynamic>[],
    );

Map<String, dynamic> _$$CategoryModelImplToJson(_$CategoryModelImpl instance) =>
    <String, dynamic>{
      'categoryCode': instance.categoryCode,
      'categoryName': instance.categoryName,
      'showType': instance.showType,
      'color': instance.color,
      'background': instance.background,
      'image': instance.image,
      'printReceipt': instance.printReceipt,
      'menuVoList': instance.menuVoList,
    };

_$RecommendMenuModelImpl _$$RecommendMenuModelImplFromJson(
  Map<String, dynamic> json,
) => _$RecommendMenuModelImpl(
  menuCode: json['menuCode'] as String,
  barCode: json['barCode'] as String?,
  type: (json['type'] as num).toInt(),
  categoryCode: json['categoryCode'] as String,
  mainTitle: json['mainTitle'] as String,
  subtitle: (json['subtitle'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  printText: json['printText'] as String,
  price: (json['price'] as num).toInt(),
  currentPrice: (json['currentPrice'] as num).toInt(),
  homeImage: json['homeImage'] as String?,
  homeImageHttp: json['homeImageHttp'] as String?,
  images: json['images'],
  qtyBounds: (json['qtyBounds'] as num).toInt(),
  extend1: json['extend1'] as String?,
  tax: json['tax'] as String,
  boundsPrice: (json['boundsPrice'] as num?)?.toInt(),
  timeBoundsStart:
      (json['timeBoundsStart'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  timeBoundsEnd:
      (json['timeBoundsEnd'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  optionGroupVoList:
      json['optionGroupVoList'] as List<dynamic>? ?? const <dynamic>[],
);

Map<String, dynamic> _$$RecommendMenuModelImplToJson(
  _$RecommendMenuModelImpl instance,
) => <String, dynamic>{
  'menuCode': instance.menuCode,
  'barCode': instance.barCode,
  'type': instance.type,
  'categoryCode': instance.categoryCode,
  'mainTitle': instance.mainTitle,
  'subtitle': instance.subtitle,
  'printText': instance.printText,
  'price': instance.price,
  'currentPrice': instance.currentPrice,
  'homeImage': instance.homeImage,
  'homeImageHttp': instance.homeImageHttp,
  'images': instance.images,
  'qtyBounds': instance.qtyBounds,
  'extend1': instance.extend1,
  'tax': instance.tax,
  'boundsPrice': instance.boundsPrice,
  'timeBoundsStart': instance.timeBoundsStart,
  'timeBoundsEnd': instance.timeBoundsEnd,
  'optionGroupVoList': instance.optionGroupVoList,
};

_$ShopInfoModelImpl _$$ShopInfoModelImplFromJson(Map<String, dynamic> json) =>
    _$ShopInfoModelImpl(
      shopCode: json['shopCode'] as String,
      machineCode: json['machineCode'] as String?,
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => LanguageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <LanguageModel>[],
      shopName: json['shopName'] as String,
      ntaNo: json['ntaNo'] as String?,
      stationMachineCode: json['stationMachineCode'] as String?,
      language: json['language'] as String,
      shopAddress: json['shopAddress'] as String?,
      shopTelephone: json['shopTelephone'] as String?,
      businessTime: json['businessTime'] as String?,
      seatNumber: json['seatNumber'] as String?,
      categoryVoList:
          (json['categoryVoList'] as List<dynamic>?)
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CategoryModel>[],
      onlineCall: json['onlineCall'] as bool?,
      taxSystem: json['taxSystem'] as bool?,
      dynamicCode: json['dynamicCode'] as bool?,
      multiplayer: json['multiplayer'] as bool?,
      canToOrder: json['canToOrder'] as String?,
      uniqueOrderKey: json['uniqueOrderKey'] as String?,
      linePayChannelMap: json['linePayChannelMap'] as Map<String, dynamic>?,
      recommends:
          (json['recommends'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      recommendMenus:
          (json['recommendMenus'] as List<dynamic>?)
              ?.map(
                (e) => RecommendMenuModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <RecommendMenuModel>[],
    );

Map<String, dynamic> _$$ShopInfoModelImplToJson(_$ShopInfoModelImpl instance) =>
    <String, dynamic>{
      'shopCode': instance.shopCode,
      'machineCode': instance.machineCode,
      'languages': instance.languages,
      'shopName': instance.shopName,
      'ntaNo': instance.ntaNo,
      'stationMachineCode': instance.stationMachineCode,
      'language': instance.language,
      'shopAddress': instance.shopAddress,
      'shopTelephone': instance.shopTelephone,
      'businessTime': instance.businessTime,
      'seatNumber': instance.seatNumber,
      'categoryVoList': instance.categoryVoList,
      'onlineCall': instance.onlineCall,
      'taxSystem': instance.taxSystem,
      'dynamicCode': instance.dynamicCode,
      'multiplayer': instance.multiplayer,
      'canToOrder': instance.canToOrder,
      'uniqueOrderKey': instance.uniqueOrderKey,
      'linePayChannelMap': instance.linePayChannelMap,
      'recommends': instance.recommends,
      'recommendMenus': instance.recommendMenus,
    };
