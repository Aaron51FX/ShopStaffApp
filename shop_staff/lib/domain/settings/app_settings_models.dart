import 'package:flutter/foundation.dart';

@immutable
class BasicSettings {
  const BasicSettings({
    this.shopName,
    this.shopCode,
    this.machineCode,
    this.contactNumber,
    this.address,
    this.cashMachineEnabled,
  });

  final String? shopName;
  final String? shopCode;
  final String? machineCode;
  final String? contactNumber;
  final String? address;
  final bool? cashMachineEnabled;

  BasicSettings copyWith({
    String? shopName,
    String? shopCode,
    String? machineCode,
    String? contactNumber,
    String? address,
    bool? cashMachineEnabled,
  }) {
    return BasicSettings(
      shopName: shopName ?? this.shopName,
      shopCode: shopCode ?? this.shopCode,
      machineCode: machineCode ?? this.machineCode,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      cashMachineEnabled: cashMachineEnabled ?? this.cashMachineEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName,
      'shopCode': shopCode,
      'machineCode': machineCode,
      'contactNumber': contactNumber,
      'address': address,
      'cashMachineEnabled': cashMachineEnabled,
    }..removeWhere((key, value) => value == null);
  }

  factory BasicSettings.fromJson(Map<String, dynamic> json) {
    return BasicSettings(
      shopName: json['shopName'] as String?,
      shopCode: json['shopCode'] as String?,
      machineCode: json['machineCode'] as String?,
      contactNumber: json['contactNumber'] as String?,
      address: json['address'] as String?,
      cashMachineEnabled: _readBool(json['cashMachineEnabled']) ?? false,
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
    this.receipt = true,
    this.labelSize = '',
    this.continuous = false,
    this.isOn = false,
    this.isDefault = true,
    this.printIp,
    this.printPort,
    this.option = false,
    this.direction = true,
  });

  final String name;
  final int type;
  final bool receipt;
  final String labelSize;
  final bool continuous;
  final bool isOn;
  final bool isDefault;
  final String? printIp;
  final String? printPort;
  final bool option;
  final bool direction;

  PrinterSettings copyWith({
    String? name,
    int? type,
    bool? receipt,
    String? labelSize,
    bool? continuous,
    bool? isOn,
    bool? isDefault,
    String? printIp,
    String? printPort,
    bool? option,
    bool? direction,
  }) {
    return PrinterSettings(
      name: name ?? this.name,
      type: type ?? this.type,
      receipt: receipt ?? this.receipt,
      labelSize: labelSize ?? this.labelSize,
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
      'labelSize': labelSize,
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
      receipt: _readBool(json['receipt']) ?? true,
      labelSize: json['labelSize'] as String? ?? '',
      continuous: _readBool(json['continuous']) ?? false,
      isOn: _readBool(json['isOn']) ?? false,
      isDefault: _readBool(json['isDefault']) ?? false,
      printIp: json['printIp'] as String?,
      printPort: json['printPort']?.toString(),
      option: _readBool(json['option']) ?? false,
      direction: _readBool(json['direction']) ?? true,
    );
  }

  static List<PrinterSettings> defaultProfiles() {
    return const [
      PrinterSettings(
        name: 'キッチン',
        type: 10,
        receipt: true,
        labelSize: '',
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
        type: 10,
        receipt: false,
        labelSize: '',
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
        type: 11,
        receipt: true,
        labelSize: '',
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
        type: 12,
        receipt: true,
        labelSize: '',
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
