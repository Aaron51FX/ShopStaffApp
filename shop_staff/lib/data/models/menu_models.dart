import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_models.freezed.dart';
part 'menu_models.g.dart';

// --- Helpers for tolerant numeric parsing (backend may return string or number) ---
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

/// Option inside a group
@JsonSerializable(explicitToJson: true)
class OptionVoModel {
  final String optionCode;
  final String? group; // group code reference
  final String? groupName;
  final String mainTitle;
  final List<String>? subTitle;
  final String printText;
  final String? extend1;
  @JsonKey(fromJson: _toIntOrNull) final int? price; // legacy price, can be null (string/int)
  @JsonKey(fromJson: _toIntOrNull) final int? currentPrice;
  final String? homeImage;
  final String? homeImageHttp;
  @JsonKey(fromJson: _toIntOrNull) final int? standard; // 1 default selected
  @JsonKey(fromJson: _toIntOrNull) final int? bounds; // inventory bound or -1
  @JsonKey(fromJson: _toIntOrNull) final int? boundsPrice;
  final String? buttonColorValue; // two colors separated by comma

  OptionVoModel({
    required this.optionCode,
    required this.group,
    required this.groupName,
    required this.mainTitle,
    required this.subTitle,
    required this.printText,
    required this.extend1,
    required this.price,
    required this.currentPrice,
    required this.homeImage,
    required this.homeImageHttp,
    required this.standard,
    required this.bounds,
    required this.boundsPrice,
    required this.buttonColorValue,
  });

  factory OptionVoModel.fromJson(Map<String, dynamic> json) => _$OptionVoModelFromJson(json);
  Map<String, dynamic> toJson() => _$OptionVoModelToJson(this);
}

/// Group of options
@JsonSerializable(explicitToJson: true)
class OptionGroupModel {
  final String groupCode;
  final String groupName;
  final String printText;
  final String? remark;
  @JsonKey(fromJson: _toInt) final int multipleState; // 1 single, >1 maybe multi? (legacy semantics)
  @JsonKey(fromJson: _toInt) final int smallest; // min selection
  final List<OptionVoModel> optionVoList;

  OptionGroupModel({
    required this.groupCode,
    required this.groupName,
    required this.printText,
    required this.remark,
    required this.multipleState,
    required this.smallest,
    required this.optionVoList,
  });

  factory OptionGroupModel.fromJson(Map<String, dynamic> json) => _$OptionGroupModelFromJson(json);
  Map<String, dynamic> toJson() => _$OptionGroupModelToJson(this);
}

@freezed
class MenuItemModel with _$MenuItemModel {
  const factory MenuItemModel({
    required String menuCode,
    required String? barCode,
    required int type,
    required String categoryCode,
    required String mainTitle,
    @Default(<String>[]) List<String>? subtitle,
    required String printText,
    required int price,
    required int currentPrice,
    required String? homeImage,
    String? homeImageHttp,
    dynamic images,
    required int qtyBounds,
    String? extend1,
    required int tax,
    int? boundsPrice,
    @Default(<int>[]) List<int> timeBoundsStart,
    @Default(<int>[]) List<int> timeBoundsEnd,
    @Default(<OptionGroupModel>[]) List<OptionGroupModel> optionGroupVoList,
  }) = _MenuItemModel;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => _$MenuItemModelFromJson(json);
}

/// Wrapper for a list parsing (if needed later)
List<MenuItemModel> parseMenuItems(List<dynamic> raw) =>
    raw.map((e) => MenuItemModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
