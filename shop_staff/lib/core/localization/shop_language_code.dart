String normalizeShopLanguageCode(String? code) {
  final normalized = code?.trim().toUpperCase() ?? '';
  if (normalized == 'CN' || normalized == 'ZH') {
    return 'CH';
  }
  return normalized;
}
