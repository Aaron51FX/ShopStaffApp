import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_staff/data/models/shop_info_models.dart';

final preparePaymentSelectionUseCaseProvider = Provider<PreparePaymentSelectionUseCase>((ref) {
  return const PreparePaymentSelectionUseCase();
});

class PaymentSelectionOption {
  const PaymentSelectionOption({
    required this.group,
    required this.code,
    required this.label,
    required this.enabled,
  });

  final String group;
  final String code;
  final String label;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'group': group,
        'code': code,
        'label': label,
        'enabled': enabled,
      };
}

class PreparePaymentSelectionOutput {
  const PreparePaymentSelectionOutput({required this.options});

  final List<PaymentSelectionOption> options;

  Map<String, dynamic> toPayload({required int orderNumber, required double total}) => {
        'orderNumber': orderNumber,
        'total': total,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

class PreparePaymentSelectionUseCase {
  const PreparePaymentSelectionUseCase();

  PreparePaymentSelectionOutput execute({required ShopInfoModel shop}) {
    bool flag(String key) {
      final v = (shop.linePayChannelMap ?? const {})[key];
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1' || v.toLowerCase() == 'y';
      return false;
    }

    final hasQr = [
      'qr',
      'LinePay',
      'PayPay',
      'Alipay',
      'Wechat',
      'm_Pay',
      'R_Pay',
      'au_Pay',
      'd_Pay',
      'famiPay',
    ].any(flag);

    final hasCard = [
      'VISA',
      'MASTER',
      'JCB',
      'AMERICAN_EXPRESS',
      'Diners_Club',
      'Discover',
      'UnionPay',
    ].any(flag);

    return PreparePaymentSelectionOutput(
      options: [
        const PaymentSelectionOption(group: 'cash', code: 'cash', label: '现金', enabled: true),
        PaymentSelectionOption(group: 'qr', code: 'qr', label: '二维码', enabled: hasQr),
        PaymentSelectionOption(group: 'card', code: 'card', label: '信用卡', enabled: hasCard),
      ],
    );
  }
}
