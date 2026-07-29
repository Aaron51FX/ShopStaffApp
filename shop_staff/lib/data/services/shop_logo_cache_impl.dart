import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/services/shop_logo_cache.dart';

typedef ShopLogoDownloader = Future<List<int>> Function(String imageUrl);
typedef ShopLogoCacheDirectory = Future<Directory> Function();

class ShopLogoCacheImpl implements ShopLogoCache {
  ShopLogoCacheImpl({
    required ShopLogoDownloader downloader,
    ShopLogoCacheDirectory? cacheDirectory,
    Logger? logger,
  }) : _downloader = downloader,
       _cacheDirectory = cacheDirectory ?? getTemporaryDirectory,
       _logger = logger ?? Logger('ShopLogoCache');

  final ShopLogoDownloader _downloader;
  final ShopLogoCacheDirectory _cacheDirectory;
  final Logger _logger;

  @override
  Future<CachedShopLogo?> cache(String? imageUrl) async {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return null;

    final directory = await _cacheDirectory();
    final logoDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}shop_staff_logo',
    );
    await logoDirectory.create(recursive: true);
    final file = File(
      '${logoDirectory.path}${Platform.pathSeparator}'
      'logo_${_stableHash(url)}.img',
    );

    try {
      debugPrint('[ShopLogoCache] download start: ${_urlWithoutQuery(url)}');
      final bytes = await _downloader(url);
      if (bytes.isEmpty) {
        throw const FormatException('Downloaded logo is empty');
      }
      await file.writeAsBytes(bytes, flush: true);
      _logger.fine('Cached shop logo: ${file.path}');
      debugPrint(
        '[ShopLogoCache] cached bytes=${bytes.length} path=${file.path}',
      );
      return CachedShopLogo(path: file.path, base64: base64Encode(bytes));
    } catch (error, stack) {
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          _logger.warning(
            'Logo refresh failed; using cached image: ${file.path}',
            error,
            stack,
          );
          debugPrint(
            '[ShopLogoCache] refresh failed; using cache '
            'bytes=${bytes.length} path=${file.path}',
          );
          return CachedShopLogo(path: file.path, base64: base64Encode(bytes));
        }
      }
      _logger.warning('Unable to cache shop logo', error, stack);
      debugPrint('[ShopLogoCache] download failed: $error');
      return null;
    }
  }
}

String _urlWithoutQuery(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return value;
  return uri.replace(query: null).toString();
}

String _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
