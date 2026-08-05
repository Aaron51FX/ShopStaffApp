import 'package:intl/intl.dart';

import 'package:shop_staff/core/network/api_exception.dart';
import 'package:shop_staff/core/network/models/api_response.dart';
import 'package:shop_staff/data/datasources/remote/pos_remote_datasource.dart';
import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/domain/repositories/order_management_repository.dart';

class OrderManagementRepositoryImpl implements OrderManagementRepository {
  OrderManagementRepositoryImpl(this._remote);

  final PosRemoteDataSource _remote;

  @override
  Future<ManagedOrderPage> fetchOrders(ManagedOrderQuery query) async {
    final raw = await _remote.fetchManagedOrders({
      'shop_code': query.shopCode,
      'state': query.status.apiValue,
      'startPage': query.page,
      'limit': query.limit,
      'startDate': DateFormat('yyyy-MM-dd').format(query.startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(query.endDate),
    });
    final data = _asMap(_unwrapData(raw));
    final pageResult = _asMap(data?['pageResult']);
    final rows = _asList(pageResult?['rows']);
    final orders = rows
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(_parseOrder)
        .toList(growable: false);
    return ManagedOrderPage(
      orders: orders,
      hasMore: orders.length >= query.limit,
    );
  }

  @override
  Future<ManagedOrderDetail> fetchOrderDetail(ManagedOrder order) async {
    final raw = await _remote.fetchManagedOrderDetail(order.orderId);
    final data = _unwrapData(raw);
    final rows = _asList(data);
    return ManagedOrderDetail(
      order: order,
      lines: rows
          .map(_asMap)
          .whereType<Map<String, dynamic>>()
          .map(_parseLine)
          .toList(growable: false),
    );
  }

  @override
  Future<void> markPaid({
    required String orderId,
    required String payChannel,
  }) async {
    _ensureTrue(
      await _remote.markManagedOrderPaid(
        orderId: orderId,
        payChannel: payChannel,
      ),
    );
  }

  @override
  Future<void> cancelUnpaid(String orderId) async {
    _ensureTrue(await _remote.cancelUnpaidManagedOrder(orderId));
  }

  @override
  Future<void> cancelPaid(ManagedOrder order) async {
    if (order.usesOnlinePaymentCancellation) {
      _ensureTrue(
        await _remote.checkOnlineManagedOrderCancellation(order.orderId),
      );
      _ensureTrue(
        await _remote.confirmOnlineManagedOrderCancellation(order.orderId),
      );
      return;
    }
    _ensureTrue(await _remote.cancelPaidManagedOrder(order.orderId));
  }

  ManagedOrder _parseOrder(Map<String, dynamic> json) {
    return ManagedOrder(
      orderId: _string(json['orderId']),
      status: ManagedOrderStatus.fromApi(json['state']),
      createdAt: _date(json['creatTime'] ?? json['createTime']),
      price: _number(json['price']),
      serialNumber: _string(json['serialNumber']),
      payChannel: _string(json['payChannel']),
      payBizId: _string(json['payBizId']),
      payPrice: _number(json['payPrice']),
      changeAmount: _number(json['changeAmt']),
      discount: _number(json['discount']),
      payTime: _date(json['payTime']),
      remark: _string(json['remark']),
      takeout: _boolean(json['takeOut'] ?? json['takeout']),
    );
  }

  ManagedOrderLine _parseLine(Map<String, dynamic> json) {
    final options = <ManagedOrderOption>[];
    final optionMap = _asMap(json['optionVoMap']);
    optionMap?.forEach((groupName, rawValues) {
      for (final value in _asList(rawValues)) {
        final option = _asMap(value);
        if (option == null) continue;
        options.add(
          ManagedOrderOption(
            groupName: groupName,
            name: _string(
              option['mainTitle'] ?? option['name'] ?? option['optionName'],
            ),
            price: _number(option['price']),
            quantity: _integer(option['qty'], fallback: 1),
            code: _string(
              option['optionCode'] ?? option['code'] ?? option['bizId'],
            ),
          ),
        );
      }
    });
    return ManagedOrderLine(
      productId: _integer(json['menuId'] ?? json['productId'] ?? json['bizId']),
      categoryId: _string(json['categoryCode'] ?? json['categoryId']),
      name: _string(json['mainTitle'] ?? json['menuName'] ?? json['name']),
      quantity: _integer(json['qty'] ?? json['menuQty'], fallback: 1),
      price: _number(json['price']),
      tax: _integer(json['tax']),
      options: options,
    );
  }

  dynamic _unwrapData(dynamic raw) {
    final envelope = _asMap(raw);
    if (envelope == null) {
      throw ApiException('API response is not an object', data: raw);
    }
    final response = ApiResponse<dynamic>.fromJson(envelope);
    if (!response.isOk) {
      throw ApiException(
        response.message.isEmpty ? 'API request failed' : response.message,
        statusCode: response.code,
      );
    }
    return response.data;
  }

  void _ensureTrue(dynamic raw) {
    final envelope = _asMap(raw);
    if (envelope == null) {
      throw ApiException('API response is not an object', data: raw);
    }
    final response = ApiResponse<dynamic>.fromJson(envelope);
    if (!response.isOk || response.data != true) {
      throw ApiException(
        response.message.isEmpty ? 'Operation failed' : response.message,
        statusCode: response.code,
      );
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<dynamic> _asList(dynamic value) =>
      value is List ? value : const <dynamic>[];

  String _string(dynamic value) => value?.toString().trim() ?? '';

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_string(value).replaceAll(',', '')) ?? 0;
  }

  int _integer(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(_string(value)) ?? fallback;
  }

  bool _boolean(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = _string(value).toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  DateTime? _date(dynamic value) {
    final raw = _string(value);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }
}
