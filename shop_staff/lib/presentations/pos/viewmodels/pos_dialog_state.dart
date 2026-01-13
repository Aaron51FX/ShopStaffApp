import 'package:shop_staff/data/models/shop_info_models.dart';

enum PosDialogType {
  paymentSelection,
}

class PosDialogState {
  const PosDialogState._({
    required this.type,
    required this.shop,
    required this.total,
  });

  final PosDialogType type;
  final ShopInfoModel shop;
  final double total;

  const PosDialogState.paymentSelection({
    required ShopInfoModel shop,
    required double total,
  }) : this._(
          type: PosDialogType.paymentSelection,
          shop: shop,
          total: total,
        );
}
