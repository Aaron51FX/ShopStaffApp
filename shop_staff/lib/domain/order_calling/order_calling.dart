bool isCallingOrderEvent(String event) => event == 'message';

class OrderCallingSettings {
  const OrderCallingSettings({
    this.enabled = false,
    this.ip = '',
    this.port = 3000,
  });
  final bool enabled;
  final String ip;
  final int port;

  static bool isValidIp(String value) {
    final text = value.trim();
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(text)) {
      return text.split('.').every((part) => int.parse(part) <= 255);
    }
    if (!text.contains(':') || !RegExp(r'^[0-9a-fA-F:]+$').hasMatch(text)) {
      return false;
    }
    try {
      Uri.parse('http://[$text]');
      return true;
    } on FormatException {
      return false;
    }
  }

  Uri get endpoint {
    if (!isValidIp(ip) || port < 1 || port > 65535) {
      throw const FormatException('Invalid order push IP or port');
    }
    return Uri(
      scheme: 'http',
      host: ip.trim(),
      port: port,
      path: '/api/add/order',
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'ip': ip.trim(),
    'port': port,
  };

  factory OrderCallingSettings.fromJson(Map<String, dynamic> json) {
    if (json['ip'] is String) {
      final rawPort = json['port'];
      return OrderCallingSettings(
        enabled: json['enabled'] == true,
        ip: (json['ip'] as String).trim(),
        port: rawPort is int
            ? rawPort
            : int.tryParse(rawPort?.toString() ?? '') ?? 3000,
      );
    }
    // Migrate the previously saved combined address without requiring re-entry.
    final oldAddress = (json['address'] as String? ?? '').trim();
    final oldUri = Uri.tryParse(
      oldAddress.contains('://') ? oldAddress : 'http://$oldAddress',
    );
    return OrderCallingSettings(
      enabled: json['enabled'] == true,
      ip: oldUri?.host ?? '',
      port: oldUri != null && oldUri.hasPort ? oldUri.port : 3000,
    );
  }
}

abstract class OrderCallingService {
  /// Persist an order delivery task; non-order events must not be forwarded.
  Future<void> enqueueOrder(
    Map<String, dynamic> payload, {
    required String source,
    String event = 'message',
  });
}
