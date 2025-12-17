// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrintInfoDocumentImpl _$$PrintInfoDocumentImplFromJson(
  Map<String, dynamic> json,
) => _$PrintInfoDocumentImpl(
  shopName: json['shopName'] as String? ?? '',
  shopCode: json['shopCode'] as String? ?? '',
  orderDate: json['orderDate'] as String? ?? '',
  address: json['address'] as String? ?? '',
  telNo: json['telNo'] as String? ?? '',
  ntaNo: json['ntaNo'] as String? ?? '',
  orderType: json['orderType'] == null ? 0 : _toInt(json['orderType']),
  numberTip: json['numberTip'] as String? ?? '',
  serialNo: json['serialNo'] as String?,
  serialNumber: json['serialNumber'] as String?,
  serialNumberText: json['serialNumberText'] as String?,
  orderId: json['orderId'] == null ? 0 : _toInt(json['orderId']),
  language: json['language'] as String? ?? 'JP',
  takeOut: json['takeOut'] as bool? ?? false,
  price: json['price'] == null ? 0 : _toInt(json['price']),
  tax: json['tax'] == null ? 0 : _toInt(json['tax']),
  tax1: json['tax1'] == null ? 0 : _toInt(json['tax1']),
  baseTax1: json['baseTax1'] == null ? 0 : _toInt(json['baseTax1']),
  tax2: json['tax2'] == null ? 0 : _toInt(json['tax2']),
  baseTax2: json['baseTax2'] == null ? 0 : _toInt(json['baseTax2']),
  order: json['order'] as String? ?? '',
  payPrice: json['payPrice'] == null ? 0 : _toInt(json['payPrice']),
  change: json['change'] == null ? 0 : _toInt(json['change']),
  payDate: json['payDate'] as String?,
  memberNo: json['memberNo'] as String?,
  payMethod: json['payMethod'] as String? ?? '',
  details: json['details'] as List<dynamic>?,
  discount: json['discount'] == null ? 0 : _toInt(json['discount']),
  originalPrice: json['originalPrice'] == null
      ? 0
      : _toInt(json['originalPrice']),
  orderTime: json['orderTime'] as String? ?? '',
  printInfo: json['printInfo'] == null
      ? null
      : PrintTicketInfo.fromJson(json['printInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$PrintInfoDocumentImplToJson(
  _$PrintInfoDocumentImpl instance,
) => <String, dynamic>{
  'shopName': instance.shopName,
  'shopCode': instance.shopCode,
  'orderDate': instance.orderDate,
  'address': instance.address,
  'telNo': instance.telNo,
  'ntaNo': instance.ntaNo,
  'orderType': instance.orderType,
  'numberTip': instance.numberTip,
  'serialNo': instance.serialNo,
  'serialNumber': instance.serialNumber,
  'serialNumberText': instance.serialNumberText,
  'orderId': instance.orderId,
  'language': instance.language,
  'takeOut': instance.takeOut,
  'price': instance.price,
  'tax': instance.tax,
  'tax1': instance.tax1,
  'baseTax1': instance.baseTax1,
  'tax2': instance.tax2,
  'baseTax2': instance.baseTax2,
  'order': instance.order,
  'payPrice': instance.payPrice,
  'change': instance.change,
  'payDate': instance.payDate,
  'memberNo': instance.memberNo,
  'payMethod': instance.payMethod,
  'details': instance.details,
  'discount': instance.discount,
  'originalPrice': instance.originalPrice,
  'orderTime': instance.orderTime,
  'printInfo': instance.printInfo,
};

_$PrintTicketInfoImpl _$$PrintTicketInfoImplFromJson(
  Map<String, dynamic> json,
) => _$PrintTicketInfoImpl(
  uuid: json['uuid'] as String?,
  bizId: json['bizId'] == null ? 0 : _toInt(json['bizId']),
  orderTime: json['orderTime'] as String? ?? '',
  remark: json['remark'] as String? ?? '',
  fromPlate: json['from_plate'] as String? ?? '',
  orderSnCode: json['order_sn_code'] as String? ?? '',
  paymentCode: json['payment_code'] as String? ?? '',
  orderType: json['order_type'] as String? ?? '',
  payType: json['pay_type'] as String? ?? '',
  orderLinesMap: json['orderLinesMap'] == null
      ? const <String, List<PrintOrderLine>>{}
      : _linesMapFromJson(json['orderLinesMap'] as Map<String, dynamic>?),
  orderLines:
      (json['orderLines'] as List<dynamic>?)
          ?.map((e) => PrintOrderLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PrintOrderLine>[],
);

Map<String, dynamic> _$$PrintTicketInfoImplToJson(
  _$PrintTicketInfoImpl instance,
) => <String, dynamic>{
  'uuid': instance.uuid,
  'bizId': instance.bizId,
  'orderTime': instance.orderTime,
  'remark': instance.remark,
  'from_plate': instance.fromPlate,
  'order_sn_code': instance.orderSnCode,
  'payment_code': instance.paymentCode,
  'order_type': instance.orderType,
  'pay_type': instance.payType,
  'orderLinesMap': _linesMapToJson(instance.orderLinesMap),
  'orderLines': instance.orderLines,
};

_$PrintOrderLineImpl _$$PrintOrderLineImplFromJson(Map<String, dynamic> json) =>
    _$PrintOrderLineImpl(
      categoryName: json['categoryName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] == null ? 0 : _toInt(json['price']),
      qty: json['qty'] == null ? 0 : _toInt(json['qty']),
      bizId: json['bizId'] == null ? 0 : _toInt(json['bizId']),
      options: json['options'] == null
          ? const <String, List<PrintOrderOption>>{}
          : _optionsFromJson(json['options'] as Map<String, dynamic>?),
      extend2qr: json['extend2qr'],
    );

Map<String, dynamic> _$$PrintOrderLineImplToJson(
  _$PrintOrderLineImpl instance,
) => <String, dynamic>{
  'categoryName': instance.categoryName,
  'name': instance.name,
  'price': instance.price,
  'qty': instance.qty,
  'bizId': instance.bizId,
  'options': _optionsToJson(instance.options),
  'extend2qr': instance.extend2qr,
};

_$PrintOrderOptionImpl _$$PrintOrderOptionImplFromJson(
  Map<String, dynamic> json,
) => _$PrintOrderOptionImpl(
  name: json['name'] as String? ?? '',
  price: _toIntOrNull(json['price']),
  qty: json['qty'] == null ? 0 : _toInt(json['qty']),
);

Map<String, dynamic> _$$PrintOrderOptionImplToJson(
  _$PrintOrderOptionImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'price': instance.price,
  'qty': instance.qty,
};
