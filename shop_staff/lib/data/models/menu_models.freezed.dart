// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'menu_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MenuItemModel _$MenuItemModelFromJson(Map<String, dynamic> json) {
  return _MenuItemModel.fromJson(json);
}

/// @nodoc
mixin _$MenuItemModel {
  String get menuCode => throw _privateConstructorUsedError;
  String? get barCode => throw _privateConstructorUsedError;
  int get type => throw _privateConstructorUsedError;
  String get categoryCode => throw _privateConstructorUsedError;
  String get mainTitle => throw _privateConstructorUsedError;
  List<String>? get subtitle => throw _privateConstructorUsedError;
  String get printText => throw _privateConstructorUsedError;
  int get price => throw _privateConstructorUsedError;
  int get currentPrice => throw _privateConstructorUsedError;
  String? get homeImage => throw _privateConstructorUsedError;
  String? get homeImageHttp => throw _privateConstructorUsedError;
  dynamic get images => throw _privateConstructorUsedError;
  int get qtyBounds => throw _privateConstructorUsedError;
  String? get extend1 => throw _privateConstructorUsedError;
  int get tax => throw _privateConstructorUsedError;
  int? get boundsPrice => throw _privateConstructorUsedError;
  List<int> get timeBoundsStart => throw _privateConstructorUsedError;
  List<int> get timeBoundsEnd => throw _privateConstructorUsedError;
  List<OptionGroupModel> get optionGroupVoList =>
      throw _privateConstructorUsedError;

  /// Serializes this MenuItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MenuItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MenuItemModelCopyWith<MenuItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MenuItemModelCopyWith<$Res> {
  factory $MenuItemModelCopyWith(
    MenuItemModel value,
    $Res Function(MenuItemModel) then,
  ) = _$MenuItemModelCopyWithImpl<$Res, MenuItemModel>;
  @useResult
  $Res call({
    String menuCode,
    String? barCode,
    int type,
    String categoryCode,
    String mainTitle,
    List<String>? subtitle,
    String printText,
    int price,
    int currentPrice,
    String? homeImage,
    String? homeImageHttp,
    dynamic images,
    int qtyBounds,
    String? extend1,
    int tax,
    int? boundsPrice,
    List<int> timeBoundsStart,
    List<int> timeBoundsEnd,
    List<OptionGroupModel> optionGroupVoList,
  });
}

/// @nodoc
class _$MenuItemModelCopyWithImpl<$Res, $Val extends MenuItemModel>
    implements $MenuItemModelCopyWith<$Res> {
  _$MenuItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MenuItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuCode = null,
    Object? barCode = freezed,
    Object? type = null,
    Object? categoryCode = null,
    Object? mainTitle = null,
    Object? subtitle = freezed,
    Object? printText = null,
    Object? price = null,
    Object? currentPrice = null,
    Object? homeImage = freezed,
    Object? homeImageHttp = freezed,
    Object? images = freezed,
    Object? qtyBounds = null,
    Object? extend1 = freezed,
    Object? tax = null,
    Object? boundsPrice = freezed,
    Object? timeBoundsStart = null,
    Object? timeBoundsEnd = null,
    Object? optionGroupVoList = null,
  }) {
    return _then(
      _value.copyWith(
            menuCode: null == menuCode
                ? _value.menuCode
                : menuCode // ignore: cast_nullable_to_non_nullable
                      as String,
            barCode: freezed == barCode
                ? _value.barCode
                : barCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as int,
            categoryCode: null == categoryCode
                ? _value.categoryCode
                : categoryCode // ignore: cast_nullable_to_non_nullable
                      as String,
            mainTitle: null == mainTitle
                ? _value.mainTitle
                : mainTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            printText: null == printText
                ? _value.printText
                : printText // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int,
            currentPrice: null == currentPrice
                ? _value.currentPrice
                : currentPrice // ignore: cast_nullable_to_non_nullable
                      as int,
            homeImage: freezed == homeImage
                ? _value.homeImage
                : homeImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            homeImageHttp: freezed == homeImageHttp
                ? _value.homeImageHttp
                : homeImageHttp // ignore: cast_nullable_to_non_nullable
                      as String?,
            images: freezed == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as dynamic,
            qtyBounds: null == qtyBounds
                ? _value.qtyBounds
                : qtyBounds // ignore: cast_nullable_to_non_nullable
                      as int,
            extend1: freezed == extend1
                ? _value.extend1
                : extend1 // ignore: cast_nullable_to_non_nullable
                      as String?,
            tax: null == tax
                ? _value.tax
                : tax // ignore: cast_nullable_to_non_nullable
                      as int,
            boundsPrice: freezed == boundsPrice
                ? _value.boundsPrice
                : boundsPrice // ignore: cast_nullable_to_non_nullable
                      as int?,
            timeBoundsStart: null == timeBoundsStart
                ? _value.timeBoundsStart
                : timeBoundsStart // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            timeBoundsEnd: null == timeBoundsEnd
                ? _value.timeBoundsEnd
                : timeBoundsEnd // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            optionGroupVoList: null == optionGroupVoList
                ? _value.optionGroupVoList
                : optionGroupVoList // ignore: cast_nullable_to_non_nullable
                      as List<OptionGroupModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MenuItemModelImplCopyWith<$Res>
    implements $MenuItemModelCopyWith<$Res> {
  factory _$$MenuItemModelImplCopyWith(
    _$MenuItemModelImpl value,
    $Res Function(_$MenuItemModelImpl) then,
  ) = __$$MenuItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String menuCode,
    String? barCode,
    int type,
    String categoryCode,
    String mainTitle,
    List<String>? subtitle,
    String printText,
    int price,
    int currentPrice,
    String? homeImage,
    String? homeImageHttp,
    dynamic images,
    int qtyBounds,
    String? extend1,
    int tax,
    int? boundsPrice,
    List<int> timeBoundsStart,
    List<int> timeBoundsEnd,
    List<OptionGroupModel> optionGroupVoList,
  });
}

/// @nodoc
class __$$MenuItemModelImplCopyWithImpl<$Res>
    extends _$MenuItemModelCopyWithImpl<$Res, _$MenuItemModelImpl>
    implements _$$MenuItemModelImplCopyWith<$Res> {
  __$$MenuItemModelImplCopyWithImpl(
    _$MenuItemModelImpl _value,
    $Res Function(_$MenuItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MenuItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? menuCode = null,
    Object? barCode = freezed,
    Object? type = null,
    Object? categoryCode = null,
    Object? mainTitle = null,
    Object? subtitle = freezed,
    Object? printText = null,
    Object? price = null,
    Object? currentPrice = null,
    Object? homeImage = freezed,
    Object? homeImageHttp = freezed,
    Object? images = freezed,
    Object? qtyBounds = null,
    Object? extend1 = freezed,
    Object? tax = null,
    Object? boundsPrice = freezed,
    Object? timeBoundsStart = null,
    Object? timeBoundsEnd = null,
    Object? optionGroupVoList = null,
  }) {
    return _then(
      _$MenuItemModelImpl(
        menuCode: null == menuCode
            ? _value.menuCode
            : menuCode // ignore: cast_nullable_to_non_nullable
                  as String,
        barCode: freezed == barCode
            ? _value.barCode
            : barCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryCode: null == categoryCode
            ? _value.categoryCode
            : categoryCode // ignore: cast_nullable_to_non_nullable
                  as String,
        mainTitle: null == mainTitle
            ? _value.mainTitle
            : mainTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value._subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        printText: null == printText
            ? _value.printText
            : printText // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int,
        currentPrice: null == currentPrice
            ? _value.currentPrice
            : currentPrice // ignore: cast_nullable_to_non_nullable
                  as int,
        homeImage: freezed == homeImage
            ? _value.homeImage
            : homeImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        homeImageHttp: freezed == homeImageHttp
            ? _value.homeImageHttp
            : homeImageHttp // ignore: cast_nullable_to_non_nullable
                  as String?,
        images: freezed == images
            ? _value.images
            : images // ignore: cast_nullable_to_non_nullable
                  as dynamic,
        qtyBounds: null == qtyBounds
            ? _value.qtyBounds
            : qtyBounds // ignore: cast_nullable_to_non_nullable
                  as int,
        extend1: freezed == extend1
            ? _value.extend1
            : extend1 // ignore: cast_nullable_to_non_nullable
                  as String?,
        tax: null == tax
            ? _value.tax
            : tax // ignore: cast_nullable_to_non_nullable
                  as int,
        boundsPrice: freezed == boundsPrice
            ? _value.boundsPrice
            : boundsPrice // ignore: cast_nullable_to_non_nullable
                  as int?,
        timeBoundsStart: null == timeBoundsStart
            ? _value._timeBoundsStart
            : timeBoundsStart // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        timeBoundsEnd: null == timeBoundsEnd
            ? _value._timeBoundsEnd
            : timeBoundsEnd // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        optionGroupVoList: null == optionGroupVoList
            ? _value._optionGroupVoList
            : optionGroupVoList // ignore: cast_nullable_to_non_nullable
                  as List<OptionGroupModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MenuItemModelImpl implements _MenuItemModel {
  const _$MenuItemModelImpl({
    required this.menuCode,
    required this.barCode,
    required this.type,
    required this.categoryCode,
    required this.mainTitle,
    final List<String>? subtitle = const <String>[],
    required this.printText,
    required this.price,
    required this.currentPrice,
    required this.homeImage,
    this.homeImageHttp,
    this.images,
    required this.qtyBounds,
    this.extend1,
    required this.tax,
    this.boundsPrice,
    final List<int> timeBoundsStart = const <int>[],
    final List<int> timeBoundsEnd = const <int>[],
    final List<OptionGroupModel> optionGroupVoList = const <OptionGroupModel>[],
  }) : _subtitle = subtitle,
       _timeBoundsStart = timeBoundsStart,
       _timeBoundsEnd = timeBoundsEnd,
       _optionGroupVoList = optionGroupVoList;

  factory _$MenuItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MenuItemModelImplFromJson(json);

  @override
  final String menuCode;
  @override
  final String? barCode;
  @override
  final int type;
  @override
  final String categoryCode;
  @override
  final String mainTitle;
  final List<String>? _subtitle;
  @override
  @JsonKey()
  List<String>? get subtitle {
    final value = _subtitle;
    if (value == null) return null;
    if (_subtitle is EqualUnmodifiableListView) return _subtitle;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String printText;
  @override
  final int price;
  @override
  final int currentPrice;
  @override
  final String? homeImage;
  @override
  final String? homeImageHttp;
  @override
  final dynamic images;
  @override
  final int qtyBounds;
  @override
  final String? extend1;
  @override
  final int tax;
  @override
  final int? boundsPrice;
  final List<int> _timeBoundsStart;
  @override
  @JsonKey()
  List<int> get timeBoundsStart {
    if (_timeBoundsStart is EqualUnmodifiableListView) return _timeBoundsStart;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_timeBoundsStart);
  }

  final List<int> _timeBoundsEnd;
  @override
  @JsonKey()
  List<int> get timeBoundsEnd {
    if (_timeBoundsEnd is EqualUnmodifiableListView) return _timeBoundsEnd;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_timeBoundsEnd);
  }

  final List<OptionGroupModel> _optionGroupVoList;
  @override
  @JsonKey()
  List<OptionGroupModel> get optionGroupVoList {
    if (_optionGroupVoList is EqualUnmodifiableListView)
      return _optionGroupVoList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_optionGroupVoList);
  }

  @override
  String toString() {
    return 'MenuItemModel(menuCode: $menuCode, barCode: $barCode, type: $type, categoryCode: $categoryCode, mainTitle: $mainTitle, subtitle: $subtitle, printText: $printText, price: $price, currentPrice: $currentPrice, homeImage: $homeImage, homeImageHttp: $homeImageHttp, images: $images, qtyBounds: $qtyBounds, extend1: $extend1, tax: $tax, boundsPrice: $boundsPrice, timeBoundsStart: $timeBoundsStart, timeBoundsEnd: $timeBoundsEnd, optionGroupVoList: $optionGroupVoList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MenuItemModelImpl &&
            (identical(other.menuCode, menuCode) ||
                other.menuCode == menuCode) &&
            (identical(other.barCode, barCode) || other.barCode == barCode) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.categoryCode, categoryCode) ||
                other.categoryCode == categoryCode) &&
            (identical(other.mainTitle, mainTitle) ||
                other.mainTitle == mainTitle) &&
            const DeepCollectionEquality().equals(other._subtitle, _subtitle) &&
            (identical(other.printText, printText) ||
                other.printText == printText) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currentPrice, currentPrice) ||
                other.currentPrice == currentPrice) &&
            (identical(other.homeImage, homeImage) ||
                other.homeImage == homeImage) &&
            (identical(other.homeImageHttp, homeImageHttp) ||
                other.homeImageHttp == homeImageHttp) &&
            const DeepCollectionEquality().equals(other.images, images) &&
            (identical(other.qtyBounds, qtyBounds) ||
                other.qtyBounds == qtyBounds) &&
            (identical(other.extend1, extend1) || other.extend1 == extend1) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.boundsPrice, boundsPrice) ||
                other.boundsPrice == boundsPrice) &&
            const DeepCollectionEquality().equals(
              other._timeBoundsStart,
              _timeBoundsStart,
            ) &&
            const DeepCollectionEquality().equals(
              other._timeBoundsEnd,
              _timeBoundsEnd,
            ) &&
            const DeepCollectionEquality().equals(
              other._optionGroupVoList,
              _optionGroupVoList,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    menuCode,
    barCode,
    type,
    categoryCode,
    mainTitle,
    const DeepCollectionEquality().hash(_subtitle),
    printText,
    price,
    currentPrice,
    homeImage,
    homeImageHttp,
    const DeepCollectionEquality().hash(images),
    qtyBounds,
    extend1,
    tax,
    boundsPrice,
    const DeepCollectionEquality().hash(_timeBoundsStart),
    const DeepCollectionEquality().hash(_timeBoundsEnd),
    const DeepCollectionEquality().hash(_optionGroupVoList),
  ]);

  /// Create a copy of MenuItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MenuItemModelImplCopyWith<_$MenuItemModelImpl> get copyWith =>
      __$$MenuItemModelImplCopyWithImpl<_$MenuItemModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MenuItemModelImplToJson(this);
  }
}

abstract class _MenuItemModel implements MenuItemModel {
  const factory _MenuItemModel({
    required final String menuCode,
    required final String? barCode,
    required final int type,
    required final String categoryCode,
    required final String mainTitle,
    final List<String>? subtitle,
    required final String printText,
    required final int price,
    required final int currentPrice,
    required final String? homeImage,
    final String? homeImageHttp,
    final dynamic images,
    required final int qtyBounds,
    final String? extend1,
    required final int tax,
    final int? boundsPrice,
    final List<int> timeBoundsStart,
    final List<int> timeBoundsEnd,
    final List<OptionGroupModel> optionGroupVoList,
  }) = _$MenuItemModelImpl;

  factory _MenuItemModel.fromJson(Map<String, dynamic> json) =
      _$MenuItemModelImpl.fromJson;

  @override
  String get menuCode;
  @override
  String? get barCode;
  @override
  int get type;
  @override
  String get categoryCode;
  @override
  String get mainTitle;
  @override
  List<String>? get subtitle;
  @override
  String get printText;
  @override
  int get price;
  @override
  int get currentPrice;
  @override
  String? get homeImage;
  @override
  String? get homeImageHttp;
  @override
  dynamic get images;
  @override
  int get qtyBounds;
  @override
  String? get extend1;
  @override
  int get tax;
  @override
  int? get boundsPrice;
  @override
  List<int> get timeBoundsStart;
  @override
  List<int> get timeBoundsEnd;
  @override
  List<OptionGroupModel> get optionGroupVoList;

  /// Create a copy of MenuItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MenuItemModelImplCopyWith<_$MenuItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
