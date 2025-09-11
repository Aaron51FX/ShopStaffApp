import 'package:flutter/material.dart';

import '../models/shop_info_models.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_models.dart';
import '../datasources/remote/pos_remote_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final PosRemoteDataSource _remote;
  MenuRepositoryImpl(this._remote);

  List<CategoryModel>? _cachedCategories;

  @override
  Future<List<CategoryModel>> fetchCategories({required String machineCode, String language = 'JP', bool takeout = false}) async {
    if (_cachedCategories != null) return _cachedCategories!;
  final raw = await _remote.fetchCategoriesV2(machineCode: machineCode, language: language, takeout: takeout);
    final list = _parseCategoriesFlexible(raw);
    // 仅在非空时缓存，避免把一次异常/空结果锁死
    if (list.isNotEmpty) {
      _cachedCategories = list;
    }
    return list;
  }

  @override
  Future<List<Product>> fetchFirstPage({required String machineCode, String language = 'JP', bool takeout = false}) async {
    // 调用与分类相同的接口, 服务端返回 categoryVoList, 每个分类里可能有 menuVoList 代表首批商品
    final raw = await _remote.fetchHomeMenu(machineCode: machineCode, language: language, takeout: takeout);
    final products = <Product>[];
    // 解析分类 (并缓存)
    final catList = _parseCategoriesFlexible(raw);
    if (catList.isNotEmpty) {
      debugPrint('[MenuRepo] Parsed categories count=${catList.length} from home menu');
      if (_cachedCategories == null && catList.isNotEmpty) {
        _cachedCategories = catList;
      }
      for (final c in catList) {
        for (final item in c.menuVoList) {
          if (item is Map) {
            try {
              final model = MenuItemModel.fromJson(Map<String, dynamic>.from(item.cast<String, dynamic>()));
              products.add(_toEntity(model));
            } catch (_) {
              // swallow a single malformed item
            }
          }
        }
      }
    } else if (raw is List) {
      // 兼容: 接口直接返回商品数组
      final models = parseMenuItems(raw.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      products.addAll(models.map(_toEntity));
    }
    return products;
  }

  @override
  Future<List<Product>> fetchMenuByCategory({required String machineCode, String language = 'JP', bool takeout = false, required String categoryCode}) async {
    // 不再使用 _cache 里的所有商品过滤; 按需请求
    final raw = await _remote.fetchMenuByCategoryV2(
      machineCode: machineCode,
      language: language,
      takeout: takeout,
      categoryCode: categoryCode,
    );
    debugPrint('[MenuRepo] fetchMenuByCategory raw type=${raw.runtimeType}');
    debugPrint('[MenuRepo] fetchMenuByCategory raw content=${raw.toString()}');
    if (raw is List) {
  return _safeParseMenuList(raw);
    }
    // 兼容后端包装: 尝试在常见 data/result/payload 下找 list
    if (raw is Map<String, dynamic>) {
      for (final k in ['data','result','payload']) {
        final v = raw[k];
        debugPrint('[MenuRepo] fetchMenuByCategory envelope key=$k type=${v.runtimeType}');
        if (v is List) {
          debugPrint('[MenuRepo] fetchMenuByCategory found list under key=$k count=${v.length}');
          final entities = _safeParseMenuList(v);
          debugPrint('[MenuRepo] fetchMenuByCategory parsed models count=${entities.length}');
          return entities;
        }
      }
    }
    return const [];
  }

  List<Product> _safeParseMenuList(List dynamicList) {
    final list = <Product>[];
    for (var i = 0; i < dynamicList.length; i++) {
      final rawItem = dynamicList[i];
      if (rawItem is! Map) {
        debugPrint('[MenuRepo] skip index=$i not a Map type=${rawItem.runtimeType}');
        continue;
      }
      try {
        final normalized = _normalizeMenuJson(Map<String, dynamic>.from(rawItem.cast<String, dynamic>()));
        final model = MenuItemModel.fromJson(normalized);
        list.add(_toEntity(model));
      } catch (e, st) {
        debugPrint('[MenuRepo] parse item failed index=$i error=$e json=$rawItem');
        debugPrint(st.toString());
      }
    }
    return list;
  }

  Map<String, dynamic> _normalizeMenuJson(Map<String, dynamic> json) {
    // subtitle: 后端可能是 null / string / list
    final sub = json['subtitle'];
    if (sub == null) {
      json['subtitle'] = <String>[]; // match factory default (List<String>)
    } else if (sub is String) {
      json['subtitle'] = sub.isEmpty ? <String>[] : <String>[sub];
    } else if (sub is List) {
      json['subtitle'] = sub.whereType<String>().toList();
    }
    // tax: 后端给了字符串 "0"
    final tax = json['tax'];
    if (tax is String) {
      json['tax'] = int.tryParse(tax) ?? 0;
    } else if (tax == null) {
      json['tax'] = 0;
    }
    // optionGroupVoList: 可能为 null
    if (json['optionGroupVoList'] == null || json['optionGroupVoList'] is! List) {
      json['optionGroupVoList'] = <Map<String, dynamic>>[];
    }
    // 深度规范化 optionGroupVoList -> optionVoList 数字字段
    final ogList = json['optionGroupVoList'];
    if (ogList is List) {
      for (var gi = 0; gi < ogList.length; gi++) {
        final g = ogList[gi];
        if (g is Map) {
          // 组层级
          final ms = g['multipleState'];
            if (ms is String) g['multipleState'] = int.tryParse(ms) ?? 0;
            else if (ms is! int) g['multipleState'] = 0;
          final sm = g['smallest'];
            if (sm is String) g['smallest'] = int.tryParse(sm) ?? 0;
            else if (sm is! int) g['smallest'] = 0;
          // 子选项
          final ovList = g['optionVoList'];
          if (ovList is List) {
            for (var oi = 0; oi < ovList.length; oi++) {
              final o = ovList[oi];
              if (o is Map) {
                for (final key in ['price','currentPrice','standard','bounds','boundsPrice']) {
                  final v = o[key];
                  if (v is String) {
                    o[key] = int.tryParse(v) ?? (v.isEmpty ? null : null);
                  } else if (v == null) {
                    // leave null; model允许部分为 null
                  } else if (v is num) {
                    o[key] = v.toInt();
                  }
                }
              }
            }
          } else {
            g['optionVoList'] = <Map<String, dynamic>>[];
          }
        } else {
          // 非 Map 条目丢弃
          ogList[gi] = <String, dynamic>{
            'groupCode': 'UNK_$gi',
            'groupName': 'UNK',
            'printText': 'UNK',
            'remark': null,
            'multipleState': 0,
            'smallest': 0,
            'optionVoList': <Map<String, dynamic>>[],
          };
        }
      }
    }
    // timeBoundsStart/End: 可能为 null
    if (json['timeBoundsStart'] == null || json['timeBoundsStart'] is! List) {
      json['timeBoundsStart'] = <int>[];
    }
    if (json['timeBoundsEnd'] == null || json['timeBoundsEnd'] is! List) {
      json['timeBoundsEnd'] = <int>[];
    }
    // ensure required numeric fields
    json['currentPrice'] ??= json['price'] ?? 0;
    json['qtyBounds'] ??= -1;
    json['type'] ??= 1;
    return json;
  }

  Product _toEntity(MenuItemModel m) => Product(
        id: int.tryParse(m.menuCode) ?? m.menuCode.hashCode,
        name: m.mainTitle,
        categoryId: m.categoryCode,
  price: m.currentPrice.toDouble(),
  originalPrice: m.price.toDouble(),
  tax: m.tax,
        imageUrl: m.homeImage ?? '',
        optionGroups: m.optionGroupVoList.map(_mapGroup).toList(),
      );

  OptionGroupEntity _mapGroup(OptionGroupModel g) => OptionGroupEntity(
        groupCode: g.groupCode,
        groupName: g.groupName,
        multiple: g.multipleState != 1, // assumption: 1 single, else multi
        minSelect: g.smallest,
        maxSelect: null,
        options: g.optionVoList.map(_mapOption).toList(),
      );

  OptionChoiceEntity _mapOption(OptionVoModel o) => OptionChoiceEntity(
        code: o.optionCode,
        name: o.mainTitle,
        extraPrice: (o.currentPrice ?? o.price ?? 0).toDouble(),
        isDefault: o.standard == 1,
      );

  // --- Flexible parsing helpers ---
  List<CategoryModel> _parseCategoriesFlexible(dynamic raw) {
    try {
      final extracted = _extractCategoryArray(raw);
      if (extracted == null) {
        // ignore: avoid_print
        print('[MenuRepo] No category array found in raw response type=${raw.runtimeType}');
        return const <CategoryModel>[];
      }
      final list = extracted
          .whereType<Map>()
          .map((e) => CategoryModel.fromJsonSafe(Map<String, dynamic>.from(e.cast<String, dynamic>())))
          .toList();
      // ignore: avoid_print
      print('[MenuRepo] Parsed categories count=${list.length}');
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('[MenuRepo] Category parse error: $e');
      return const <CategoryModel>[];
    }
  }

  List<dynamic>? _extractCategoryArray(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      // Direct keys
      for (final key in ['categoryVoList', 'categoryList', 'categories']) {
        final v = raw[key];
        if (v is List) return v;
      }
      // Deep envelope traversal (handle data -> data -> result ...)
      final envelopeKeys = ['data', 'result', 'payload'];
      final seen = <int>{};
      dynamic cursor = raw;
      bool progressed = true;
      while (progressed && cursor is Map<String, dynamic>) {
        progressed = false;
        for (final env in envelopeKeys) {
          final inner = cursor[env];
            if (inner is List) return inner;
            if (inner is Map<String, dynamic>) {
              // Check keys inside
              for (final key in ['categoryVoList', 'categoryList', 'categories']) {
                final v = inner[key];
                if (v is List) return v;
              }
              // move deeper only if map hash not seen to avoid loops
              final h = identityHashCode(inner);
              if (!seen.contains(h)) {
                seen.add(h);
                cursor = inner;
                progressed = true;
                break;
              }
            }
        }
      }
    }
    return null;
  }
}

