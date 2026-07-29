String parseSettlementOrderKey(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    throw const FormatException('Order code is empty');
  }

  final uri = Uri.tryParse(value);
  final looksLikeLink =
      value.contains('://') || value.contains('?') || value.contains('&');
  if (looksLikeLink) {
    final orderKey = uri?.queryParameters['p']?.trim();
    if (orderKey == null || orderKey.isEmpty) {
      throw const FormatException('Order link does not contain ?p=');
    }
    return orderKey;
  }

  return value;
}
