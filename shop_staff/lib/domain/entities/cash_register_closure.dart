class CashRegisterClosureVerifyInput {
  const CashRegisterClosureVerifyInput({
    required this.machineCode,
    required this.verifyCode,
    required this.verifyEmail,
    required this.verifyUserName,
  });

  final String machineCode;
  final String verifyCode;
  final String verifyEmail;
  final String verifyUserName;

  Map<String, dynamic> toJson() => {
    'machineCode': machineCode,
    'verifyCode': verifyCode,
    'verifyEmail': verifyEmail,
    'verifyUserName': verifyUserName,
  };
}

class CashRegisterClosureMailAccount {
  const CashRegisterClosureMailAccount({
    required this.verifyEmail,
    required this.verifyUserName,
  });

  final String verifyEmail;
  final String verifyUserName;

  factory CashRegisterClosureMailAccount.fromJson(Map<String, dynamic> json) {
    return CashRegisterClosureMailAccount(
      verifyEmail: (json['verifyEmail'] ?? '').toString(),
      verifyUserName: (json['verifyUserName'] ?? '').toString(),
    );
  }
}

class CashRegisterCashInfoEntry {
  const CashRegisterCashInfoEntry({
    required this.backup,
    required this.income,
    required this.remain,
  });

  final String backup;
  final String income;
  final String remain;

  factory CashRegisterCashInfoEntry.fromJson(Map<String, dynamic> json) {
    return CashRegisterCashInfoEntry(
      backup: (json['backup'] ?? '').toString(),
      income: (json['income'] ?? '').toString(),
      remain: (json['remain'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'backup': backup,
    'income': income,
    'remain': remain,
  };
}

class CashRegisterClosureSummary {
  const CashRegisterClosureSummary({
    required this.machineCode,
    required this.shopCode,
    required this.shopName,
    required this.startTime,
    required this.endTime,
    required this.printTime,
    required this.verifyCode,
    required this.verifyEmail,
    required this.verifyUserName,
    required this.cashInfo,
    required this.cashInfoGlory,
    required this.aliPayTotal,
    required this.auPayTotal,
    required this.cashTotal,
    required this.creditCardTotal,
    required this.dPayTotal,
    required this.discountTotal,
    required this.mPayTotal,
    required this.noTaxTotal,
    required this.payPayTotal,
    required this.qty,
    required this.qtyA,
    required this.qtyB,
    required this.rPayTotal,
    required this.repaymentQty,
    required this.repaymentTotal,
    required this.taxTotal,
    required this.taxTotalA,
    required this.taxTotalB,
    required this.total,
    required this.trafficTotal,
    required this.voucherAmountTotal,
    required this.wechatTotal,
  });

  final String machineCode;
  final String shopCode;
  final String shopName;
  final String startTime;
  final String endTime;
  final String printTime;
  final String verifyCode;
  final String verifyEmail;
  final String verifyUserName;
  final Map<String, CashRegisterCashInfoEntry> cashInfo;
  final Map<String, int> cashInfoGlory;
  final int aliPayTotal;
  final int auPayTotal;
  final int cashTotal;
  final int creditCardTotal;
  final int dPayTotal;
  final int discountTotal;
  final int mPayTotal;
  final int noTaxTotal;
  final int payPayTotal;
  final int qty;
  final int qtyA;
  final int qtyB;
  final int rPayTotal;
  final int repaymentQty;
  final int repaymentTotal;
  final int taxTotal;
  final int taxTotalA;
  final int taxTotalB;
  final int total;
  final int trafficTotal;
  final int voucherAmountTotal;
  final int wechatTotal;

  factory CashRegisterClosureSummary.fromJson(Map<String, dynamic> json) {
    return CashRegisterClosureSummary(
      machineCode: _readString(json, 'machineCode'),
      shopCode: _readString(json, 'shopCode'),
      shopName: _readString(json, 'shopName'),
      startTime: _readString(json, 'startTime'),
      endTime: _readString(json, 'endTime'),
      printTime: _readString(json, 'printTime'),
      verifyCode: _readString(json, 'verifyCode'),
      verifyEmail: _readString(json, 'verifyEmail'),
      verifyUserName: _readString(json, 'verifyUserName'),
      cashInfo: _readCashInfo(json['cashInfo']),
      cashInfoGlory: _readIntMap(json['cashInfoGlory']),
      aliPayTotal: _readInt(json, 'aliPayTotal'),
      auPayTotal: _readInt(json, 'au_PayTotal'),
      cashTotal: _readInt(json, 'cashTotal'),
      creditCardTotal: _readInt(json, 'creditCardTotal'),
      dPayTotal: _readInt(json, 'd_PayTotal'),
      discountTotal: _readInt(json, 'discountTotal'),
      mPayTotal: _readInt(json, 'm_PayTotal'),
      noTaxTotal: _readInt(json, 'noTaxTotal'),
      payPayTotal: _readInt(json, 'payPayTotal'),
      qty: _readInt(json, 'qty'),
      qtyA: _readInt(json, 'qtyA'),
      qtyB: _readInt(json, 'qtyB'),
      rPayTotal: _readInt(json, 'r_PayTotal'),
      repaymentQty: _readInt(json, 'repaymentQty'),
      repaymentTotal: _readInt(json, 'repaymentTotal'),
      taxTotal: _readInt(json, 'taxTotal'),
      taxTotalA: _readInt(json, 'taxTotalA'),
      taxTotalB: _readInt(json, 'taxTotalB'),
      total: _readInt(json, 'total'),
      trafficTotal: _readInt(json, 'trafficTotal'),
      voucherAmountTotal: _readInt(json, 'voucherAmountTotal'),
      wechatTotal: _readInt(json, 'wechatTotal'),
    );
  }

  Map<String, dynamic> toJson() => {
    'machineCode': machineCode,
    'shopCode': shopCode,
    'shopName': shopName,
    'startTime': startTime,
    'endTime': endTime,
    'printTime': printTime,
    'verifyCode': verifyCode,
    'verifyEmail': verifyEmail,
    'verifyUserName': verifyUserName,
    'cashInfo': cashInfo.map((key, value) => MapEntry(key, value.toJson())),
    'cashInfoGlory': Map<String, int>.from(cashInfoGlory),
    'aliPayTotal': aliPayTotal,
    'au_PayTotal': auPayTotal,
    'cashTotal': cashTotal,
    'creditCardTotal': creditCardTotal,
    'd_PayTotal': dPayTotal,
    'discountTotal': discountTotal,
    'm_PayTotal': mPayTotal,
    'noTaxTotal': noTaxTotal,
    'payPayTotal': payPayTotal,
    'qty': qty,
    'qtyA': qtyA,
    'qtyB': qtyB,
    'r_PayTotal': rPayTotal,
    'repaymentQty': repaymentQty,
    'repaymentTotal': repaymentTotal,
    'taxTotal': taxTotal,
    'taxTotalA': taxTotalA,
    'taxTotalB': taxTotalB,
    'total': total,
    'trafficTotal': trafficTotal,
    'voucherAmountTotal': voucherAmountTotal,
    'wechatTotal': wechatTotal,
  };

  static Map<String, CashRegisterCashInfoEntry> _readCashInfo(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) {
      final entry = value is Map
          ? CashRegisterCashInfoEntry.fromJson(Map<String, dynamic>.from(value))
          : const CashRegisterCashInfoEntry(backup: '', income: '', remain: '');
      return MapEntry(key.toString(), entry);
    });
  }

  static Map<String, int> _readIntMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), _toInt(value)));
  }

  static String _readString(Map<String, dynamic> json, String key) {
    return (json[key] ?? '').toString();
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    return _toInt(json[key]);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return num.tryParse(value)?.round() ?? 0;
    return 0;
  }
}

class NoLatestCashRegisterClosureDataException implements Exception {
  const NoLatestCashRegisterClosureDataException();

  @override
  String toString() => 'No latest cash register closure data';
}
