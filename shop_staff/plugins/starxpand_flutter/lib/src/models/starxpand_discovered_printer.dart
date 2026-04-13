import 'starxpand_printer_target.dart';

class StarXpandDiscoveredPrinter {
  const StarXpandDiscoveredPrinter({
    required this.transport,
    required this.identifier,
    this.host,
    this.modelName,
    this.displayName,
    this.connectionInfo,
  });

  factory StarXpandDiscoveredPrinter.fromJson(Map<String, dynamic> json) {
    final rawTransport = json['transport'] as String? ?? 'network';
    final transport = StarXpandTransport.values.firstWhere(
      (candidate) => candidate.wireValue == rawTransport,
      orElse: () => StarXpandTransport.network,
    );

    return StarXpandDiscoveredPrinter(
      transport: transport,
      identifier: (json['identifier'] ?? '').toString(),
      host: json['host'] as String?,
      modelName: json['modelName'] as String?,
      displayName: json['displayName'] as String?,
      connectionInfo: json['connectionInfo'] as String?,
    );
  }

  final StarXpandTransport transport;
  final String identifier;
  final String? host;
  final String? modelName;
  final String? displayName;
  final String? connectionInfo;
}
