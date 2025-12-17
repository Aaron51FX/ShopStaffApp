// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'print_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PrintInfoDocument _$PrintInfoDocumentFromJson(Map<String, dynamic> json) {
  return _PrintInfoDocument.fromJson(json);
}

/// @nodoc
mixin _$PrintInfoDocument {
  String get shopName => throw _privateConstructorUsedError;
  String get shopCode => throw _privateConstructorUsedError;
  String get orderDate => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get telNo => throw _privateConstructorUsedError;
  String get ntaNo => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get orderType => throw _privateConstructorUsedError;
  String get numberTip => throw _privateConstructorUsedError;
  String? get serialNo => throw _privateConstructorUsedError;
  String? get serialNumber => throw _privateConstructorUsedError;
  String? get serialNumberText => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get orderId => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  bool get takeOut => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get price => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get tax => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get tax1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get baseTax1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get tax2 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get baseTax2 => throw _privateConstructorUsedError;
  String get order => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get payPrice => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get change => throw _privateConstructorUsedError;
  String? get payDate => throw _privateConstructorUsedError;
  String? get memberNo => throw _privateConstructorUsedError;
  String get payMethod => throw _privateConstructorUsedError;
  List<dynamic>? get details => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get discount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get originalPrice => throw _privateConstructorUsedError;
  String get orderTime => throw _privateConstructorUsedError;
  PrintTicketInfo? get printInfo => throw _privateConstructorUsedError;

  /// Serializes this PrintInfoDocument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrintInfoDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrintInfoDocumentCopyWith<PrintInfoDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrintInfoDocumentCopyWith<$Res> {
  factory $PrintInfoDocumentCopyWith(
    PrintInfoDocument value,
    $Res Function(PrintInfoDocument) then,
  ) = _$PrintInfoDocumentCopyWithImpl<$Res, PrintInfoDocument>;
  @useResult
  $Res call({
    String shopName,
    String shopCode,
    String orderDate,
    String address,
    String telNo,
    String ntaNo,
    @JsonKey(fromJson: _toInt) int orderType,
    String numberTip,
    String? serialNo,
    String? serialNumber,
    String? serialNumberText,
    @JsonKey(fromJson: _toInt) int orderId,
    String language,
    bool takeOut,
    @JsonKey(fromJson: _toInt) int price,
    @JsonKey(fromJson: _toInt) int tax,
    @JsonKey(fromJson: _toInt) int tax1,
    @JsonKey(fromJson: _toInt) int baseTax1,
    @JsonKey(fromJson: _toInt) int tax2,
    @JsonKey(fromJson: _toInt) int baseTax2,
    String order,
    @JsonKey(fromJson: _toInt) int payPrice,
    @JsonKey(fromJson: _toInt) int change,
    String? payDate,
    String? memberNo,
    String payMethod,
    List<dynamic>? details,
    @JsonKey(fromJson: _toInt) int discount,
    @JsonKey(fromJson: _toInt) int originalPrice,
    String orderTime,
    PrintTicketInfo? printInfo,
  });

  $PrintTicketInfoCopyWith<$Res>? get printInfo;
}

/// @nodoc
class _$PrintInfoDocumentCopyWithImpl<$Res, $Val extends PrintInfoDocument>
    implements $PrintInfoDocumentCopyWith<$Res> {
  _$PrintInfoDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrintInfoDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shopName = null,
    Object? shopCode = null,
    Object? orderDate = null,
    Object? address = null,
    Object? telNo = null,
    Object? ntaNo = null,
    Object? orderType = null,
    Object? numberTip = null,
    Object? serialNo = freezed,
    Object? serialNumber = freezed,
    Object? serialNumberText = freezed,
    Object? orderId = null,
    Object? language = null,
    Object? takeOut = null,
    Object? price = null,
    Object? tax = null,
    Object? tax1 = null,
    Object? baseTax1 = null,
    Object? tax2 = null,
    Object? baseTax2 = null,
    Object? order = null,
    Object? payPrice = null,
    Object? change = null,
    Object? payDate = freezed,
    Object? memberNo = freezed,
    Object? payMethod = null,
    Object? details = freezed,
    Object? discount = null,
    Object? originalPrice = null,
    Object? orderTime = null,
    Object? printInfo = freezed,
  }) {
    return _then(
      _value.copyWith(
            shopName: null == shopName
                ? _value.shopName
                : shopName // ignore: cast_nullable_to_non_nullable
                      as String,
            shopCode: null == shopCode
                ? _value.shopCode
                : shopCode // ignore: cast_nullable_to_non_nullable
                      as String,
            orderDate: null == orderDate
                ? _value.orderDate
                : orderDate // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            telNo: null == telNo
                ? _value.telNo
                : telNo // ignore: cast_nullable_to_non_nullable
                      as String,
            ntaNo: null == ntaNo
                ? _value.ntaNo
                : ntaNo // ignore: cast_nullable_to_non_nullable
                      as String,
            orderType: null == orderType
                ? _value.orderType
                : orderType // ignore: cast_nullable_to_non_nullable
                      as int,
            numberTip: null == numberTip
                ? _value.numberTip
                : numberTip // ignore: cast_nullable_to_non_nullable
                      as String,
            serialNo: freezed == serialNo
                ? _value.serialNo
                : serialNo // ignore: cast_nullable_to_non_nullable
                      as String?,
            serialNumber: freezed == serialNumber
                ? _value.serialNumber
                : serialNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            serialNumberText: freezed == serialNumberText
                ? _value.serialNumberText
                : serialNumberText // ignore: cast_nullable_to_non_nullable
                      as String?,
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as int,
            language: null == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String,
            takeOut: null == takeOut
                ? _value.takeOut
                : takeOut // ignore: cast_nullable_to_non_nullable
                      as bool,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int,
            tax: null == tax
                ? _value.tax
                : tax // ignore: cast_nullable_to_non_nullable
                      as int,
            tax1: null == tax1
                ? _value.tax1
                : tax1 // ignore: cast_nullable_to_non_nullable
                      as int,
            baseTax1: null == baseTax1
                ? _value.baseTax1
                : baseTax1 // ignore: cast_nullable_to_non_nullable
                      as int,
            tax2: null == tax2
                ? _value.tax2
                : tax2 // ignore: cast_nullable_to_non_nullable
                      as int,
            baseTax2: null == baseTax2
                ? _value.baseTax2
                : baseTax2 // ignore: cast_nullable_to_non_nullable
                      as int,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as String,
            payPrice: null == payPrice
                ? _value.payPrice
                : payPrice // ignore: cast_nullable_to_non_nullable
                      as int,
            change: null == change
                ? _value.change
                : change // ignore: cast_nullable_to_non_nullable
                      as int,
            payDate: freezed == payDate
                ? _value.payDate
                : payDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberNo: freezed == memberNo
                ? _value.memberNo
                : memberNo // ignore: cast_nullable_to_non_nullable
                      as String?,
            payMethod: null == payMethod
                ? _value.payMethod
                : payMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as List<dynamic>?,
            discount: null == discount
                ? _value.discount
                : discount // ignore: cast_nullable_to_non_nullable
                      as int,
            originalPrice: null == originalPrice
                ? _value.originalPrice
                : originalPrice // ignore: cast_nullable_to_non_nullable
                      as int,
            orderTime: null == orderTime
                ? _value.orderTime
                : orderTime // ignore: cast_nullable_to_non_nullable
                      as String,
            printInfo: freezed == printInfo
                ? _value.printInfo
                : printInfo // ignore: cast_nullable_to_non_nullable
                      as PrintTicketInfo?,
          )
          as $Val,
    );
  }

  /// Create a copy of PrintInfoDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrintTicketInfoCopyWith<$Res>? get printInfo {
    if (_value.printInfo == null) {
      return null;
    }

    return $PrintTicketInfoCopyWith<$Res>(_value.printInfo!, (value) {
      return _then(_value.copyWith(printInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PrintInfoDocumentImplCopyWith<$Res>
    implements $PrintInfoDocumentCopyWith<$Res> {
  factory _$$PrintInfoDocumentImplCopyWith(
    _$PrintInfoDocumentImpl value,
    $Res Function(_$PrintInfoDocumentImpl) then,
  ) = __$$PrintInfoDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String shopName,
    String shopCode,
    String orderDate,
    String address,
    String telNo,
    String ntaNo,
    @JsonKey(fromJson: _toInt) int orderType,
    String numberTip,
    String? serialNo,
    String? serialNumber,
    String? serialNumberText,
    @JsonKey(fromJson: _toInt) int orderId,
    String language,
    bool takeOut,
    @JsonKey(fromJson: _toInt) int price,
    @JsonKey(fromJson: _toInt) int tax,
    @JsonKey(fromJson: _toInt) int tax1,
    @JsonKey(fromJson: _toInt) int baseTax1,
    @JsonKey(fromJson: _toInt) int tax2,
    @JsonKey(fromJson: _toInt) int baseTax2,
    String order,
    @JsonKey(fromJson: _toInt) int payPrice,
    @JsonKey(fromJson: _toInt) int change,
    String? payDate,
    String? memberNo,
    String payMethod,
    List<dynamic>? details,
    @JsonKey(fromJson: _toInt) int discount,
    @JsonKey(fromJson: _toInt) int originalPrice,
    String orderTime,
    PrintTicketInfo? printInfo,
  });

  @override
  $PrintTicketInfoCopyWith<$Res>? get printInfo;
}

/// @nodoc
class __$$PrintInfoDocumentImplCopyWithImpl<$Res>
    extends _$PrintInfoDocumentCopyWithImpl<$Res, _$PrintInfoDocumentImpl>
    implements _$$PrintInfoDocumentImplCopyWith<$Res> {
  __$$PrintInfoDocumentImplCopyWithImpl(
    _$PrintInfoDocumentImpl _value,
    $Res Function(_$PrintInfoDocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrintInfoDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shopName = null,
    Object? shopCode = null,
    Object? orderDate = null,
    Object? address = null,
    Object? telNo = null,
    Object? ntaNo = null,
    Object? orderType = null,
    Object? numberTip = null,
    Object? serialNo = freezed,
    Object? serialNumber = freezed,
    Object? serialNumberText = freezed,
    Object? orderId = null,
    Object? language = null,
    Object? takeOut = null,
    Object? price = null,
    Object? tax = null,
    Object? tax1 = null,
    Object? baseTax1 = null,
    Object? tax2 = null,
    Object? baseTax2 = null,
    Object? order = null,
    Object? payPrice = null,
    Object? change = null,
    Object? payDate = freezed,
    Object? memberNo = freezed,
    Object? payMethod = null,
    Object? details = freezed,
    Object? discount = null,
    Object? originalPrice = null,
    Object? orderTime = null,
    Object? printInfo = freezed,
  }) {
    return _then(
      _$PrintInfoDocumentImpl(
        shopName: null == shopName
            ? _value.shopName
            : shopName // ignore: cast_nullable_to_non_nullable
                  as String,
        shopCode: null == shopCode
            ? _value.shopCode
            : shopCode // ignore: cast_nullable_to_non_nullable
                  as String,
        orderDate: null == orderDate
            ? _value.orderDate
            : orderDate // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        telNo: null == telNo
            ? _value.telNo
            : telNo // ignore: cast_nullable_to_non_nullable
                  as String,
        ntaNo: null == ntaNo
            ? _value.ntaNo
            : ntaNo // ignore: cast_nullable_to_non_nullable
                  as String,
        orderType: null == orderType
            ? _value.orderType
            : orderType // ignore: cast_nullable_to_non_nullable
                  as int,
        numberTip: null == numberTip
            ? _value.numberTip
            : numberTip // ignore: cast_nullable_to_non_nullable
                  as String,
        serialNo: freezed == serialNo
            ? _value.serialNo
            : serialNo // ignore: cast_nullable_to_non_nullable
                  as String?,
        serialNumber: freezed == serialNumber
            ? _value.serialNumber
            : serialNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        serialNumberText: freezed == serialNumberText
            ? _value.serialNumberText
            : serialNumberText // ignore: cast_nullable_to_non_nullable
                  as String?,
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as int,
        language: null == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
        takeOut: null == takeOut
            ? _value.takeOut
            : takeOut // ignore: cast_nullable_to_non_nullable
                  as bool,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int,
        tax: null == tax
            ? _value.tax
            : tax // ignore: cast_nullable_to_non_nullable
                  as int,
        tax1: null == tax1
            ? _value.tax1
            : tax1 // ignore: cast_nullable_to_non_nullable
                  as int,
        baseTax1: null == baseTax1
            ? _value.baseTax1
            : baseTax1 // ignore: cast_nullable_to_non_nullable
                  as int,
        tax2: null == tax2
            ? _value.tax2
            : tax2 // ignore: cast_nullable_to_non_nullable
                  as int,
        baseTax2: null == baseTax2
            ? _value.baseTax2
            : baseTax2 // ignore: cast_nullable_to_non_nullable
                  as int,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as String,
        payPrice: null == payPrice
            ? _value.payPrice
            : payPrice // ignore: cast_nullable_to_non_nullable
                  as int,
        change: null == change
            ? _value.change
            : change // ignore: cast_nullable_to_non_nullable
                  as int,
        payDate: freezed == payDate
            ? _value.payDate
            : payDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberNo: freezed == memberNo
            ? _value.memberNo
            : memberNo // ignore: cast_nullable_to_non_nullable
                  as String?,
        payMethod: null == payMethod
            ? _value.payMethod
            : payMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        details: freezed == details
            ? _value._details
            : details // ignore: cast_nullable_to_non_nullable
                  as List<dynamic>?,
        discount: null == discount
            ? _value.discount
            : discount // ignore: cast_nullable_to_non_nullable
                  as int,
        originalPrice: null == originalPrice
            ? _value.originalPrice
            : originalPrice // ignore: cast_nullable_to_non_nullable
                  as int,
        orderTime: null == orderTime
            ? _value.orderTime
            : orderTime // ignore: cast_nullable_to_non_nullable
                  as String,
        printInfo: freezed == printInfo
            ? _value.printInfo
            : printInfo // ignore: cast_nullable_to_non_nullable
                  as PrintTicketInfo?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrintInfoDocumentImpl implements _PrintInfoDocument {
  const _$PrintInfoDocumentImpl({
    this.shopName = '',
    this.shopCode = '',
    this.orderDate = '',
    this.address = '',
    this.telNo = '',
    this.ntaNo = '',
    @JsonKey(fromJson: _toInt) this.orderType = 0,
    this.numberTip = '',
    this.serialNo,
    this.serialNumber,
    this.serialNumberText,
    @JsonKey(fromJson: _toInt) this.orderId = 0,
    this.language = 'JP',
    this.takeOut = false,
    @JsonKey(fromJson: _toInt) this.price = 0,
    @JsonKey(fromJson: _toInt) this.tax = 0,
    @JsonKey(fromJson: _toInt) this.tax1 = 0,
    @JsonKey(fromJson: _toInt) this.baseTax1 = 0,
    @JsonKey(fromJson: _toInt) this.tax2 = 0,
    @JsonKey(fromJson: _toInt) this.baseTax2 = 0,
    this.order = '',
    @JsonKey(fromJson: _toInt) this.payPrice = 0,
    @JsonKey(fromJson: _toInt) this.change = 0,
    this.payDate,
    this.memberNo,
    this.payMethod = '',
    final List<dynamic>? details,
    @JsonKey(fromJson: _toInt) this.discount = 0,
    @JsonKey(fromJson: _toInt) this.originalPrice = 0,
    this.orderTime = '',
    this.printInfo,
  }) : _details = details;

  factory _$PrintInfoDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrintInfoDocumentImplFromJson(json);

  @override
  @JsonKey()
  final String shopName;
  @override
  @JsonKey()
  final String shopCode;
  @override
  @JsonKey()
  final String orderDate;
  @override
  @JsonKey()
  final String address;
  @override
  @JsonKey()
  final String telNo;
  @override
  @JsonKey()
  final String ntaNo;
  @override
  @JsonKey(fromJson: _toInt)
  final int orderType;
  @override
  @JsonKey()
  final String numberTip;
  @override
  final String? serialNo;
  @override
  final String? serialNumber;
  @override
  final String? serialNumberText;
  @override
  @JsonKey(fromJson: _toInt)
  final int orderId;
  @override
  @JsonKey()
  final String language;
  @override
  @JsonKey()
  final bool takeOut;
  @override
  @JsonKey(fromJson: _toInt)
  final int price;
  @override
  @JsonKey(fromJson: _toInt)
  final int tax;
  @override
  @JsonKey(fromJson: _toInt)
  final int tax1;
  @override
  @JsonKey(fromJson: _toInt)
  final int baseTax1;
  @override
  @JsonKey(fromJson: _toInt)
  final int tax2;
  @override
  @JsonKey(fromJson: _toInt)
  final int baseTax2;
  @override
  @JsonKey()
  final String order;
  @override
  @JsonKey(fromJson: _toInt)
  final int payPrice;
  @override
  @JsonKey(fromJson: _toInt)
  final int change;
  @override
  final String? payDate;
  @override
  final String? memberNo;
  @override
  @JsonKey()
  final String payMethod;
  final List<dynamic>? _details;
  @override
  List<dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableListView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(fromJson: _toInt)
  final int discount;
  @override
  @JsonKey(fromJson: _toInt)
  final int originalPrice;
  @override
  @JsonKey()
  final String orderTime;
  @override
  final PrintTicketInfo? printInfo;

  @override
  String toString() {
    return 'PrintInfoDocument(shopName: $shopName, shopCode: $shopCode, orderDate: $orderDate, address: $address, telNo: $telNo, ntaNo: $ntaNo, orderType: $orderType, numberTip: $numberTip, serialNo: $serialNo, serialNumber: $serialNumber, serialNumberText: $serialNumberText, orderId: $orderId, language: $language, takeOut: $takeOut, price: $price, tax: $tax, tax1: $tax1, baseTax1: $baseTax1, tax2: $tax2, baseTax2: $baseTax2, order: $order, payPrice: $payPrice, change: $change, payDate: $payDate, memberNo: $memberNo, payMethod: $payMethod, details: $details, discount: $discount, originalPrice: $originalPrice, orderTime: $orderTime, printInfo: $printInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrintInfoDocumentImpl &&
            (identical(other.shopName, shopName) ||
                other.shopName == shopName) &&
            (identical(other.shopCode, shopCode) ||
                other.shopCode == shopCode) &&
            (identical(other.orderDate, orderDate) ||
                other.orderDate == orderDate) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.telNo, telNo) || other.telNo == telNo) &&
            (identical(other.ntaNo, ntaNo) || other.ntaNo == ntaNo) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.numberTip, numberTip) ||
                other.numberTip == numberTip) &&
            (identical(other.serialNo, serialNo) ||
                other.serialNo == serialNo) &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.serialNumberText, serialNumberText) ||
                other.serialNumberText == serialNumberText) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.takeOut, takeOut) || other.takeOut == takeOut) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.tax1, tax1) || other.tax1 == tax1) &&
            (identical(other.baseTax1, baseTax1) ||
                other.baseTax1 == baseTax1) &&
            (identical(other.tax2, tax2) || other.tax2 == tax2) &&
            (identical(other.baseTax2, baseTax2) ||
                other.baseTax2 == baseTax2) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.payPrice, payPrice) ||
                other.payPrice == payPrice) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.payDate, payDate) || other.payDate == payDate) &&
            (identical(other.memberNo, memberNo) ||
                other.memberNo == memberNo) &&
            (identical(other.payMethod, payMethod) ||
                other.payMethod == payMethod) &&
            const DeepCollectionEquality().equals(other._details, _details) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.originalPrice, originalPrice) ||
                other.originalPrice == originalPrice) &&
            (identical(other.orderTime, orderTime) ||
                other.orderTime == orderTime) &&
            (identical(other.printInfo, printInfo) ||
                other.printInfo == printInfo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    shopName,
    shopCode,
    orderDate,
    address,
    telNo,
    ntaNo,
    orderType,
    numberTip,
    serialNo,
    serialNumber,
    serialNumberText,
    orderId,
    language,
    takeOut,
    price,
    tax,
    tax1,
    baseTax1,
    tax2,
    baseTax2,
    order,
    payPrice,
    change,
    payDate,
    memberNo,
    payMethod,
    const DeepCollectionEquality().hash(_details),
    discount,
    originalPrice,
    orderTime,
    printInfo,
  ]);

  /// Create a copy of PrintInfoDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrintInfoDocumentImplCopyWith<_$PrintInfoDocumentImpl> get copyWith =>
      __$$PrintInfoDocumentImplCopyWithImpl<_$PrintInfoDocumentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PrintInfoDocumentImplToJson(this);
  }
}

abstract class _PrintInfoDocument implements PrintInfoDocument {
  const factory _PrintInfoDocument({
    final String shopName,
    final String shopCode,
    final String orderDate,
    final String address,
    final String telNo,
    final String ntaNo,
    @JsonKey(fromJson: _toInt) final int orderType,
    final String numberTip,
    final String? serialNo,
    final String? serialNumber,
    final String? serialNumberText,
    @JsonKey(fromJson: _toInt) final int orderId,
    final String language,
    final bool takeOut,
    @JsonKey(fromJson: _toInt) final int price,
    @JsonKey(fromJson: _toInt) final int tax,
    @JsonKey(fromJson: _toInt) final int tax1,
    @JsonKey(fromJson: _toInt) final int baseTax1,
    @JsonKey(fromJson: _toInt) final int tax2,
    @JsonKey(fromJson: _toInt) final int baseTax2,
    final String order,
    @JsonKey(fromJson: _toInt) final int payPrice,
    @JsonKey(fromJson: _toInt) final int change,
    final String? payDate,
    final String? memberNo,
    final String payMethod,
    final List<dynamic>? details,
    @JsonKey(fromJson: _toInt) final int discount,
    @JsonKey(fromJson: _toInt) final int originalPrice,
    final String orderTime,
    final PrintTicketInfo? printInfo,
  }) = _$PrintInfoDocumentImpl;

  factory _PrintInfoDocument.fromJson(Map<String, dynamic> json) =
      _$PrintInfoDocumentImpl.fromJson;

  @override
  String get shopName;
  @override
  String get shopCode;
  @override
  String get orderDate;
  @override
  String get address;
  @override
  String get telNo;
  @override
  String get ntaNo;
  @override
  @JsonKey(fromJson: _toInt)
  int get orderType;
  @override
  String get numberTip;
  @override
  String? get serialNo;
  @override
  String? get serialNumber;
  @override
  String? get serialNumberText;
  @override
  @JsonKey(fromJson: _toInt)
  int get orderId;
  @override
  String get language;
  @override
  bool get takeOut;
  @override
  @JsonKey(fromJson: _toInt)
  int get price;
  @override
  @JsonKey(fromJson: _toInt)
  int get tax;
  @override
  @JsonKey(fromJson: _toInt)
  int get tax1;
  @override
  @JsonKey(fromJson: _toInt)
  int get baseTax1;
  @override
  @JsonKey(fromJson: _toInt)
  int get tax2;
  @override
  @JsonKey(fromJson: _toInt)
  int get baseTax2;
  @override
  String get order;
  @override
  @JsonKey(fromJson: _toInt)
  int get payPrice;
  @override
  @JsonKey(fromJson: _toInt)
  int get change;
  @override
  String? get payDate;
  @override
  String? get memberNo;
  @override
  String get payMethod;
  @override
  List<dynamic>? get details;
  @override
  @JsonKey(fromJson: _toInt)
  int get discount;
  @override
  @JsonKey(fromJson: _toInt)
  int get originalPrice;
  @override
  String get orderTime;
  @override
  PrintTicketInfo? get printInfo;

  /// Create a copy of PrintInfoDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrintInfoDocumentImplCopyWith<_$PrintInfoDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrintTicketInfo _$PrintTicketInfoFromJson(Map<String, dynamic> json) {
  return _PrintTicketInfo.fromJson(json);
}

/// @nodoc
mixin _$PrintTicketInfo {
  String? get uuid => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get bizId => throw _privateConstructorUsedError;
  String get orderTime => throw _privateConstructorUsedError;
  String get remark => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_plate')
  String get fromPlate => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_sn_code')
  String get orderSnCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_code')
  String get paymentCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_type')
  String get orderType => throw _privateConstructorUsedError;
  @JsonKey(name: 'pay_type')
  String get payType => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
  Map<String, List<PrintOrderLine>> get orderLinesMap =>
      throw _privateConstructorUsedError;
  List<PrintOrderLine> get orderLines => throw _privateConstructorUsedError;

  /// Serializes this PrintTicketInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrintTicketInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrintTicketInfoCopyWith<PrintTicketInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrintTicketInfoCopyWith<$Res> {
  factory $PrintTicketInfoCopyWith(
    PrintTicketInfo value,
    $Res Function(PrintTicketInfo) then,
  ) = _$PrintTicketInfoCopyWithImpl<$Res, PrintTicketInfo>;
  @useResult
  $Res call({
    String? uuid,
    @JsonKey(fromJson: _toInt) int bizId,
    String orderTime,
    String remark,
    @JsonKey(name: 'from_plate') String fromPlate,
    @JsonKey(name: 'order_sn_code') String orderSnCode,
    @JsonKey(name: 'payment_code') String paymentCode,
    @JsonKey(name: 'order_type') String orderType,
    @JsonKey(name: 'pay_type') String payType,
    @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
    Map<String, List<PrintOrderLine>> orderLinesMap,
    List<PrintOrderLine> orderLines,
  });
}

/// @nodoc
class _$PrintTicketInfoCopyWithImpl<$Res, $Val extends PrintTicketInfo>
    implements $PrintTicketInfoCopyWith<$Res> {
  _$PrintTicketInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrintTicketInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = freezed,
    Object? bizId = null,
    Object? orderTime = null,
    Object? remark = null,
    Object? fromPlate = null,
    Object? orderSnCode = null,
    Object? paymentCode = null,
    Object? orderType = null,
    Object? payType = null,
    Object? orderLinesMap = null,
    Object? orderLines = null,
  }) {
    return _then(
      _value.copyWith(
            uuid: freezed == uuid
                ? _value.uuid
                : uuid // ignore: cast_nullable_to_non_nullable
                      as String?,
            bizId: null == bizId
                ? _value.bizId
                : bizId // ignore: cast_nullable_to_non_nullable
                      as int,
            orderTime: null == orderTime
                ? _value.orderTime
                : orderTime // ignore: cast_nullable_to_non_nullable
                      as String,
            remark: null == remark
                ? _value.remark
                : remark // ignore: cast_nullable_to_non_nullable
                      as String,
            fromPlate: null == fromPlate
                ? _value.fromPlate
                : fromPlate // ignore: cast_nullable_to_non_nullable
                      as String,
            orderSnCode: null == orderSnCode
                ? _value.orderSnCode
                : orderSnCode // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentCode: null == paymentCode
                ? _value.paymentCode
                : paymentCode // ignore: cast_nullable_to_non_nullable
                      as String,
            orderType: null == orderType
                ? _value.orderType
                : orderType // ignore: cast_nullable_to_non_nullable
                      as String,
            payType: null == payType
                ? _value.payType
                : payType // ignore: cast_nullable_to_non_nullable
                      as String,
            orderLinesMap: null == orderLinesMap
                ? _value.orderLinesMap
                : orderLinesMap // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<PrintOrderLine>>,
            orderLines: null == orderLines
                ? _value.orderLines
                : orderLines // ignore: cast_nullable_to_non_nullable
                      as List<PrintOrderLine>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PrintTicketInfoImplCopyWith<$Res>
    implements $PrintTicketInfoCopyWith<$Res> {
  factory _$$PrintTicketInfoImplCopyWith(
    _$PrintTicketInfoImpl value,
    $Res Function(_$PrintTicketInfoImpl) then,
  ) = __$$PrintTicketInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? uuid,
    @JsonKey(fromJson: _toInt) int bizId,
    String orderTime,
    String remark,
    @JsonKey(name: 'from_plate') String fromPlate,
    @JsonKey(name: 'order_sn_code') String orderSnCode,
    @JsonKey(name: 'payment_code') String paymentCode,
    @JsonKey(name: 'order_type') String orderType,
    @JsonKey(name: 'pay_type') String payType,
    @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
    Map<String, List<PrintOrderLine>> orderLinesMap,
    List<PrintOrderLine> orderLines,
  });
}

/// @nodoc
class __$$PrintTicketInfoImplCopyWithImpl<$Res>
    extends _$PrintTicketInfoCopyWithImpl<$Res, _$PrintTicketInfoImpl>
    implements _$$PrintTicketInfoImplCopyWith<$Res> {
  __$$PrintTicketInfoImplCopyWithImpl(
    _$PrintTicketInfoImpl _value,
    $Res Function(_$PrintTicketInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrintTicketInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = freezed,
    Object? bizId = null,
    Object? orderTime = null,
    Object? remark = null,
    Object? fromPlate = null,
    Object? orderSnCode = null,
    Object? paymentCode = null,
    Object? orderType = null,
    Object? payType = null,
    Object? orderLinesMap = null,
    Object? orderLines = null,
  }) {
    return _then(
      _$PrintTicketInfoImpl(
        uuid: freezed == uuid
            ? _value.uuid
            : uuid // ignore: cast_nullable_to_non_nullable
                  as String?,
        bizId: null == bizId
            ? _value.bizId
            : bizId // ignore: cast_nullable_to_non_nullable
                  as int,
        orderTime: null == orderTime
            ? _value.orderTime
            : orderTime // ignore: cast_nullable_to_non_nullable
                  as String,
        remark: null == remark
            ? _value.remark
            : remark // ignore: cast_nullable_to_non_nullable
                  as String,
        fromPlate: null == fromPlate
            ? _value.fromPlate
            : fromPlate // ignore: cast_nullable_to_non_nullable
                  as String,
        orderSnCode: null == orderSnCode
            ? _value.orderSnCode
            : orderSnCode // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentCode: null == paymentCode
            ? _value.paymentCode
            : paymentCode // ignore: cast_nullable_to_non_nullable
                  as String,
        orderType: null == orderType
            ? _value.orderType
            : orderType // ignore: cast_nullable_to_non_nullable
                  as String,
        payType: null == payType
            ? _value.payType
            : payType // ignore: cast_nullable_to_non_nullable
                  as String,
        orderLinesMap: null == orderLinesMap
            ? _value._orderLinesMap
            : orderLinesMap // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<PrintOrderLine>>,
        orderLines: null == orderLines
            ? _value._orderLines
            : orderLines // ignore: cast_nullable_to_non_nullable
                  as List<PrintOrderLine>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrintTicketInfoImpl implements _PrintTicketInfo {
  const _$PrintTicketInfoImpl({
    this.uuid,
    @JsonKey(fromJson: _toInt) this.bizId = 0,
    this.orderTime = '',
    this.remark = '',
    @JsonKey(name: 'from_plate') this.fromPlate = '',
    @JsonKey(name: 'order_sn_code') this.orderSnCode = '',
    @JsonKey(name: 'payment_code') this.paymentCode = '',
    @JsonKey(name: 'order_type') this.orderType = '',
    @JsonKey(name: 'pay_type') this.payType = '',
    @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
    final Map<String, List<PrintOrderLine>> orderLinesMap =
        const <String, List<PrintOrderLine>>{},
    final List<PrintOrderLine> orderLines = const <PrintOrderLine>[],
  }) : _orderLinesMap = orderLinesMap,
       _orderLines = orderLines;

  factory _$PrintTicketInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrintTicketInfoImplFromJson(json);

  @override
  final String? uuid;
  @override
  @JsonKey(fromJson: _toInt)
  final int bizId;
  @override
  @JsonKey()
  final String orderTime;
  @override
  @JsonKey()
  final String remark;
  @override
  @JsonKey(name: 'from_plate')
  final String fromPlate;
  @override
  @JsonKey(name: 'order_sn_code')
  final String orderSnCode;
  @override
  @JsonKey(name: 'payment_code')
  final String paymentCode;
  @override
  @JsonKey(name: 'order_type')
  final String orderType;
  @override
  @JsonKey(name: 'pay_type')
  final String payType;
  final Map<String, List<PrintOrderLine>> _orderLinesMap;
  @override
  @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
  Map<String, List<PrintOrderLine>> get orderLinesMap {
    if (_orderLinesMap is EqualUnmodifiableMapView) return _orderLinesMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_orderLinesMap);
  }

  final List<PrintOrderLine> _orderLines;
  @override
  @JsonKey()
  List<PrintOrderLine> get orderLines {
    if (_orderLines is EqualUnmodifiableListView) return _orderLines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orderLines);
  }

  @override
  String toString() {
    return 'PrintTicketInfo(uuid: $uuid, bizId: $bizId, orderTime: $orderTime, remark: $remark, fromPlate: $fromPlate, orderSnCode: $orderSnCode, paymentCode: $paymentCode, orderType: $orderType, payType: $payType, orderLinesMap: $orderLinesMap, orderLines: $orderLines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrintTicketInfoImpl &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.bizId, bizId) || other.bizId == bizId) &&
            (identical(other.orderTime, orderTime) ||
                other.orderTime == orderTime) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.fromPlate, fromPlate) ||
                other.fromPlate == fromPlate) &&
            (identical(other.orderSnCode, orderSnCode) ||
                other.orderSnCode == orderSnCode) &&
            (identical(other.paymentCode, paymentCode) ||
                other.paymentCode == paymentCode) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.payType, payType) || other.payType == payType) &&
            const DeepCollectionEquality().equals(
              other._orderLinesMap,
              _orderLinesMap,
            ) &&
            const DeepCollectionEquality().equals(
              other._orderLines,
              _orderLines,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uuid,
    bizId,
    orderTime,
    remark,
    fromPlate,
    orderSnCode,
    paymentCode,
    orderType,
    payType,
    const DeepCollectionEquality().hash(_orderLinesMap),
    const DeepCollectionEquality().hash(_orderLines),
  );

  /// Create a copy of PrintTicketInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrintTicketInfoImplCopyWith<_$PrintTicketInfoImpl> get copyWith =>
      __$$PrintTicketInfoImplCopyWithImpl<_$PrintTicketInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PrintTicketInfoImplToJson(this);
  }
}

abstract class _PrintTicketInfo implements PrintTicketInfo {
  const factory _PrintTicketInfo({
    final String? uuid,
    @JsonKey(fromJson: _toInt) final int bizId,
    final String orderTime,
    final String remark,
    @JsonKey(name: 'from_plate') final String fromPlate,
    @JsonKey(name: 'order_sn_code') final String orderSnCode,
    @JsonKey(name: 'payment_code') final String paymentCode,
    @JsonKey(name: 'order_type') final String orderType,
    @JsonKey(name: 'pay_type') final String payType,
    @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
    final Map<String, List<PrintOrderLine>> orderLinesMap,
    final List<PrintOrderLine> orderLines,
  }) = _$PrintTicketInfoImpl;

  factory _PrintTicketInfo.fromJson(Map<String, dynamic> json) =
      _$PrintTicketInfoImpl.fromJson;

  @override
  String? get uuid;
  @override
  @JsonKey(fromJson: _toInt)
  int get bizId;
  @override
  String get orderTime;
  @override
  String get remark;
  @override
  @JsonKey(name: 'from_plate')
  String get fromPlate;
  @override
  @JsonKey(name: 'order_sn_code')
  String get orderSnCode;
  @override
  @JsonKey(name: 'payment_code')
  String get paymentCode;
  @override
  @JsonKey(name: 'order_type')
  String get orderType;
  @override
  @JsonKey(name: 'pay_type')
  String get payType;
  @override
  @JsonKey(fromJson: _linesMapFromJson, toJson: _linesMapToJson)
  Map<String, List<PrintOrderLine>> get orderLinesMap;
  @override
  List<PrintOrderLine> get orderLines;

  /// Create a copy of PrintTicketInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrintTicketInfoImplCopyWith<_$PrintTicketInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrintOrderLine _$PrintOrderLineFromJson(Map<String, dynamic> json) {
  return _PrintOrderLine.fromJson(json);
}

/// @nodoc
mixin _$PrintOrderLine {
  String get categoryName => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get price => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get qty => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get bizId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
  Map<String, List<PrintOrderOption>> get options =>
      throw _privateConstructorUsedError;
  dynamic get extend2qr => throw _privateConstructorUsedError;

  /// Serializes this PrintOrderLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrintOrderLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrintOrderLineCopyWith<PrintOrderLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrintOrderLineCopyWith<$Res> {
  factory $PrintOrderLineCopyWith(
    PrintOrderLine value,
    $Res Function(PrintOrderLine) then,
  ) = _$PrintOrderLineCopyWithImpl<$Res, PrintOrderLine>;
  @useResult
  $Res call({
    String categoryName,
    String name,
    @JsonKey(fromJson: _toInt) int price,
    @JsonKey(fromJson: _toInt) int qty,
    @JsonKey(fromJson: _toInt) int bizId,
    @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
    Map<String, List<PrintOrderOption>> options,
    dynamic extend2qr,
  });
}

/// @nodoc
class _$PrintOrderLineCopyWithImpl<$Res, $Val extends PrintOrderLine>
    implements $PrintOrderLineCopyWith<$Res> {
  _$PrintOrderLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrintOrderLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryName = null,
    Object? name = null,
    Object? price = null,
    Object? qty = null,
    Object? bizId = null,
    Object? options = null,
    Object? extend2qr = freezed,
  }) {
    return _then(
      _value.copyWith(
            categoryName: null == categoryName
                ? _value.categoryName
                : categoryName // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            bizId: null == bizId
                ? _value.bizId
                : bizId // ignore: cast_nullable_to_non_nullable
                      as int,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<PrintOrderOption>>,
            extend2qr: freezed == extend2qr
                ? _value.extend2qr
                : extend2qr // ignore: cast_nullable_to_non_nullable
                      as dynamic,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PrintOrderLineImplCopyWith<$Res>
    implements $PrintOrderLineCopyWith<$Res> {
  factory _$$PrintOrderLineImplCopyWith(
    _$PrintOrderLineImpl value,
    $Res Function(_$PrintOrderLineImpl) then,
  ) = __$$PrintOrderLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String categoryName,
    String name,
    @JsonKey(fromJson: _toInt) int price,
    @JsonKey(fromJson: _toInt) int qty,
    @JsonKey(fromJson: _toInt) int bizId,
    @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
    Map<String, List<PrintOrderOption>> options,
    dynamic extend2qr,
  });
}

/// @nodoc
class __$$PrintOrderLineImplCopyWithImpl<$Res>
    extends _$PrintOrderLineCopyWithImpl<$Res, _$PrintOrderLineImpl>
    implements _$$PrintOrderLineImplCopyWith<$Res> {
  __$$PrintOrderLineImplCopyWithImpl(
    _$PrintOrderLineImpl _value,
    $Res Function(_$PrintOrderLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrintOrderLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryName = null,
    Object? name = null,
    Object? price = null,
    Object? qty = null,
    Object? bizId = null,
    Object? options = null,
    Object? extend2qr = freezed,
  }) {
    return _then(
      _$PrintOrderLineImpl(
        categoryName: null == categoryName
            ? _value.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        bizId: null == bizId
            ? _value.bizId
            : bizId // ignore: cast_nullable_to_non_nullable
                  as int,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<PrintOrderOption>>,
        extend2qr: freezed == extend2qr
            ? _value.extend2qr
            : extend2qr // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrintOrderLineImpl implements _PrintOrderLine {
  const _$PrintOrderLineImpl({
    this.categoryName = '',
    this.name = '',
    @JsonKey(fromJson: _toInt) this.price = 0,
    @JsonKey(fromJson: _toInt) this.qty = 0,
    @JsonKey(fromJson: _toInt) this.bizId = 0,
    @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
    final Map<String, List<PrintOrderOption>> options =
        const <String, List<PrintOrderOption>>{},
    this.extend2qr,
  }) : _options = options;

  factory _$PrintOrderLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrintOrderLineImplFromJson(json);

  @override
  @JsonKey()
  final String categoryName;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey(fromJson: _toInt)
  final int price;
  @override
  @JsonKey(fromJson: _toInt)
  final int qty;
  @override
  @JsonKey(fromJson: _toInt)
  final int bizId;
  final Map<String, List<PrintOrderOption>> _options;
  @override
  @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
  Map<String, List<PrintOrderOption>> get options {
    if (_options is EqualUnmodifiableMapView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_options);
  }

  @override
  final dynamic extend2qr;

  @override
  String toString() {
    return 'PrintOrderLine(categoryName: $categoryName, name: $name, price: $price, qty: $qty, bizId: $bizId, options: $options, extend2qr: $extend2qr)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrintOrderLineImpl &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.bizId, bizId) || other.bizId == bizId) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality().equals(other.extend2qr, extend2qr));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryName,
    name,
    price,
    qty,
    bizId,
    const DeepCollectionEquality().hash(_options),
    const DeepCollectionEquality().hash(extend2qr),
  );

  /// Create a copy of PrintOrderLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrintOrderLineImplCopyWith<_$PrintOrderLineImpl> get copyWith =>
      __$$PrintOrderLineImplCopyWithImpl<_$PrintOrderLineImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PrintOrderLineImplToJson(this);
  }
}

abstract class _PrintOrderLine implements PrintOrderLine {
  const factory _PrintOrderLine({
    final String categoryName,
    final String name,
    @JsonKey(fromJson: _toInt) final int price,
    @JsonKey(fromJson: _toInt) final int qty,
    @JsonKey(fromJson: _toInt) final int bizId,
    @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
    final Map<String, List<PrintOrderOption>> options,
    final dynamic extend2qr,
  }) = _$PrintOrderLineImpl;

  factory _PrintOrderLine.fromJson(Map<String, dynamic> json) =
      _$PrintOrderLineImpl.fromJson;

  @override
  String get categoryName;
  @override
  String get name;
  @override
  @JsonKey(fromJson: _toInt)
  int get price;
  @override
  @JsonKey(fromJson: _toInt)
  int get qty;
  @override
  @JsonKey(fromJson: _toInt)
  int get bizId;
  @override
  @JsonKey(fromJson: _optionsFromJson, toJson: _optionsToJson)
  Map<String, List<PrintOrderOption>> get options;
  @override
  dynamic get extend2qr;

  /// Create a copy of PrintOrderLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrintOrderLineImplCopyWith<_$PrintOrderLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrintOrderOption _$PrintOrderOptionFromJson(Map<String, dynamic> json) {
  return _PrintOrderOption.fromJson(json);
}

/// @nodoc
mixin _$PrintOrderOption {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toIntOrNull)
  int? get price => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _toInt)
  int get qty => throw _privateConstructorUsedError;

  /// Serializes this PrintOrderOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrintOrderOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrintOrderOptionCopyWith<PrintOrderOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrintOrderOptionCopyWith<$Res> {
  factory $PrintOrderOptionCopyWith(
    PrintOrderOption value,
    $Res Function(PrintOrderOption) then,
  ) = _$PrintOrderOptionCopyWithImpl<$Res, PrintOrderOption>;
  @useResult
  $Res call({
    String name,
    @JsonKey(fromJson: _toIntOrNull) int? price,
    @JsonKey(fromJson: _toInt) int qty,
  });
}

/// @nodoc
class _$PrintOrderOptionCopyWithImpl<$Res, $Val extends PrintOrderOption>
    implements $PrintOrderOptionCopyWith<$Res> {
  _$PrintOrderOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrintOrderOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? price = freezed,
    Object? qty = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            price: freezed == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as int?,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PrintOrderOptionImplCopyWith<$Res>
    implements $PrintOrderOptionCopyWith<$Res> {
  factory _$$PrintOrderOptionImplCopyWith(
    _$PrintOrderOptionImpl value,
    $Res Function(_$PrintOrderOptionImpl) then,
  ) = __$$PrintOrderOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    @JsonKey(fromJson: _toIntOrNull) int? price,
    @JsonKey(fromJson: _toInt) int qty,
  });
}

/// @nodoc
class __$$PrintOrderOptionImplCopyWithImpl<$Res>
    extends _$PrintOrderOptionCopyWithImpl<$Res, _$PrintOrderOptionImpl>
    implements _$$PrintOrderOptionImplCopyWith<$Res> {
  __$$PrintOrderOptionImplCopyWithImpl(
    _$PrintOrderOptionImpl _value,
    $Res Function(_$PrintOrderOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrintOrderOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? price = freezed,
    Object? qty = null,
  }) {
    return _then(
      _$PrintOrderOptionImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        price: freezed == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as int?,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrintOrderOptionImpl implements _PrintOrderOption {
  const _$PrintOrderOptionImpl({
    this.name = '',
    @JsonKey(fromJson: _toIntOrNull) this.price,
    @JsonKey(fromJson: _toInt) this.qty = 0,
  });

  factory _$PrintOrderOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrintOrderOptionImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey(fromJson: _toIntOrNull)
  final int? price;
  @override
  @JsonKey(fromJson: _toInt)
  final int qty;

  @override
  String toString() {
    return 'PrintOrderOption(name: $name, price: $price, qty: $qty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrintOrderOptionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.qty, qty) || other.qty == qty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, price, qty);

  /// Create a copy of PrintOrderOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrintOrderOptionImplCopyWith<_$PrintOrderOptionImpl> get copyWith =>
      __$$PrintOrderOptionImplCopyWithImpl<_$PrintOrderOptionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PrintOrderOptionImplToJson(this);
  }
}

abstract class _PrintOrderOption implements PrintOrderOption {
  const factory _PrintOrderOption({
    final String name,
    @JsonKey(fromJson: _toIntOrNull) final int? price,
    @JsonKey(fromJson: _toInt) final int qty,
  }) = _$PrintOrderOptionImpl;

  factory _PrintOrderOption.fromJson(Map<String, dynamic> json) =
      _$PrintOrderOptionImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(fromJson: _toIntOrNull)
  int? get price;
  @override
  @JsonKey(fromJson: _toInt)
  int get qty;

  /// Create a copy of PrintOrderOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrintOrderOptionImplCopyWith<_$PrintOrderOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
