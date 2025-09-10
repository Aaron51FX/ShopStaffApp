// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_info_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LanguageModel _$LanguageModelFromJson(Map<String, dynamic> json) {
  return _LanguageModel.fromJson(json);
}

/// @nodoc
mixin _$LanguageModel {
  String get val => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this LanguageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LanguageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LanguageModelCopyWith<LanguageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LanguageModelCopyWith<$Res> {
  factory $LanguageModelCopyWith(
    LanguageModel value,
    $Res Function(LanguageModel) then,
  ) = _$LanguageModelCopyWithImpl<$Res, LanguageModel>;
  @useResult
  $Res call({String val, String name});
}

/// @nodoc
class _$LanguageModelCopyWithImpl<$Res, $Val extends LanguageModel>
    implements $LanguageModelCopyWith<$Res> {
  _$LanguageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LanguageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? val = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            val: null == val
                ? _value.val
                : val // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LanguageModelImplCopyWith<$Res>
    implements $LanguageModelCopyWith<$Res> {
  factory _$$LanguageModelImplCopyWith(
    _$LanguageModelImpl value,
    $Res Function(_$LanguageModelImpl) then,
  ) = __$$LanguageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String val, String name});
}

/// @nodoc
class __$$LanguageModelImplCopyWithImpl<$Res>
    extends _$LanguageModelCopyWithImpl<$Res, _$LanguageModelImpl>
    implements _$$LanguageModelImplCopyWith<$Res> {
  __$$LanguageModelImplCopyWithImpl(
    _$LanguageModelImpl _value,
    $Res Function(_$LanguageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LanguageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? val = null, Object? name = null}) {
    return _then(
      _$LanguageModelImpl(
        val: null == val
            ? _value.val
            : val // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LanguageModelImpl implements _LanguageModel {
  const _$LanguageModelImpl({required this.val, required this.name});

  factory _$LanguageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LanguageModelImplFromJson(json);

  @override
  final String val;
  @override
  final String name;

  @override
  String toString() {
    return 'LanguageModel(val: $val, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LanguageModelImpl &&
            (identical(other.val, val) || other.val == val) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, val, name);

  /// Create a copy of LanguageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LanguageModelImplCopyWith<_$LanguageModelImpl> get copyWith =>
      __$$LanguageModelImplCopyWithImpl<_$LanguageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LanguageModelImplToJson(this);
  }
}

abstract class _LanguageModel implements LanguageModel {
  const factory _LanguageModel({
    required final String val,
    required final String name,
  }) = _$LanguageModelImpl;

  factory _LanguageModel.fromJson(Map<String, dynamic> json) =
      _$LanguageModelImpl.fromJson;

  @override
  String get val;
  @override
  String get name;

  /// Create a copy of LanguageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LanguageModelImplCopyWith<_$LanguageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) {
  return _CategoryModel.fromJson(json);
}

/// @nodoc
mixin _$CategoryModel {
  String get categoryCode => throw _privateConstructorUsedError;
  String get categoryName => throw _privateConstructorUsedError;
  String get showType => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  String? get background => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  int? get printReceipt => throw _privateConstructorUsedError;
  List<dynamic> get menuVoList => throw _privateConstructorUsedError;
  List<int> get recommends => throw _privateConstructorUsedError;
  List<RecommendMenuModel> get recommendMenus =>
      throw _privateConstructorUsedError;

  /// Serializes this CategoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryModelCopyWith<CategoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryModelCopyWith<$Res> {
  factory $CategoryModelCopyWith(
    CategoryModel value,
    $Res Function(CategoryModel) then,
  ) = _$CategoryModelCopyWithImpl<$Res, CategoryModel>;
  @useResult
  $Res call({
    String categoryCode,
    String categoryName,
    String showType,
    String? color,
    String? background,
    String? image,
    int? printReceipt,
    List<dynamic> menuVoList,
    List<int> recommends,
    List<RecommendMenuModel> recommendMenus,
  });
}

/// @nodoc
class _$CategoryModelCopyWithImpl<$Res, $Val extends CategoryModel>
    implements $CategoryModelCopyWith<$Res> {
  _$CategoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryCode = null,
    Object? categoryName = null,
    Object? showType = null,
    Object? color = freezed,
    Object? background = freezed,
    Object? image = freezed,
    Object? printReceipt = freezed,
    Object? menuVoList = null,
    Object? recommends = null,
    Object? recommendMenus = null,
  }) {
    return _then(
      _value.copyWith(
            categoryCode: null == categoryCode
                ? _value.categoryCode
                : categoryCode // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryName: null == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String,
            showType: null == showType
                ? _value.showType
                : showType // ignore: cast_nullable_to_non_nullable
                      as String,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            background: freezed == background
                ? _value.background
                : background // ignore: cast_nullable_to_non_nullable
                      as String?,
            image: freezed == image
                ? _value.image
                : image // ignore: cast_nullable_to_non_nullable
                      as String?,
            printReceipt: freezed == printReceipt
                ? _value.printReceipt
                : printReceipt // ignore: cast_nullable_to_non_nullable
                      as int?,
            menuVoList: null == menuVoList
                ? _value.menuVoList
                : menuVoList // ignore: cast_nullable_to_non_nullable
                      as List<dynamic>,
            recommends: null == recommends
                ? _value.recommends
                : recommends // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            recommendMenus: null == recommendMenus
                ? _value.recommendMenus
                : recommendMenus // ignore: cast_nullable_to_non_nullable
                      as List<RecommendMenuModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryModelImplCopyWith<$Res>
    implements $CategoryModelCopyWith<$Res> {
  factory _$$CategoryModelImplCopyWith(
    _$CategoryModelImpl value,
    $Res Function(_$CategoryModelImpl) then,
  ) = __$$CategoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String categoryCode,
    String categoryName,
    String showType,
    String? color,
    String? background,
    String? image,
    int? printReceipt,
    List<dynamic> menuVoList,
    List<int> recommends,
    List<RecommendMenuModel> recommendMenus,
  });
}

/// @nodoc
class __$$CategoryModelImplCopyWithImpl<$Res>
    extends _$CategoryModelCopyWithImpl<$Res, _$CategoryModelImpl>
    implements _$$CategoryModelImplCopyWith<$Res> {
  __$$CategoryModelImplCopyWithImpl(
    _$CategoryModelImpl _value,
    $Res Function(_$CategoryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryCode = null,
    Object? categoryName = null,
    Object? showType = null,
    Object? color = freezed,
    Object? background = freezed,
    Object? image = freezed,
    Object? printReceipt = freezed,
    Object? menuVoList = null,
    Object? recommends = null,
    Object? recommendMenus = null,
  }) {
    return _then(
      _$CategoryModelImpl(
        categoryCode: null == categoryCode
            ? _value.categoryCode
            : categoryCode // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryName: null == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        showType: null == showType
            ? _value.showType
            : showType // ignore: cast_nullable_to_non_nullable
                  as String,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        background: freezed == background
            ? _value.background
            : background // ignore: cast_nullable_to_non_nullable
                  as String?,
        image: freezed == image
            ? _value.image
            : image // ignore: cast_nullable_to_non_nullable
                  as String?,
        printReceipt: freezed == printReceipt
            ? _value.printReceipt
            : printReceipt // ignore: cast_nullable_to_non_nullable
                  as int?,
        menuVoList: null == menuVoList
            ? _value._menuVoList
            : menuVoList // ignore: cast_nullable_to_non_nullable
                  as List<dynamic>,
        recommends: null == recommends
            ? _value._recommends
            : recommends // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        recommendMenus: null == recommendMenus
            ? _value._recommendMenus
            : recommendMenus // ignore: cast_nullable_to_non_nullable
                  as List<RecommendMenuModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryModelImpl implements _CategoryModel {
  const _$CategoryModelImpl({
    required this.categoryCode,
    required this.categoryName,
    required this.showType,
    this.color,
    this.background,
    this.image,
    this.printReceipt,
    final List<dynamic> menuVoList = const <dynamic>[],
    final List<int> recommends = const <int>[],
    final List<RecommendMenuModel> recommendMenus =
        const <RecommendMenuModel>[],
  }) : _menuVoList = menuVoList,
       _recommends = recommends,
       _recommendMenus = recommendMenus;

  factory _$CategoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryModelImplFromJson(json);

  @override
  final String categoryCode;
  @override
  final String categoryName;
  @override
  final String showType;
  @override
  final String? color;
  @override
  final String? background;
  @override
  final String? image;
  @override
  final int? printReceipt;
  final List<dynamic> _menuVoList;
  @override
  @JsonKey()
  List<dynamic> get menuVoList {
    if (_menuVoList is EqualUnmodifiableListView) return _menuVoList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_menuVoList);
  }

  final List<int> _recommends;
  @override
  @JsonKey()
  List<int> get recommends {
    if (_recommends is EqualUnmodifiableListView) return _recommends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommends);
  }

  final List<RecommendMenuModel> _recommendMenus;
  @override
  @JsonKey()
  List<RecommendMenuModel> get recommendMenus {
    if (_recommendMenus is EqualUnmodifiableListView) return _recommendMenus;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommendMenus);
  }

  @override
  String toString() {
    return 'CategoryModel(categoryCode: $categoryCode, categoryName: $categoryName, showType: $showType, color: $color, background: $background, image: $image, printReceipt: $printReceipt, menuVoList: $menuVoList, recommends: $recommends, recommendMenus: $recommendMenus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryModelImpl &&
            (identical(other.categoryCode, categoryCode) ||
                other.categoryCode == categoryCode) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.showType, showType) ||
                other.showType == showType) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.background, background) ||
                other.background == background) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.printReceipt, printReceipt) ||
                other.printReceipt == printReceipt) &&
            const DeepCollectionEquality().equals(
              other._menuVoList,
              _menuVoList,
            ) &&
            const DeepCollectionEquality().equals(
              other._recommends,
              _recommends,
            ) &&
            const DeepCollectionEquality().equals(
              other._recommendMenus,
              _recommendMenus,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryCode,
    categoryName,
    showType,
    color,
    background,
    image,
    printReceipt,
    const DeepCollectionEquality().hash(_menuVoList),
    const DeepCollectionEquality().hash(_recommends),
    const DeepCollectionEquality().hash(_recommendMenus),
  );

  /// Create a copy of CategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryModelImplCopyWith<_$CategoryModelImpl> get copyWith =>
      __$$CategoryModelImplCopyWithImpl<_$CategoryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryModelImplToJson(this);
  }
}

abstract class _CategoryModel implements CategoryModel {
  const factory _CategoryModel({
    required final String categoryCode,
    required final String categoryName,
    required final String showType,
    final String? color,
    final String? background,
    final String? image,
    final int? printReceipt,
    final List<dynamic> menuVoList,
    final List<int> recommends,
    final List<RecommendMenuModel> recommendMenus,
  }) = _$CategoryModelImpl;

  factory _CategoryModel.fromJson(Map<String, dynamic> json) =
      _$CategoryModelImpl.fromJson;

  @override
  String get categoryCode;
  @override
  String get categoryName;
  @override
  String get showType;
  @override
  String? get color;
  @override
  String? get background;
  @override
  String? get image;
  @override
  int? get printReceipt;
  @override
  List<dynamic> get menuVoList;
  @override
  List<int> get recommends;
  @override
  List<RecommendMenuModel> get recommendMenus;

  /// Create a copy of CategoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryModelImplCopyWith<_$CategoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecommendMenuModel _$RecommendMenuModelFromJson(Map<String, dynamic> json) {
  return _RecommendMenuModel.fromJson(json);
}

/// @nodoc
mixin _$RecommendMenuModel {
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
  String get tax => throw _privateConstructorUsedError;
  int? get boundsPrice => throw _privateConstructorUsedError;
  List<int> get timeBoundsStart => throw _privateConstructorUsedError;
  List<int> get timeBoundsEnd => throw _privateConstructorUsedError;
  List<dynamic> get optionGroupVoList => throw _privateConstructorUsedError;

  /// Serializes this RecommendMenuModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecommendMenuModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecommendMenuModelCopyWith<RecommendMenuModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendMenuModelCopyWith<$Res> {
  factory $RecommendMenuModelCopyWith(
    RecommendMenuModel value,
    $Res Function(RecommendMenuModel) then,
  ) = _$RecommendMenuModelCopyWithImpl<$Res, RecommendMenuModel>;
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
    String tax,
    int? boundsPrice,
    List<int> timeBoundsStart,
    List<int> timeBoundsEnd,
    List<dynamic> optionGroupVoList,
  });
}

/// @nodoc
class _$RecommendMenuModelCopyWithImpl<$Res, $Val extends RecommendMenuModel>
    implements $RecommendMenuModelCopyWith<$Res> {
  _$RecommendMenuModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecommendMenuModel
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
                      as String,
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
                      as List<dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecommendMenuModelImplCopyWith<$Res>
    implements $RecommendMenuModelCopyWith<$Res> {
  factory _$$RecommendMenuModelImplCopyWith(
    _$RecommendMenuModelImpl value,
    $Res Function(_$RecommendMenuModelImpl) then,
  ) = __$$RecommendMenuModelImplCopyWithImpl<$Res>;
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
    String tax,
    int? boundsPrice,
    List<int> timeBoundsStart,
    List<int> timeBoundsEnd,
    List<dynamic> optionGroupVoList,
  });
}

/// @nodoc
class __$$RecommendMenuModelImplCopyWithImpl<$Res>
    extends _$RecommendMenuModelCopyWithImpl<$Res, _$RecommendMenuModelImpl>
    implements _$$RecommendMenuModelImplCopyWith<$Res> {
  __$$RecommendMenuModelImplCopyWithImpl(
    _$RecommendMenuModelImpl _value,
    $Res Function(_$RecommendMenuModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecommendMenuModel
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
      _$RecommendMenuModelImpl(
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
                  as String,
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
                  as List<dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecommendMenuModelImpl implements _RecommendMenuModel {
  const _$RecommendMenuModelImpl({
    required this.menuCode,
    this.barCode,
    required this.type,
    required this.categoryCode,
    required this.mainTitle,
    final List<String>? subtitle,
    required this.printText,
    required this.price,
    required this.currentPrice,
    this.homeImage,
    this.homeImageHttp,
    this.images,
    required this.qtyBounds,
    this.extend1,
    required this.tax,
    this.boundsPrice,
    final List<int> timeBoundsStart = const <int>[],
    final List<int> timeBoundsEnd = const <int>[],
    final List<dynamic> optionGroupVoList = const <dynamic>[],
  }) : _subtitle = subtitle,
       _timeBoundsStart = timeBoundsStart,
       _timeBoundsEnd = timeBoundsEnd,
       _optionGroupVoList = optionGroupVoList;

  factory _$RecommendMenuModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecommendMenuModelImplFromJson(json);

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
  final String tax;
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

  final List<dynamic> _optionGroupVoList;
  @override
  @JsonKey()
  List<dynamic> get optionGroupVoList {
    if (_optionGroupVoList is EqualUnmodifiableListView)
      return _optionGroupVoList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_optionGroupVoList);
  }

  @override
  String toString() {
    return 'RecommendMenuModel(menuCode: $menuCode, barCode: $barCode, type: $type, categoryCode: $categoryCode, mainTitle: $mainTitle, subtitle: $subtitle, printText: $printText, price: $price, currentPrice: $currentPrice, homeImage: $homeImage, homeImageHttp: $homeImageHttp, images: $images, qtyBounds: $qtyBounds, extend1: $extend1, tax: $tax, boundsPrice: $boundsPrice, timeBoundsStart: $timeBoundsStart, timeBoundsEnd: $timeBoundsEnd, optionGroupVoList: $optionGroupVoList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendMenuModelImpl &&
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

  /// Create a copy of RecommendMenuModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendMenuModelImplCopyWith<_$RecommendMenuModelImpl> get copyWith =>
      __$$RecommendMenuModelImplCopyWithImpl<_$RecommendMenuModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecommendMenuModelImplToJson(this);
  }
}

abstract class _RecommendMenuModel implements RecommendMenuModel {
  const factory _RecommendMenuModel({
    required final String menuCode,
    final String? barCode,
    required final int type,
    required final String categoryCode,
    required final String mainTitle,
    final List<String>? subtitle,
    required final String printText,
    required final int price,
    required final int currentPrice,
    final String? homeImage,
    final String? homeImageHttp,
    final dynamic images,
    required final int qtyBounds,
    final String? extend1,
    required final String tax,
    final int? boundsPrice,
    final List<int> timeBoundsStart,
    final List<int> timeBoundsEnd,
    final List<dynamic> optionGroupVoList,
  }) = _$RecommendMenuModelImpl;

  factory _RecommendMenuModel.fromJson(Map<String, dynamic> json) =
      _$RecommendMenuModelImpl.fromJson;

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
  String get tax;
  @override
  int? get boundsPrice;
  @override
  List<int> get timeBoundsStart;
  @override
  List<int> get timeBoundsEnd;
  @override
  List<dynamic> get optionGroupVoList;

  /// Create a copy of RecommendMenuModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecommendMenuModelImplCopyWith<_$RecommendMenuModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShopInfoModel _$ShopInfoModelFromJson(Map<String, dynamic> json) {
  return _ShopInfoModel.fromJson(json);
}

/// @nodoc
mixin _$ShopInfoModel {
  String get shopCode => throw _privateConstructorUsedError;
  String? get machineCode => throw _privateConstructorUsedError;
  List<LanguageModel> get languages => throw _privateConstructorUsedError;
  String get shopName => throw _privateConstructorUsedError;
  String? get ntaNo => throw _privateConstructorUsedError;
  String? get stationMachineCode => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  String? get shopAddress => throw _privateConstructorUsedError;
  String? get shopTelephone => throw _privateConstructorUsedError;
  String? get businessTime => throw _privateConstructorUsedError;
  String? get seatNumber => throw _privateConstructorUsedError;
  List<CategoryModel> get categoryVoList => throw _privateConstructorUsedError;
  bool? get onlineCall => throw _privateConstructorUsedError;
  bool? get taxSystem => throw _privateConstructorUsedError;
  bool? get dynamicCode => throw _privateConstructorUsedError;
  bool? get multiplayer => throw _privateConstructorUsedError;
  String? get canToOrder => throw _privateConstructorUsedError;
  String? get uniqueOrderKey => throw _privateConstructorUsedError;
  Map<String, dynamic>? get linePayChannelMap =>
      throw _privateConstructorUsedError;

  /// Serializes this ShopInfoModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShopInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShopInfoModelCopyWith<ShopInfoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShopInfoModelCopyWith<$Res> {
  factory $ShopInfoModelCopyWith(
    ShopInfoModel value,
    $Res Function(ShopInfoModel) then,
  ) = _$ShopInfoModelCopyWithImpl<$Res, ShopInfoModel>;
  @useResult
  $Res call({
    String shopCode,
    String? machineCode,
    List<LanguageModel> languages,
    String shopName,
    String? ntaNo,
    String? stationMachineCode,
    String language,
    String? shopAddress,
    String? shopTelephone,
    String? businessTime,
    String? seatNumber,
    List<CategoryModel> categoryVoList,
    bool? onlineCall,
    bool? taxSystem,
    bool? dynamicCode,
    bool? multiplayer,
    String? canToOrder,
    String? uniqueOrderKey,
    Map<String, dynamic>? linePayChannelMap,
  });
}

/// @nodoc
class _$ShopInfoModelCopyWithImpl<$Res, $Val extends ShopInfoModel>
    implements $ShopInfoModelCopyWith<$Res> {
  _$ShopInfoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShopInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shopCode = null,
    Object? machineCode = freezed,
    Object? languages = null,
    Object? shopName = null,
    Object? ntaNo = freezed,
    Object? stationMachineCode = freezed,
    Object? language = null,
    Object? shopAddress = freezed,
    Object? shopTelephone = freezed,
    Object? businessTime = freezed,
    Object? seatNumber = freezed,
    Object? categoryVoList = null,
    Object? onlineCall = freezed,
    Object? taxSystem = freezed,
    Object? dynamicCode = freezed,
    Object? multiplayer = freezed,
    Object? canToOrder = freezed,
    Object? uniqueOrderKey = freezed,
    Object? linePayChannelMap = freezed,
  }) {
    return _then(
      _value.copyWith(
            shopCode: null == shopCode
                ? _value.shopCode
                : shopCode // ignore: cast_nullable_to_non_nullable
                      as String,
            machineCode: freezed == machineCode
                ? _value.machineCode
                : machineCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            languages: null == languages
                ? _value.languages
                : languages // ignore: cast_nullable_to_non_nullable
                      as List<LanguageModel>,
            shopName: null == shopName
                ? _value.shopName
                : shopName // ignore: cast_nullable_to_non_nullable
                      as String,
            ntaNo: freezed == ntaNo
                ? _value.ntaNo
                : ntaNo // ignore: cast_nullable_to_non_nullable
                      as String?,
            stationMachineCode: freezed == stationMachineCode
                ? _value.stationMachineCode
                : stationMachineCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            language: null == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String,
            shopAddress: freezed == shopAddress
                ? _value.shopAddress
                : shopAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            shopTelephone: freezed == shopTelephone
                ? _value.shopTelephone
                : shopTelephone // ignore: cast_nullable_to_non_nullable
                      as String?,
            businessTime: freezed == businessTime
                ? _value.businessTime
                : businessTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            seatNumber: freezed == seatNumber
                ? _value.seatNumber
                : seatNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryVoList: null == categoryVoList
                ? _value.categoryVoList
                : categoryVoList // ignore: cast_nullable_to_non_nullable
                      as List<CategoryModel>,
            onlineCall: freezed == onlineCall
                ? _value.onlineCall
                : onlineCall // ignore: cast_nullable_to_non_nullable
                      as bool?,
            taxSystem: freezed == taxSystem
                ? _value.taxSystem
                : taxSystem // ignore: cast_nullable_to_non_nullable
                      as bool?,
            dynamicCode: freezed == dynamicCode
                ? _value.dynamicCode
                : dynamicCode // ignore: cast_nullable_to_non_nullable
                      as bool?,
            multiplayer: freezed == multiplayer
                ? _value.multiplayer
                : multiplayer // ignore: cast_nullable_to_non_nullable
                      as bool?,
            canToOrder: freezed == canToOrder
                ? _value.canToOrder
                : canToOrder // ignore: cast_nullable_to_non_nullable
                      as String?,
            uniqueOrderKey: freezed == uniqueOrderKey
                ? _value.uniqueOrderKey
                : uniqueOrderKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            linePayChannelMap: freezed == linePayChannelMap
                ? _value.linePayChannelMap
                : linePayChannelMap // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShopInfoModelImplCopyWith<$Res>
    implements $ShopInfoModelCopyWith<$Res> {
  factory _$$ShopInfoModelImplCopyWith(
    _$ShopInfoModelImpl value,
    $Res Function(_$ShopInfoModelImpl) then,
  ) = __$$ShopInfoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String shopCode,
    String? machineCode,
    List<LanguageModel> languages,
    String shopName,
    String? ntaNo,
    String? stationMachineCode,
    String language,
    String? shopAddress,
    String? shopTelephone,
    String? businessTime,
    String? seatNumber,
    List<CategoryModel> categoryVoList,
    bool? onlineCall,
    bool? taxSystem,
    bool? dynamicCode,
    bool? multiplayer,
    String? canToOrder,
    String? uniqueOrderKey,
    Map<String, dynamic>? linePayChannelMap,
  });
}

/// @nodoc
class __$$ShopInfoModelImplCopyWithImpl<$Res>
    extends _$ShopInfoModelCopyWithImpl<$Res, _$ShopInfoModelImpl>
    implements _$$ShopInfoModelImplCopyWith<$Res> {
  __$$ShopInfoModelImplCopyWithImpl(
    _$ShopInfoModelImpl _value,
    $Res Function(_$ShopInfoModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShopInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shopCode = null,
    Object? machineCode = freezed,
    Object? languages = null,
    Object? shopName = null,
    Object? ntaNo = freezed,
    Object? stationMachineCode = freezed,
    Object? language = null,
    Object? shopAddress = freezed,
    Object? shopTelephone = freezed,
    Object? businessTime = freezed,
    Object? seatNumber = freezed,
    Object? categoryVoList = null,
    Object? onlineCall = freezed,
    Object? taxSystem = freezed,
    Object? dynamicCode = freezed,
    Object? multiplayer = freezed,
    Object? canToOrder = freezed,
    Object? uniqueOrderKey = freezed,
    Object? linePayChannelMap = freezed,
  }) {
    return _then(
      _$ShopInfoModelImpl(
        shopCode: null == shopCode
            ? _value.shopCode
            : shopCode // ignore: cast_nullable_to_non_nullable
                  as String,
        machineCode: freezed == machineCode
            ? _value.machineCode
            : machineCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        languages: null == languages
            ? _value._languages
            : languages // ignore: cast_nullable_to_non_nullable
                  as List<LanguageModel>,
        shopName: null == shopName
            ? _value.shopName
            : shopName // ignore: cast_nullable_to_non_nullable
                  as String,
        ntaNo: freezed == ntaNo
            ? _value.ntaNo
            : ntaNo // ignore: cast_nullable_to_non_nullable
                  as String?,
        stationMachineCode: freezed == stationMachineCode
            ? _value.stationMachineCode
            : stationMachineCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        language: null == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
        shopAddress: freezed == shopAddress
            ? _value.shopAddress
            : shopAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        shopTelephone: freezed == shopTelephone
            ? _value.shopTelephone
            : shopTelephone // ignore: cast_nullable_to_non_nullable
                  as String?,
        businessTime: freezed == businessTime
            ? _value.businessTime
            : businessTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        seatNumber: freezed == seatNumber
            ? _value.seatNumber
            : seatNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryVoList: null == categoryVoList
            ? _value._categoryVoList
            : categoryVoList // ignore: cast_nullable_to_non_nullable
                  as List<CategoryModel>,
        onlineCall: freezed == onlineCall
            ? _value.onlineCall
            : onlineCall // ignore: cast_nullable_to_non_nullable
                  as bool?,
        taxSystem: freezed == taxSystem
            ? _value.taxSystem
            : taxSystem // ignore: cast_nullable_to_non_nullable
                  as bool?,
        dynamicCode: freezed == dynamicCode
            ? _value.dynamicCode
            : dynamicCode // ignore: cast_nullable_to_non_nullable
                  as bool?,
        multiplayer: freezed == multiplayer
            ? _value.multiplayer
            : multiplayer // ignore: cast_nullable_to_non_nullable
                  as bool?,
        canToOrder: freezed == canToOrder
            ? _value.canToOrder
            : canToOrder // ignore: cast_nullable_to_non_nullable
                  as String?,
        uniqueOrderKey: freezed == uniqueOrderKey
            ? _value.uniqueOrderKey
            : uniqueOrderKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        linePayChannelMap: freezed == linePayChannelMap
            ? _value._linePayChannelMap
            : linePayChannelMap // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShopInfoModelImpl implements _ShopInfoModel {
  const _$ShopInfoModelImpl({
    required this.shopCode,
    this.machineCode,
    final List<LanguageModel> languages = const <LanguageModel>[],
    required this.shopName,
    this.ntaNo,
    this.stationMachineCode,
    required this.language,
    this.shopAddress,
    this.shopTelephone,
    this.businessTime,
    this.seatNumber,
    final List<CategoryModel> categoryVoList = const <CategoryModel>[],
    this.onlineCall,
    this.taxSystem,
    this.dynamicCode,
    this.multiplayer,
    this.canToOrder,
    this.uniqueOrderKey,
    final Map<String, dynamic>? linePayChannelMap,
  }) : _languages = languages,
       _categoryVoList = categoryVoList,
       _linePayChannelMap = linePayChannelMap;

  factory _$ShopInfoModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShopInfoModelImplFromJson(json);

  @override
  final String shopCode;
  @override
  final String? machineCode;
  final List<LanguageModel> _languages;
  @override
  @JsonKey()
  List<LanguageModel> get languages {
    if (_languages is EqualUnmodifiableListView) return _languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_languages);
  }

  @override
  final String shopName;
  @override
  final String? ntaNo;
  @override
  final String? stationMachineCode;
  @override
  final String language;
  @override
  final String? shopAddress;
  @override
  final String? shopTelephone;
  @override
  final String? businessTime;
  @override
  final String? seatNumber;
  final List<CategoryModel> _categoryVoList;
  @override
  @JsonKey()
  List<CategoryModel> get categoryVoList {
    if (_categoryVoList is EqualUnmodifiableListView) return _categoryVoList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryVoList);
  }

  @override
  final bool? onlineCall;
  @override
  final bool? taxSystem;
  @override
  final bool? dynamicCode;
  @override
  final bool? multiplayer;
  @override
  final String? canToOrder;
  @override
  final String? uniqueOrderKey;
  final Map<String, dynamic>? _linePayChannelMap;
  @override
  Map<String, dynamic>? get linePayChannelMap {
    final value = _linePayChannelMap;
    if (value == null) return null;
    if (_linePayChannelMap is EqualUnmodifiableMapView)
      return _linePayChannelMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ShopInfoModel(shopCode: $shopCode, machineCode: $machineCode, languages: $languages, shopName: $shopName, ntaNo: $ntaNo, stationMachineCode: $stationMachineCode, language: $language, shopAddress: $shopAddress, shopTelephone: $shopTelephone, businessTime: $businessTime, seatNumber: $seatNumber, categoryVoList: $categoryVoList, onlineCall: $onlineCall, taxSystem: $taxSystem, dynamicCode: $dynamicCode, multiplayer: $multiplayer, canToOrder: $canToOrder, uniqueOrderKey: $uniqueOrderKey, linePayChannelMap: $linePayChannelMap)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShopInfoModelImpl &&
            (identical(other.shopCode, shopCode) ||
                other.shopCode == shopCode) &&
            (identical(other.machineCode, machineCode) ||
                other.machineCode == machineCode) &&
            const DeepCollectionEquality().equals(
              other._languages,
              _languages,
            ) &&
            (identical(other.shopName, shopName) ||
                other.shopName == shopName) &&
            (identical(other.ntaNo, ntaNo) || other.ntaNo == ntaNo) &&
            (identical(other.stationMachineCode, stationMachineCode) ||
                other.stationMachineCode == stationMachineCode) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.shopAddress, shopAddress) ||
                other.shopAddress == shopAddress) &&
            (identical(other.shopTelephone, shopTelephone) ||
                other.shopTelephone == shopTelephone) &&
            (identical(other.businessTime, businessTime) ||
                other.businessTime == businessTime) &&
            (identical(other.seatNumber, seatNumber) ||
                other.seatNumber == seatNumber) &&
            const DeepCollectionEquality().equals(
              other._categoryVoList,
              _categoryVoList,
            ) &&
            (identical(other.onlineCall, onlineCall) ||
                other.onlineCall == onlineCall) &&
            (identical(other.taxSystem, taxSystem) ||
                other.taxSystem == taxSystem) &&
            (identical(other.dynamicCode, dynamicCode) ||
                other.dynamicCode == dynamicCode) &&
            (identical(other.multiplayer, multiplayer) ||
                other.multiplayer == multiplayer) &&
            (identical(other.canToOrder, canToOrder) ||
                other.canToOrder == canToOrder) &&
            (identical(other.uniqueOrderKey, uniqueOrderKey) ||
                other.uniqueOrderKey == uniqueOrderKey) &&
            const DeepCollectionEquality().equals(
              other._linePayChannelMap,
              _linePayChannelMap,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    shopCode,
    machineCode,
    const DeepCollectionEquality().hash(_languages),
    shopName,
    ntaNo,
    stationMachineCode,
    language,
    shopAddress,
    shopTelephone,
    businessTime,
    seatNumber,
    const DeepCollectionEquality().hash(_categoryVoList),
    onlineCall,
    taxSystem,
    dynamicCode,
    multiplayer,
    canToOrder,
    uniqueOrderKey,
    const DeepCollectionEquality().hash(_linePayChannelMap),
  ]);

  /// Create a copy of ShopInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShopInfoModelImplCopyWith<_$ShopInfoModelImpl> get copyWith =>
      __$$ShopInfoModelImplCopyWithImpl<_$ShopInfoModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShopInfoModelImplToJson(this);
  }
}

abstract class _ShopInfoModel implements ShopInfoModel {
  const factory _ShopInfoModel({
    required final String shopCode,
    final String? machineCode,
    final List<LanguageModel> languages,
    required final String shopName,
    final String? ntaNo,
    final String? stationMachineCode,
    required final String language,
    final String? shopAddress,
    final String? shopTelephone,
    final String? businessTime,
    final String? seatNumber,
    final List<CategoryModel> categoryVoList,
    final bool? onlineCall,
    final bool? taxSystem,
    final bool? dynamicCode,
    final bool? multiplayer,
    final String? canToOrder,
    final String? uniqueOrderKey,
    final Map<String, dynamic>? linePayChannelMap,
  }) = _$ShopInfoModelImpl;

  factory _ShopInfoModel.fromJson(Map<String, dynamic> json) =
      _$ShopInfoModelImpl.fromJson;

  @override
  String get shopCode;
  @override
  String? get machineCode;
  @override
  List<LanguageModel> get languages;
  @override
  String get shopName;
  @override
  String? get ntaNo;
  @override
  String? get stationMachineCode;
  @override
  String get language;
  @override
  String? get shopAddress;
  @override
  String? get shopTelephone;
  @override
  String? get businessTime;
  @override
  String? get seatNumber;
  @override
  List<CategoryModel> get categoryVoList;
  @override
  bool? get onlineCall;
  @override
  bool? get taxSystem;
  @override
  bool? get dynamicCode;
  @override
  bool? get multiplayer;
  @override
  String? get canToOrder;
  @override
  String? get uniqueOrderKey;
  @override
  Map<String, dynamic>? get linePayChannelMap;

  /// Create a copy of ShopInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShopInfoModelImplCopyWith<_$ShopInfoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
