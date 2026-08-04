import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/storage/key_value_store.dart';
import 'package:shop_staff/data/services/pos_favorites_store.dart';
import 'package:shop_staff/domain/entities/product.dart';

void main() {
  test('persists complete favorite products on the device', () async {
    final storage = _MemoryKeyValueStore();
    final store = KeyValuePosFavoritesStore(storage);
    const product = Product(
      id: 7,
      name: 'Coffee',
      categoryId: 'drink',
      price: 300,
      originalPrice: 350,
      tax: 10,
      imageUrl: 'https://example.com/coffee.png',
      optionGroups: [
        OptionGroupEntity(
          groupCode: 'size',
          groupName: 'Size',
          multiple: false,
          minSelect: 1,
          maxSelect: 1,
          options: [
            OptionChoiceEntity(
              code: 'large',
              name: 'Large',
              extraPrice: 50,
              isDefault: false,
            ),
          ],
        ),
      ],
    );

    await store.save(const [product]);

    expect(await store.load(), const [product]);
  });

  test('ignores corrupt favorite data', () async {
    final storage = _MemoryKeyValueStore();
    await storage.write(AppStorageKeys.posFavoriteProducts, 'not-json');

    expect(await KeyValuePosFavoritesStore(storage).load(), isEmpty);
  });
}

class _MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clearAll() async => values.clear();

  @override
  Future<bool> contains(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
