import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/services/shop_logo_cache_impl.dart';

void main() {
  test('downloads the activation logo into cache and returns base64', () async {
    final directory = await Directory.systemTemp.createTemp('shop_logo_test_');
    addTearDown(() => directory.delete(recursive: true));
    var downloadCount = 0;
    final cache = ShopLogoCacheImpl(
      downloader: (url) async {
        downloadCount++;
        expect(url, 'https://example.com/logo.png');
        return <int>[1, 2, 3, 4];
      },
      cacheDirectory: () async => directory,
    );

    final result = await cache.cache('https://example.com/logo.png');

    expect(downloadCount, 1);
    expect(result, isNotNull);
    expect(result!.base64, 'AQIDBA==');
    expect(await File(result.path).readAsBytes(), <int>[1, 2, 3, 4]);
  });

  test('uses the cached logo when a later refresh fails', () async {
    final directory = await Directory.systemTemp.createTemp('shop_logo_test_');
    addTearDown(() => directory.delete(recursive: true));
    var shouldFail = false;
    final cache = ShopLogoCacheImpl(
      downloader: (_) async {
        if (shouldFail) throw StateError('offline');
        return <int>[5, 6, 7];
      },
      cacheDirectory: () async => directory,
    );

    final first = await cache.cache('https://example.com/logo.png');
    shouldFail = true;
    final fallback = await cache.cache('https://example.com/logo.png');

    expect(first, isNotNull);
    expect(fallback?.path, first?.path);
    expect(fallback?.base64, first?.base64);
  });
}
