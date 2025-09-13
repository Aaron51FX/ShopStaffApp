class OrderSubmissionResult {
  final String orderId;
  final int tax1; // 10% tax amount
  final int baseTax1; // base amount for tax1
  final int tax2; // 8% tax amount
  final int baseTax2; // base amount for tax2
  final int total; // total from backend (could differ from client computed)
  final String? message;
  final Map<String, dynamic>? menuLackMap; // items that lacked inventory if any

  const OrderSubmissionResult({
    required this.orderId,
    required this.tax1,
    required this.baseTax1,
    required this.tax2,
    required this.baseTax2,
    required this.total,
    this.message,
    this.menuLackMap,
  });

  factory OrderSubmissionResult.fromJson(Map<String, dynamic> json) {
    return OrderSubmissionResult(
      orderId: json['orderId'].toString(),
  tax1: (json['tax1'] is num) ? (json['tax1'] as num).toInt() : 0,
  baseTax1: (json['baseTax1'] is num) ? (json['baseTax1'] as num).toInt() : 0,
  tax2: (json['tax2'] is num) ? (json['tax2'] as num).toInt() : 0,
  baseTax2: (json['baseTax2'] is num) ? (json['baseTax2'] as num).toInt() : 0,
  total: (json['total'] is num) ? (json['total'] as num).toInt() : 0,
      message: json['message'] as String?,
      menuLackMap: json['menuLackMap'] is Map<String, dynamic>
          ? (json['menuLackMap'] as Map<String, dynamic>)
          : null,
    );
  }
}
