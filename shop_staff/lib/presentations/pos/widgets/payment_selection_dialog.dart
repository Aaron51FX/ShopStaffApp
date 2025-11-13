import 'package:flutter/material.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';

typedef OnPaymentSelected = void Function(String group, String code);

// A large, vertical payment selection dialog. First row shows Cash and QR payments,
// second row Credit Cards, third row Transit/IC and E-money. Scrolls if overflow.
Future<void> showPaymentSelectionDialog({
  required BuildContext context,
  required ShopInfoModel shop,
  required OnPaymentSelected onSelected,
}) async {
  final m = shop.linePayChannelMap ?? const {};

  bool flag(String key) {
    final v = m[key];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1' || v.toLowerCase() == 'y';
    return false;
  }

  // Known channels by group
  final qrVendors = <_Vendor>[
    _Vendor('LinePay', 'LINE Pay'),
    _Vendor('PayPay', 'PayPay'),
    _Vendor('AliPay', 'Alipay'),
    _Vendor('Wechat', 'WeChat Pay'),
    _Vendor('m_Pay', 'メルペイ'),
    _Vendor('R_Pay', '楽天ペイ'),
    _Vendor('au_Pay', 'au PAY'),
    _Vendor('d_Pay', 'd払い'),
    _Vendor('famiPay', 'FamiPay'),
  ].where((v) => flag(v.key)).toList();

  final cardBrands = <_Vendor>[
    _Vendor('VISA', 'VISA'),
    _Vendor('MASTER', 'Mastercard'),
    _Vendor('JCB', 'JCB'),
    _Vendor('AMERICAN_EXPRESS', 'AMEX'),
    _Vendor('Diners_Club', 'Diners'),
    _Vendor('Discover', 'Discover'),
    _Vendor('UnionPay', 'UnionPay'),
  ].where((v) => flag(v.key)).toList();

  final transitBrands = <_Vendor>[
    _Vendor('iD', 'iD'),
    _Vendor('QUICPay', 'QUICPay'),
    _Vendor('WAON', 'WAON'),
    _Vendor('nanaco', 'nanaco'),
    _Vendor('rakutenEdy', '楽天Edy'),
    _Vendor('suica', 'Suica'),
    _Vendor('pasmo', 'PASMO'),
    _Vendor('nimoca', 'nimoca'),
    _Vendor('toica', 'TOICA'),
    _Vendor('manaca', 'manaca'),
    _Vendor('IC', 'ICOCA'),
    _Vendor('sugoca', 'SUGOCA'),
    _Vendor('hayakaken', 'はやかけん'),
  ].where((v) => flag(v.key) || flag('transportationIC')).toList();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'payment',
    barrierColor: Colors.black.withAlpha(115),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
              child: Material(
                color: Colors.white,
                elevation: 16,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(color: AppColors.amberPrimary),
                      child: Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('选择支付方式', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(ctx).pop(),
                          )
                        ],
                      ),
                    ),
                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Row 1: Cash + QR
                            Row(
                              children: [
                                Expanded(
                                  child: _GroupCard(
                                    title: '现金',
                                    leading: const Icon(Icons.attach_money, size: 28, color: Colors.green),
                                    child: const Text('现金支付'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      onSelected('cash', 'cash');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _GroupCard(
                                    title: '二维码支付',
                                    leading: const Icon(Icons.qr_code_2, size: 28, color: Colors.black87),
                                    onTap: qrVendors.isEmpty
                                        ? null
                                        : () {
                                            Navigator.of(ctx).pop();
                                            onSelected('qr', 'qr');
                                          },
                                    child: _VendorWrap(
                                      vendors: qrVendors,
                                      onTap: (v) {
                                        Navigator.of(ctx).pop();
                                        onSelected('qr', v.key);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Row 2: Credit Cards
                            _GroupCard(
                              title: '信用卡/刷卡',
                              leading: const Icon(Icons.credit_card, size: 28, color: Colors.blueAccent),
                              onTap: cardBrands.isEmpty
                                  ? null
                                  : () {
                                      Navigator.of(ctx).pop();
                                      onSelected('card', 'card');
                                    },
                              child: _VendorWrap(
                                vendors: cardBrands,
                                onTap: (v) {
                                  Navigator.of(ctx).pop();
                                  onSelected('card', v.key);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Row 3: Transit/IC & eMoney
                            _GroupCard(
                              title: '交通系/电子货币',
                              leading: const Icon(Icons.train, size: 28, color: Colors.deepPurple),
                              onTap: transitBrands.isEmpty
                                  ? null
                                  : () {
                                      Navigator.of(ctx).pop();
                                      onSelected('transit', 'transit');
                                    },
                              child: _VendorWrap(
                                vendors: transitBrands,
                                onTap: (v) {
                                  Navigator.of(ctx).pop();
                                  onSelected('transit', v.key);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Vendor {
  final String key;
  final String label;
  _Vendor(this.key, this.label);
}

class _VendorWrap extends StatelessWidget {
  final List<_Vendor> vendors;
  final void Function(_Vendor) onTap;
  const _VendorWrap({required this.vendors, required this.onTap});
  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const Text('未配置');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vendors
          .map((v) => InkWell(
                borderRadius: BorderRadius.circular(8),
                //onTap: () => onTap(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(v.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ))
          .toList(),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? leading;
  final VoidCallback? onTap;
  const _GroupCard({required this.title, required this.child, this.leading, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) leading!,
                if (leading != null) const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
