import 'package:freezed_annotation/freezed_annotation.dart';

part 'print_info.freezed.dart';
part 'print_info.g.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

Map<String, List<PrintOrderLine>> _linesMapFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return <String, List<PrintOrderLine>>{};
  return raw.map((key, value) {
    final list = (value as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PrintOrderLine.fromJson)
        .toList(growable: false);
    return MapEntry(key, list);
  });
}

Map<String, dynamic> _linesMapToJson(Map<String, List<PrintOrderLine>> map) {
  return map.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
}

Map<String, List<PrintOrderOption>> _optionsFromJson(Map<String, dynamic>? raw) {
  if (raw == null) return <String, List<PrintOrderOption>>{};
  return raw.map((key, value) {
    final list = (value as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PrintOrderOption.fromJson)
        .toList(growable: false);
    return MapEntry(key, list);
  });
}

Map<String, dynamic> _optionsToJson(Map<String, List<PrintOrderOption>> map) {
  return map.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
}

@freezed
class PrintInfoDocument with _$PrintInfoDocument {
  const factory PrintInfoDocument({
    @Default('') String shopName,
    @Default('') String shopCode,
    @Default('') String orderDate,
    @Default('') String address,
    @Default('') String telNo,
    @Default('') String ntaNo,
    @JsonKey(fromJson: _toInt) @Default(0) int orderType,
    @Default('') String numberTip,
    String? serialNo,
    String? serialNumber,
    String? serialNumberText,
    @JsonKey(fromJson: _toInt) @Default(0) int orderId,
    @Default('JP') String language,
    @Default(false) bool takeOut,
    @JsonKey(fromJson: _toInt) @Default(0) int price,
    @JsonKey(fromJson: _toInt) @Default(0) int tax,
    @JsonKey(fromJson: _toInt) @Default(0) int tax1,
    @JsonKey(fromJson: _toInt) @Default(0) int baseTax1,
    @JsonKey(fromJson: _toInt) @Default(0) int tax2,
    @JsonKey(fromJson: _toInt) @Default(0) int baseTax2,
    @Default('') String order,
    @JsonKey(fromJson: _toInt) @Default(0) int payPrice,
    @JsonKey(fromJson: _toInt) @Default(0) int change,
    String? payDate,
    String? memberNo,
    @Default('') String payMethod,
    List<dynamic>? details,
    @JsonKey(fromJson: _toInt) @Default(0) int discount,
    @JsonKey(fromJson: _toInt) @Default(0) int originalPrice,
    @Default('') String orderTime,
    PrintTicketInfo? printInfo,
  }) = _PrintInfoDocument;

  factory PrintInfoDocument.fromJson(Map<String, dynamic> json) => _$PrintInfoDocumentFromJson(json);
}

@freezed
class PrintTicketInfo with _$PrintTicketInfo {
  const factory PrintTicketInfo({
    String? uuid,
    @JsonKey(fromJson: _toInt) @Default(0) int bizId,
    @Default('') String orderTime,
    @Default('') String remark,
    @JsonKey(name: 'from_plate') @Default('') String fromPlate,
    @JsonKey(name: 'order_sn_code') @Default('') String orderSnCode,
    @JsonKey(name: 'payment_code') @Default('') String paymentCode,
    @JsonKey(name: 'order_type') @Default('') String orderType,
    @JsonKey(name: 'pay_type') @Default('') String payType,
    @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
    @Default(<String, List<PrintOrderLine>>{})
    Map<String, List<PrintOrderLine>> orderLinesMap,
    @Default(<PrintOrderLine>[]) List<PrintOrderLine> orderLines,
  }) = _PrintTicketInfo;

  factory PrintTicketInfo.fromJson(Map<String, dynamic> json) => _$PrintTicketInfoFromJson(json);
}

@freezed
class PrintOrderLine with _$PrintOrderLine {
  const factory PrintOrderLine({
    @Default('') String categoryName,
    @Default('') String name,
    @JsonKey(fromJson: _toInt) @Default(0) int price,
    @JsonKey(fromJson: _toInt) @Default(0) int qty,
    @JsonKey(fromJson: _toInt) @Default(0) int bizId,
    @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
    @Default(<String, List<PrintOrderOption>>{})
    Map<String, List<PrintOrderOption>> options,
    dynamic extend2qr,
  }) = _PrintOrderLine;

  factory PrintOrderLine.fromJson(Map<String, dynamic> json) => _$PrintOrderLineFromJson(json);
}

@freezed
class PrintOrderOption with _$PrintOrderOption {
  const factory PrintOrderOption({
    @Default('') String name,
    @JsonKey(fromJson: _toIntOrNull) int? price,
    @JsonKey(fromJson: _toInt) @Default(0) int qty,
  }) = _PrintOrderOption;

  factory PrintOrderOption.fromJson(Map<String, dynamic> json) => _$PrintOrderOptionFromJson(json);
}
