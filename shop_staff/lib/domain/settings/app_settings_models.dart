import 'package:flutter/foundation.dart';

@immutable
class BasicSettings {
  const BasicSettings({
    this.shopName,
    this.shopCode,
    this.machineCode,
    this.contactNumber,
    this.address,
  });

  final String? shopName;
  final String? shopCode;
  final String? machineCode;
  final String? contactNumber;
  final String? address;

  BasicSettings copyWith({
    String? shopName,
    String? shopCode,
    String? machineCode,
    String? contactNumber,
    String? address,
  }) {
    return BasicSettings(
      shopName: shopName ?? this.shopName,
      shopCode: shopCode ?? this.shopCode,
      machineCode: machineCode ?? this.machineCode,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName,
      'shopCode': shopCode,
      'machineCode': machineCode,
      'contactNumber': contactNumber,
      'address': address,
    }..removeWhere((key, value) => value == null);
  }

  factory BasicSettings.fromJson(Map<String, dynamic> json) {
    return BasicSettings(
      shopName: json['shopName'] as String?,
      shopCode: json['shopCode'] as String?,
      machineCode: json['machineCode'] as String?,
      contactNumber: json['contactNumber'] as String?,
      address: json['address'] as String?,
    );
  }
}

@immutable
class PosTerminalSettings {
  const PosTerminalSettings({
    this.posIp,
    this.posPort,
  });

  final String? posIp;
  final int? posPort;

  PosTerminalSettings copyWith({
    String? posIp,
    int? posPort,
  }) {
    return PosTerminalSettings(
      posIp: posIp ?? this.posIp,
      posPort: posPort ?? this.posPort,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posIp': posIp,
      'posPort': posPort,
    }..removeWhere((key, value) => value == null);
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
  const PrinterSettings({
    required this.name,
    required this.type,
    this.receipt = 0,
    this.labelWidth = 0,
    this.continuous = 0,
    this.isOn = false,
    this.isDefault = false,
    this.printIp,
    this.printPort,
    this.option = false,
    this.direction = 0,
  });

  final String name;
  final int type;
  final int receipt;
  final int labelWidth;
  final int continuous;
  final bool isOn;
  final bool isDefault;
  final String? printIp;
  final String? printPort;
  final bool option;
  final int direction;

  PrinterSettings copyWith({
    String? name,
    int? type,
    int? receipt,
    int? labelWidth,
    int? continuous,
    bool? isOn,
    bool? isDefault,
    String? printIp,
    String? printPort,
    bool? option,
    int? direction,
  }) {
    return PrinterSettings(
      name: name ?? this.name,
      type: type ?? this.type,
      receipt: receipt ?? this.receipt,
      labelWidth: labelWidth ?? this.labelWidth,
      continuous: continuous ?? this.continuous,
      isOn: isOn ?? this.isOn,
      isDefault: isDefault ?? this.isDefault,
      printIp: printIp ?? this.printIp,
      printPort: printPort ?? this.printPort,
      option: option ?? this.option,
      direction: direction ?? this.direction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'receipt': receipt,
      'labelWidth': labelWidth,
      'continuous': continuous,
      'isOn': isOn,
      'isDefault': isDefault,
      'printIp': printIp,
      'printPort': printPort,
      'option': option,
      'direction': direction,
    }..removeWhere((key, value) => value == null);
  }

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      name: json['name'] as String? ?? '',
      type: _readInt(json['type']) ?? 0,
      receipt: _readInt(json['receipt']) ?? 0,
      labelWidth: _readInt(json['labelWidth']) ?? 0,
      continuous: _readInt(json['continuous']) ?? 0,
      isOn: _readBool(json['isOn']) ?? false,
      isDefault: _readBool(json['isDefault']) ?? false,
      printIp: json['printIp'] as String?,
      printPort: json['printPort']?.toString(),
      option: _readBool(json['option']) ?? false,
      direction: _readInt(json['direction']) ?? 0,
    );
  }

  static List<PrinterSettings> defaultProfiles() {
    return const [
      PrinterSettings(
        name: 'キッチン',
        type: 10,
        receipt: 0,
        labelWidth: 0,
        continuous: 0,
        isOn: false,
        isDefault: true,
        printIp: '',
        printPort: '9100',
        option: true,
        direction: 0,
      ),
      PrinterSettings(
        name: 'キッチン (ラベル)',
        type: 10,
        receipt: 1,
        labelWidth: 0,
        continuous: 0,
        isOn: false,
        isDefault: false,
        printIp: '',
        printPort: '9100',
        option: true,
        direction: 0,
      ),
      PrinterSettings(
        name: 'センター',
        type: 11,
        receipt: 0,
        labelWidth: 0,
        continuous: 0,
        isOn: false,
        isDefault: false,
        printIp: '',
        printPort: '9100',
        option: false,
        direction: 0,
      ),
      PrinterSettings(
        name: 'カウンター',
        type: 12,
        receipt: 0,
        labelWidth: 0,
        continuous: 0,
        isOn: false,
        isDefault: false,
        printIp: '',
        printPort: '9100',
        option: false,
        direction: 0,
      ),
    ];
  }
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
