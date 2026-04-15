import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/order_submission_result.dart';
import 'package:shop_staff/domain/payments/payment_models.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/presentations/payment/viewmodels/payment_flow_page_args.dart';

final buildPaymentFlowArgsUseCaseProvider =
    Provider<BuildPaymentFlowArgsUseCase>((ref) {
      return const BuildPaymentFlowArgsUseCase();
    });

class BuildPaymentFlowArgsUseCase {
  const BuildPaymentFlowArgsUseCase();

  PaymentFlowPageArgs execute({
    required OrderSubmissionResult order,
    required ShopInfoModel shop,
    required String machineCode,
    required String group,
    required String code,
    required PaymentFlowMode paymentMode,
    String? label,
    required List<CartItem> items,
    required String language,
    required bool takeout,
    BasicSettings? basic,
    PosTerminalSettings? posInfo,
  }) {
    final config = Map<String, dynamic>.from(
      shop.linePayChannelMap ?? const {},
    );
    config['selectedChannel'] = code;

    if (paymentMode == PaymentFlowMode.real && group == PaymentChannels.card) {
      final String ip = posInfo?.posIp ?? '';
      final int port = posInfo?.posPort ?? 0;
      config['posIp'] = ip;
      config['posPort'] = port;

      if (ip.isEmpty) {
        throw StateError('POS_IP_MISSING');
      }
      if (port == 0) {
        throw StateError('POS_PORT_INVALID');
      }
    }

    final metadata = <String, dynamic>{
      'machineCode': machineCode,
      'shopCode': shop.shopCode,
      'shopName': shop.shopName,
      'language': language,
      'takeout': takeout,
      'channelDisplayName': label,
      'cartItems': List<CartItem>.from(items),
      'paymentMode': paymentMode.wireValue,
    };

    return PaymentFlowPageArgs(
      order: order,
      channelGroup: group,
      channelCode: code,
      paymentMode: paymentMode,
      channelDisplayName: label,
      channelConfig: config.isEmpty ? null : config,
      metadata: metadata,
    );
  }
}
