// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OptionVoModel _$OptionVoModelFromJson(Map<String, dynamic> json) =>
    OptionVoModel(
      optionCode: json['optionCode'] as String,
      group: json['group'] as String?,
      groupName: json['groupName'] as String?,
      mainTitle: json['mainTitle'] as String,
      subTitle: json['subTitle'] as String?,
      printText: json['printText'] as String,
      extend1: json['extend1'] as String?,
      price: _toIntOrNull(json['price']),
      currentPrice: _toIntOrNull(json['currentPrice']),
      homeImage: json['homeImage'] as String?,
      homeImageHttp: json['homeImageHttp'] as String?,
      standard: _toIntOrNull(json['standard']),
      bounds: _toIntOrNull(json['bounds']),
      boundsPrice: _toIntOrNull(json['boundsPrice']),
      buttonColorValue: json['buttonColorValue'] as String?,
    );

Map<String, dynamic> _$OptionVoModelToJson(OptionVoModel instance) =>
    <String, dynamic>{
      'optionCode': instance.optionCode,
      'group': instance.group,
      'groupName': instance.groupName,
      'mainTitle': instance.mainTitle,
      'subTitle': instance.subTitle,
      'printText': instance.printText,
      'extend1': instance.extend1,
      'price': instance.price,
      'currentPrice': instance.currentPrice,
      'homeImage': instance.homeImage,
      'homeImageHttp': instance.homeImageHttp,
      'standard': instance.standard,
      'bounds': instance.bounds,
      'boundsPrice': instance.boundsPrice,
      'buttonColorValue': instance.buttonColorValue,
    };

OptionGroupModel _$OptionGroupModelFromJson(Map<String, dynamic> json) =>
    OptionGroupModel(
      groupCode: json['groupCode'] as String,
      groupName: json['groupName'] as String,
      printText: json['printText'] as String,
      remark: json['remark'] as String?,
      multipleState: _toInt(json['multipleState']),
      smallest: _toInt(json['smallest']),
      optionVoList: (json['optionVoList'] as List<dynamic>)
          .map((e) => OptionVoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OptionGroupModelToJson(OptionGroupModel instance) =>
    <String, dynamic>{
      'groupCode': instance.groupCode,
      'groupName': instance.groupName,
      'printText': instance.printText,
      'remark': instance.remark,
      'multipleState': instance.multipleState,
      'smallest': instance.smallest,
      'optionVoList': instance.optionVoList.map((e) => e.toJson()).toList(),
    };

_$MenuItemModelImpl _$$MenuItemModelImplFromJson(Map<String, dynamic> json) =>
    _$MenuItemModelImpl(
      menuCode: json['menuCode'] as String,
      barCode: json['barCode'] as String?,
      type: (json['type'] as num).toInt(),
      categoryCode: json['categoryCode'] as String,
      mainTitle: json['mainTitle'] as String,
      subtitle:
          (json['subtitle'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      printText: json['printText'] as String,
      price: (json['price'] as num).toInt(),
      currentPrice: (json['currentPrice'] as num).toInt(),
      homeImage: json['homeImage'] as String?,
      homeImageHttp: json['homeImageHttp'] as String?,
      images: json['images'],
      qtyBounds: (json['qtyBounds'] as num).toInt(),
      extend1: json['extend1'] as String?,
      tax: (json['tax'] as num).toInt(),
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
          (json['optionGroupVoList'] as List<dynamic>?)
              ?.map((e) => OptionGroupModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OptionGroupModel>[],
    );

Map<String, dynamic> _$$MenuItemModelImplToJson(_$MenuItemModelImpl instance) =>
    <String, dynamic>{
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
