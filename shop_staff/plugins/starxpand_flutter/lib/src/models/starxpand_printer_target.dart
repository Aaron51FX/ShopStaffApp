enum StarXpandTransport {
  network,
  bluetoothClassic,
  bluetoothLe,
  usb,
  usbC,
  lightningUsb,
}

extension StarXpandTransportX on StarXpandTransport {
  String get wireValue {
    switch (this) {
      case StarXpandTransport.network:
        return 'network';
      case StarXpandTransport.bluetoothClassic:
        return 'bluetooth_classic';
      case StarXpandTransport.bluetoothLe:
        return 'bluetooth_le';
      case StarXpandTransport.usb:
        return 'usb';
      case StarXpandTransport.usbC:
        return 'usb_c';
      case StarXpandTransport.lightningUsb:
        return 'lightning_usb';
    }
  }
}

class StarXpandPrinterTarget {
  const StarXpandPrinterTarget({
    required this.transport,
    this.identifier,
    this.host,
    this.port,
    this.modelName,
    this.autoSwitchInterface = false,
  });

  final StarXpandTransport transport;
  final String? identifier;
  final String? host;
  final int? port;
  final String? modelName;
  final bool autoSwitchInterface;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transport': transport.wireValue,
      if (identifier != null) 'identifier': identifier,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (modelName != null) 'modelName': modelName,
      'autoSwitchInterface': autoSwitchInterface,
    };
  }
}
