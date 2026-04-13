import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:starxpand_flutter/starxpand_flutter.dart';

class StarXpandPrinterDiscoveryService {
  StarXpandPrinterDiscoveryService({StarXpandFlutter? plugin})
    : _plugin = plugin ?? StarXpandFlutter();

  final StarXpandFlutter _plugin;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  List<StarXpandTransport> get supportedLocalTransports {
    if (kIsWeb) {
      return const <StarXpandTransport>[];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const <StarXpandTransport>[
          StarXpandTransport.bluetoothClassic,
          StarXpandTransport.bluetoothLe,
          StarXpandTransport.lightningUsb,
        ];
      case TargetPlatform.android:
        return const <StarXpandTransport>[
          StarXpandTransport.bluetoothClassic,
          StarXpandTransport.bluetoothLe,
          StarXpandTransport.usbC,
        ];
      default:
        return const <StarXpandTransport>[];
    }
  }

  Future<List<StarXpandDiscoveredPrinter>> discoverLocalPrinters({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final transports = supportedLocalTransports;
    if (transports.isEmpty) {
      throw StateError(
        'Star printer discovery is only available on iOS and Android.',
      );
    }

    try {
      return await _plugin.discoverPrinters(
        transports: transports,
        timeout: timeout,
      );
    } on MissingPluginException {
      throw StateError(
        'StarXpand Flutter plugin is not registered on this platform.',
      );
    } on PlatformException catch (error) {
      final message = error.message;
      throw StateError(
        message == null || message.isEmpty
            ? 'Star printer discovery failed (${error.code}).'
            : message,
      );
    }
  }
}
