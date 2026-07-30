import 'package:logging/logging.dart';
import 'package:shop_staff/application/checkout/models/checkout_payment_request.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class PreparePaymentChannelConfigUseCase {
  PreparePaymentChannelConfigUseCase({
    required AppSettingsSnapshot? Function() readSettingsSnapshot,
    Logger? logger,
  }) : _readSettingsSnapshot = readSettingsSnapshot,
       _logger = logger ?? Logger('PreparePaymentChannelConfigUseCase');

  final AppSettingsSnapshot? Function() _readSettingsSnapshot;
  final Logger _logger;

  Map<String, dynamic>? call(CheckoutPaymentRequest args) {
    final raw = args.channelConfig;
    final config = <String, dynamic>{};
    if (raw != null) {
      raw.forEach((key, value) {
        if (value != null) config[key] = value;
      });
    }

    config.putIfAbsent('machineCode', () => args.metadata?['machineCode']);

    final needsPos =
        args.paymentMode == PaymentFlowMode.real &&
        args.channelGroup == PaymentChannels.card;
    if (needsPos) {
      final posInfo = _readSettingsSnapshot()?.posTerminal;
      final ip = posInfo?.posIp?.toString();
      final dynamic portRaw = posInfo?.posPort;
      int? port;
      if (portRaw is int) {
        port = portRaw;
      } else if (portRaw is String) {
        port = int.tryParse(portRaw);
      }

      if (args.channelGroup == PaymentChannels.card) {
        if (ip == null || ip.isEmpty) {
          throw StateError('POS_IP_MISSING');
        }
        if (port == null) {
          throw StateError('POS_PORT_INVALID');
        }
      }

      if (ip != null && ip.isNotEmpty) {
        config['posIp'] = ip;
      }
      if (port != null) {
        config['posPort'] = port;
      }
      config['paymentCode'] = (config['paymentCode'] ?? '3').toString();
      config.putIfAbsent('authCode', () => '0000000088888888');
    }

    if (config.isEmpty) return null;
    _logger.fine('Prepared payment channel config: ${config.keys.toList()}');
    return config;
  }
}
