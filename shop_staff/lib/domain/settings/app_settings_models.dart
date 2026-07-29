import 'package:flutter/foundation.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';

enum PrinterBackend { widgetRaster, starXpandNative }

enum PrinterConnectionType {
  network,
  bluetoothClassic,
  bluetoothLe,
  usb,
  usbC,
  lightningUsb,
  unknown,
}

extension PrinterBackendX on PrinterBackend {
  String get wireValue {
    switch (this) {
      case PrinterBackend.widgetRaster:
        return 'widget_raster';
      case PrinterBackend.starXpandNative:
        return 'starxpand_native';
    }
  }

  static PrinterBackend fromWireValue(String? raw) {
    switch (raw) {
      case 'starxpand_native':
        return PrinterBackend.starXpandNative;
      case 'widget_raster':
      default:
        return PrinterBackend.widgetRaster;
    }
  }
}

extension PrinterConnectionTypeX on PrinterConnectionType {
  String get wireValue {
    switch (this) {
      case PrinterConnectionType.network:
        return 'network';
      case PrinterConnectionType.bluetoothClassic:
        return 'bluetooth_classic';
      case PrinterConnectionType.bluetoothLe:
        return 'bluetooth_le';
      case PrinterConnectionType.usb:
        return 'usb';
      case PrinterConnectionType.usbC:
        return 'usb_c';
      case PrinterConnectionType.lightningUsb:
        return 'lightning_usb';
      case PrinterConnectionType.unknown:
        return 'unknown';
    }
  }

  static PrinterConnectionType fromWireValue(String? raw) {
    switch (raw) {
      case 'bluetooth_classic':
        return PrinterConnectionType.bluetoothClassic;
      case 'bluetooth_le':
        return PrinterConnectionType.bluetoothLe;
      case 'usb':
        return PrinterConnectionType.usb;
      case 'usb_c':
        return PrinterConnectionType.usbC;
      case 'lightning_usb':
        return PrinterConnectionType.lightningUsb;
      case 'network':
        return PrinterConnectionType.network;
      default:
        return PrinterConnectionType.unknown;
    }
  }
}

enum CashMachineBrand { glory, star, conlux }

extension CashMachineBrandX on CashMachineBrand {
  String get wireValue {
    switch (this) {
      case CashMachineBrand.glory:
        return 'glory';
      case CashMachineBrand.star:
        return 'star';
      case CashMachineBrand.conlux:
        return 'conlux';
    }
  }

  static CashMachineBrand? fromWireValue(String? raw) {
    switch (raw) {
      case 'glory':
        return CashMachineBrand.glory;
      case 'star':
        return CashMachineBrand.star;
      case 'conlux':
        return CashMachineBrand.conlux;
      default:
        return null;
    }
  }
}

const Object _copyWithUnset = Object();

@immutable
class OrderModeSettings {
  const OrderModeSettings({
    this.dineIn = true,
    this.takeout = true,
    this.settlement = true,
  });

  final bool dineIn;
  final bool takeout;
  final bool settlement;

  OrderModeSettings copyWith({bool? dineIn, bool? takeout, bool? settlement}) {
    return OrderModeSettings(
      dineIn: dineIn ?? this.dineIn,
      takeout: takeout ?? this.takeout,
      settlement: settlement ?? this.settlement,
    );
  }

  Map<String, dynamic> toJson() {
    return {'dineIn': dineIn, 'takeout': takeout, 'settlement': settlement};
  }

  factory OrderModeSettings.fromJson(Map<String, dynamic> json) {
    return OrderModeSettings(
      dineIn: _readBool(json['dineIn']) ?? true,
      takeout: _readBool(json['takeout']) ?? true,
      settlement: _readBool(json['settlement']) ?? true,
    );
  }
}

@immutable
class PaymentModeSettings {
  const PaymentModeSettings({this.cash, this.card, this.qr});

  final PaymentFlowMode? cash;
  final PaymentFlowMode? card;
  final PaymentFlowMode? qr;

  PaymentModeSettings copyWith({
    Object? cash = _copyWithUnset,
    Object? card = _copyWithUnset,
    Object? qr = _copyWithUnset,
  }) {
    return PaymentModeSettings(
      cash: identical(cash, _copyWithUnset)
          ? this.cash
          : cash as PaymentFlowMode?,
      card: identical(card, _copyWithUnset)
          ? this.card
          : card as PaymentFlowMode?,
      qr: identical(qr, _copyWithUnset) ? this.qr : qr as PaymentFlowMode?,
    );
  }

  PaymentFlowMode resolveCash(CashMachineSettings cashMachine) {
    return cash ?? _defaultCashMode(cashMachine);
  }

  PaymentFlowMode resolveCard() => card ?? PaymentFlowMode.real;

  PaymentFlowMode resolveQr() => qr ?? PaymentFlowMode.real;

  PaymentFlowMode resolveForGroup(
    String group, {
    required CashMachineSettings cashMachine,
  }) {
    switch (group) {
      case 'cash':
        return resolveCash(cashMachine);
      case 'card':
        return resolveCard();
      case 'qr':
      default:
        return resolveQr();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'cash': cash?.wireValue,
      'card': card?.wireValue,
      'qr': qr?.wireValue,
    }..removeWhere((key, value) => value == null);
  }

  factory PaymentModeSettings.fromJson(Map<String, dynamic> json) {
    return PaymentModeSettings(
      cash: _readMode(json['cash']),
      card: _readMode(json['card']),
      qr: _readMode(json['qr']),
    );
  }

  static PaymentFlowMode _defaultCashMode(CashMachineSettings cashMachine) {
    if (cashMachine.brand == CashMachineBrand.star) {
      return PaymentFlowMode.bookkeeping;
    }
    return PaymentFlowMode.real;
  }
}

@immutable
class CashMachineSettings {
  const CashMachineSettings({
    this.enabled = false,
    this.brand,
    this.connectionType = PrinterConnectionType.unknown,
    this.deviceIdentifier,
    this.host,
    this.modelName,
  });

  final bool enabled;
  final CashMachineBrand? brand;
  final PrinterConnectionType connectionType;
  final String? deviceIdentifier;
  final String? host;
  final String? modelName;

  bool get isConfigured {
    switch (brand) {
      case CashMachineBrand.star:
        return connectionType != PrinterConnectionType.unknown &&
            (_trimOrNull(deviceIdentifier) != null ||
                _trimOrNull(host) != null);
      case CashMachineBrand.glory:
      case CashMachineBrand.conlux:
        return true;
      case null:
        return false;
    }
  }

  CashMachineSettings copyWith({
    bool? enabled,
    Object? brand = _copyWithUnset,
    PrinterConnectionType? connectionType,
    Object? deviceIdentifier = _copyWithUnset,
    Object? host = _copyWithUnset,
    Object? modelName = _copyWithUnset,
  }) {
    return CashMachineSettings(
      enabled: enabled ?? this.enabled,
      brand: identical(brand, _copyWithUnset)
          ? this.brand
          : brand as CashMachineBrand?,
      connectionType: connectionType ?? this.connectionType,
      deviceIdentifier: identical(deviceIdentifier, _copyWithUnset)
          ? this.deviceIdentifier
          : deviceIdentifier as String?,
      host: identical(host, _copyWithUnset) ? this.host : host as String?,
      modelName: identical(modelName, _copyWithUnset)
          ? this.modelName
          : modelName as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'brand': brand?.wireValue,
      'connectionType': connectionType.wireValue,
      'deviceIdentifier': deviceIdentifier,
      'host': host,
      'modelName': modelName,
    }..removeWhere((key, value) => value == null);
  }

  factory CashMachineSettings.fromJson(Map<String, dynamic> json) {
    return CashMachineSettings(
      enabled: _readBool(json['enabled']) ?? false,
      brand: CashMachineBrandX.fromWireValue(json['brand'] as String?),
      connectionType: PrinterConnectionTypeX.fromWireValue(
        json['connectionType'] as String?,
      ),
      deviceIdentifier: json['deviceIdentifier'] as String?,
      host: json['host'] as String?,
      modelName: json['modelName'] as String?,
    );
  }

  factory CashMachineSettings.fromLegacy({required bool enabled}) {
    return CashMachineSettings(enabled: enabled);
  }
}

@immutable
class BasicSettings {
  const BasicSettings({
    this.shopName,
    this.shopCode,
    this.machineCode,
    this.contactNumber,
    this.address,
    this.displayLocaleCode,
    this.cashMachineEnabled,
    this.cashMachine = const CashMachineSettings(),
    this.paymentModes = const PaymentModeSettings(),
    this.orderModes = const OrderModeSettings(),
    this.peerLinkEnabled = true,
  });

  final String? shopName;
  final String? shopCode;
  final String? machineCode;
  final String? contactNumber;
  final String? address;
  final String? displayLocaleCode;
  final bool? cashMachineEnabled;
  final CashMachineSettings cashMachine;
  final PaymentModeSettings paymentModes;
  final OrderModeSettings orderModes;
  final bool peerLinkEnabled;

  BasicSettings copyWith({
    String? shopName,
    String? shopCode,
    String? machineCode,
    String? contactNumber,
    String? address,
    Object? displayLocaleCode = _copyWithUnset,
    bool? cashMachineEnabled,
    CashMachineSettings? cashMachine,
    PaymentModeSettings? paymentModes,
    OrderModeSettings? orderModes,
    bool? peerLinkEnabled,
  }) {
    final baseCashMachine = cashMachine ?? this.cashMachine;
    final resolvedCashMachine = cashMachineEnabled == null
        ? baseCashMachine
        : baseCashMachine.copyWith(enabled: cashMachineEnabled);
    final resolvedCashMachineEnabled =
        cashMachineEnabled ?? resolvedCashMachine.enabled;

    return BasicSettings(
      shopName: shopName ?? this.shopName,
      shopCode: shopCode ?? this.shopCode,
      machineCode: machineCode ?? this.machineCode,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      displayLocaleCode: identical(displayLocaleCode, _copyWithUnset)
          ? this.displayLocaleCode
          : displayLocaleCode as String?,
      cashMachineEnabled: resolvedCashMachineEnabled,
      cashMachine: resolvedCashMachine,
      paymentModes: paymentModes ?? this.paymentModes,
      orderModes: orderModes ?? this.orderModes,
      peerLinkEnabled: peerLinkEnabled ?? this.peerLinkEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName,
      'shopCode': shopCode,
      'machineCode': machineCode,
      'contactNumber': contactNumber,
      'address': address,
      'displayLocaleCode': displayLocaleCode,
      'cashMachineEnabled': cashMachineEnabled,
      'cashMachine': cashMachine.toJson(),
      'paymentModes': paymentModes.toJson(),
      'orderModes': orderModes.toJson(),
      'peerLinkEnabled': peerLinkEnabled,
    }..removeWhere((key, value) => value == null);
  }

  factory BasicSettings.fromJson(Map<String, dynamic> json) {
    final legacyEnabled = _readBool(json['cashMachineEnabled']) ?? false;
    final rawCashMachine = json['cashMachine'];
    var cashMachine = rawCashMachine is Map
        ? CashMachineSettings.fromJson(
            Map<String, dynamic>.from(rawCashMachine),
          )
        : CashMachineSettings.fromLegacy(enabled: legacyEnabled);

    if (_readBool(json['cashMachineEnabled']) != null) {
      cashMachine = cashMachine.copyWith(enabled: legacyEnabled);
    }

    return BasicSettings(
      shopName: json['shopName'] as String?,
      shopCode: json['shopCode'] as String?,
      machineCode: json['machineCode'] as String?,
      contactNumber: json['contactNumber'] as String?,
      address: json['address'] as String?,
      displayLocaleCode: _trimOrNull(json['displayLocaleCode'] as String?),
      cashMachineEnabled: cashMachine.enabled,
      cashMachine: cashMachine,
      paymentModes: json['paymentModes'] is Map
          ? PaymentModeSettings.fromJson(
              Map<String, dynamic>.from(json['paymentModes'] as Map),
            )
          : const PaymentModeSettings(),
      orderModes: json['orderModes'] is Map
          ? OrderModeSettings.fromJson(
              Map<String, dynamic>.from(json['orderModes'] as Map),
            )
          : const OrderModeSettings(),
      peerLinkEnabled: _readBool(json['peerLinkEnabled']) ?? true,
    );
  }
}

@immutable
class PosTerminalSettings {
  const PosTerminalSettings({this.posIp, this.posPort});

  final String? posIp;
  final int? posPort;

  PosTerminalSettings copyWith({String? posIp, int? posPort}) {
    return PosTerminalSettings(
      posIp: posIp ?? this.posIp,
      posPort: posPort ?? this.posPort,
    );
  }

  Map<String, dynamic> toJson() {
    return {'posIp': posIp, 'posPort': posPort}
      ..removeWhere((key, value) => value == null);
  }

  factory PosTerminalSettings.fromJson(Map<String, dynamic> json) {
    return PosTerminalSettings(
      posIp: json['posIp'] as String?,
      posPort: _readInt(json['posPort']),
    );
  }
}

@immutable
class PrinterSettings {
  static const int localType = 0;
  static const int kitchenType = 10;
  static const int centerType = 11;
  static const int counterType = 12;

  const PrinterSettings({
    required this.name,
    required this.type,
    this.backend = PrinterBackend.widgetRaster,
    this.connectionType = PrinterConnectionType.network,
    this.receipt = true,
    this.labelSize = '',
    this.receiptPaperWidthMm = 80,
    this.continuous = false,
    this.isOn = false,
    this.isDefault = true,
    this.printIp,
    this.printPort,
    this.deviceIdentifier,
    this.modelName,
    this.option = false,
    this.direction = true,
  });

  final String name;
  final int type;
  final PrinterBackend backend;
  final PrinterConnectionType connectionType;
  final bool receipt;
  final String labelSize;
  final int receiptPaperWidthMm;
  final bool continuous;
  final bool isOn;
  final bool isDefault;
  final String? printIp;
  final String? printPort;
  final String? deviceIdentifier;
  final String? modelName;
  final bool option;
  final bool direction;

  bool get usesWidgetRaster => backend == PrinterBackend.widgetRaster;

  bool get usesNativeSdk => backend == PrinterBackend.starXpandNative;

  bool get requiresNetworkEndpoint =>
      usesWidgetRaster || connectionType == PrinterConnectionType.network;

  bool get requiresDeviceIdentifier =>
      usesNativeSdk && connectionType != PrinterConnectionType.network;

  PrinterSettings copyWith({
    String? name,
    int? type,
    PrinterBackend? backend,
    PrinterConnectionType? connectionType,
    bool? receipt,
    String? labelSize,
    int? receiptPaperWidthMm,
    bool? continuous,
    bool? isOn,
    bool? isDefault,
    String? printIp,
    String? printPort,
    String? deviceIdentifier,
    String? modelName,
    bool? option,
    bool? direction,
  }) {
    return PrinterSettings(
      name: name ?? this.name,
      type: type ?? this.type,
      backend: backend ?? this.backend,
      connectionType: connectionType ?? this.connectionType,
      receipt: receipt ?? this.receipt,
      labelSize: labelSize ?? this.labelSize,
      receiptPaperWidthMm: receiptPaperWidthMm ?? this.receiptPaperWidthMm,
      continuous: continuous ?? this.continuous,
      isOn: isOn ?? this.isOn,
      isDefault: isDefault ?? this.isDefault,
      printIp: printIp ?? this.printIp,
      printPort: printPort ?? this.printPort,
      deviceIdentifier: deviceIdentifier ?? this.deviceIdentifier,
      modelName: modelName ?? this.modelName,
      option: option ?? this.option,
      direction: direction ?? this.direction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'backend': backend.wireValue,
      'connectionType': connectionType.wireValue,
      'receipt': receipt,
      'labelSize': labelSize,
      'receiptPaperWidthMm': receiptPaperWidthMm,
      'continuous': continuous,
      'isOn': isOn,
      'isDefault': isDefault,
      'printIp': printIp,
      'printPort': printPort,
      'deviceIdentifier': deviceIdentifier,
      'modelName': modelName,
      'option': option,
      'direction': direction,
    }..removeWhere((key, value) => value == null);
  }

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    final backend = PrinterBackendX.fromWireValue(json['backend'] as String?);
    final rawConnectionType = PrinterConnectionTypeX.fromWireValue(
      json['connectionType'] as String?,
    );
    final resolvedConnectionType =
        rawConnectionType == PrinterConnectionType.unknown &&
            backend == PrinterBackend.widgetRaster
        ? PrinterConnectionType.network
        : rawConnectionType;

    return PrinterSettings(
      name: json['name'] as String? ?? '',
      type: _readInt(json['type']) ?? 0,
      backend: backend,
      connectionType: resolvedConnectionType,
      receipt: _readBool(json['receipt']) ?? true,
      labelSize: json['labelSize'] as String? ?? '',
      receiptPaperWidthMm: _readReceiptPaperWidthMm(
        json['receiptPaperWidthMm'],
        json['labelSize'] as String?,
      ),
      continuous: _readBool(json['continuous']) ?? false,
      isOn: _readBool(json['isOn']) ?? false,
      isDefault: _readBool(json['isDefault']) ?? false,
      printIp: json['printIp'] as String?,
      printPort: json['printPort']?.toString(),
      deviceIdentifier: json['deviceIdentifier'] as String?,
      modelName: json['modelName'] as String?,
      option: _readBool(json['option']) ?? false,
      direction: _readBool(json['direction']) ?? true,
    );
  }

  static List<PrinterSettings> mergeWithDefaults(
    List<PrinterSettings> printers,
  ) {
    if (printers.isEmpty) {
      return defaultProfiles();
    }

    final merged = <PrinterSettings>[];
    final byKey = <String, PrinterSettings>{
      for (final printer in printers)
        _profileKey(printer.type, printer.receipt): printer,
    };

    for (final profile in defaultProfiles()) {
      merged.add(
        byKey.remove(_profileKey(profile.type, profile.receipt)) ?? profile,
      );
    }

    merged.addAll(byKey.values);
    return merged;
  }

  static List<PrinterSettings> defaultProfiles() {
    return const [
      PrinterSettings(
        name: '',
        type: localType,
        backend: PrinterBackend.starXpandNative,
        connectionType: PrinterConnectionType.unknown,
        receipt: true,
        labelSize: '',
        receiptPaperWidthMm: 80,
        continuous: false,
        isOn: false,
        isDefault: true,
        option: false,
        direction: true,
      ),
      PrinterSettings(
        name: 'キッチン',
        type: kitchenType,
        backend: PrinterBackend.widgetRaster,
        connectionType: PrinterConnectionType.network,
        receipt: true,
        labelSize: '',
        receiptPaperWidthMm: 80,
        continuous: false,
        isOn: false,
        isDefault: true,
        printIp: '',
        printPort: '9100',
        option: true,
        direction: false,
      ),
      PrinterSettings(
        name: 'キッチン (ラベル)',
        type: kitchenType,
        backend: PrinterBackend.widgetRaster,
        connectionType: PrinterConnectionType.network,
        receipt: false,
        labelSize: '',
        receiptPaperWidthMm: 80,
        continuous: false,
        isOn: false,
        isDefault: false,
        printIp: '',
        printPort: '9100',
        option: true,
        direction: false,
      ),
      PrinterSettings(
        name: 'センター',
        type: centerType,
        backend: PrinterBackend.widgetRaster,
        connectionType: PrinterConnectionType.network,
        receipt: true,
        labelSize: '',
        receiptPaperWidthMm: 80,
        continuous: false,
        isOn: false,
        isDefault: false,
        printIp: '',
        printPort: '9100',
        option: true,
        direction: false,
      ),
      PrinterSettings(
        name: 'カウンター',
        type: counterType,
        backend: PrinterBackend.widgetRaster,
        connectionType: PrinterConnectionType.network,
        receipt: true,
        labelSize: '',
        receiptPaperWidthMm: 80,
        continuous: false,
        isOn: false,
        isDefault: false,
        printIp: '',
        printPort: '9100',
        option: true,
        direction: false,
      ),
    ];
  }

  static String _profileKey(int type, bool receipt) => '$type|$receipt';
}

int _readReceiptPaperWidthMm(Object? value, String? legacyLabelSize) {
  final parsed = _readInt(value);
  if (parsed == 58 || parsed == 80) {
    return parsed!;
  }

  final legacy = (legacyLabelSize ?? '').trim().toLowerCase();
  if (legacy.contains('58')) {
    return 58;
  }
  if (legacy.contains('80')) {
    return 80;
  }
  return 80;
}

@immutable
class AppSettingsSnapshot {
  const AppSettingsSnapshot({
    this.basic = const BasicSettings(),
    this.posTerminal = const PosTerminalSettings(),
    this.printers = const <PrinterSettings>[],
  });

  final BasicSettings basic;
  final PosTerminalSettings posTerminal;
  final List<PrinterSettings> printers;
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

bool? _readBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'y') return true;
    if (lower == 'false' || lower == '0' || lower == 'n') return false;
  }
  return null;
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

PaymentFlowMode? _readMode(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return PaymentFlowModeX.fromWireValue(trimmed);
  }
  return null;
}
