class CachedShopLogo {
  const CachedShopLogo({required this.path, required this.base64});

  final String path;
  final String base64;
}

abstract class ShopLogoCache {
  Future<CachedShopLogo?> cache(String? imageUrl);
}
