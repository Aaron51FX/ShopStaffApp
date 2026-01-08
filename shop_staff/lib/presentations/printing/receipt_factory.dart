import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/services/receipt_renderer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class ReceiptRendererImpl implements ReceiptRenderer {
  const ReceiptRendererImpl();

  @override
  ATempWidget? buildLabelHead({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  }) {
    final size = _ticketSize(printer.labelSize, true);
    final info = document.printInfo;
    if (info == null) return null;
    final timeTag =
        '${document.orderId}#${DateTime.now().toString().substring(5, 16)}';
    final totalQty = _expandLinesForLabels(
      document,
    ).fold<int>(0, (p, e) => p + (e.qty <= 0 ? 1 : e.qty));

    return headReceiptWidget(
      info.fromPlate,
      info.orderSnCode,
      info.orderTime,
      totalQty,
      info.remark,
      size.$1.toDouble(),
      size.$2.toDouble(),
      timeTag,
      rotate,
    );
  }

  @override
  List<ATempWidget> buildLabels({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  }) {
    final size = _ticketSize(printer.labelSize, true);
    final lines = _expandLinesForLabels(document);
    final timeTag =
        '${document.orderId}#${DateTime.now().toString().substring(5, 16)}';
    if (lines.isEmpty) return const [];

    final orderLabel = document.order.isNotEmpty
        ? document.order
        : (document.serialNumber ?? document.serialNo ?? '');

    return lines
        .map(
          (line) => labelItem(
            line.name,
            orderLabel,
            _toLegacyOptions(line.options),
            size.$1.toDouble(),
            size.$2.toDouble(),
            _labelMaxLine(size.$2.toInt()),
            rotate,
            '${lines.indexOf(line) + 1}/${lines.length}',
            timeTag,
          ),
        )
        .toList(growable: false);
  }

  @override
  ATempWidget buildContinuousReceipt({
    required PrintTicketInfo info,
    required List<Map<String, dynamic>> items,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
    bool isCenterPrint = false,
  }) {
    return ReceiptConstrainedBox(
      Transform(
        transform: Matrix4.rotationZ(rotate ? pi : 0.0),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            receiptTitle(
              info.orderSnCode,
              info.orderTime,
              info.fromPlate,
              isTakeOut: isTakeOut,
              continuous: true,
              isCenterPrint: isCenterPrint,
            ),
            ...items.map((item) {
              return menuItem(
                item['name'] as String? ?? '',
                item['qty'] as int? ?? 1,
                item['options'] as Map<String, List<Map<String, dynamic>>>,
                isUnderLine: true,
                needOption: printer.option,
                isContinuous: true,
                categoryName: item['categoryName'] as String? ?? '',
              );
            }),
            Container(
              alignment: Alignment.centerRight,
              child: Text(info.orderTime, style: const TextStyle(fontSize: 45)),
            ),
            if (info.remark.isNotEmpty) remarkTitle(info.remark),
            if (info.paymentCode.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'お会計について、QRコードを精算機にかざしていただき、お支払いくださいますようお願い申し上げます。\nご不明な点がございましたら、恐れ入りますがスタッフまでお声がけくださいませ。',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: BarcodeWidget(
                      height: 200,
                      width: 200,
                      barcode: Barcode.qrCode(),
                      data: info.paymentCode,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  ATempWidget buildSingleReceipt({
    required PrintTicketInfo info,
    required Map<String, dynamic> item,
    required PrinterSettings printer,
    required bool rotate,
    required bool isTakeOut,
  }) {
    return ReceiptConstrainedBox(
      Transform(
        transform: Matrix4.rotationZ(rotate ? pi : 0.0),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            receiptTitle(
              info.orderSnCode,
              info.orderTime,
              info.fromPlate,
              isTakeOut: isTakeOut,
              categoryName: printer.option
                  ? (item['categoryName'] as String? ?? '')
                  : '',
            ),
            menuItem(
              item['name'] as String? ?? '',
              item['qty'] as int? ?? 1,
              item['options'] as Map<String, List<Map<String, dynamic>>>,
              categoryName: printer.option
                  ? (item['categoryName'] as String? ?? '')
                  : '',
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Text(info.orderTime, style: const TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }

  // ==== Legacy helpers and widgets (copied from previous data-layer implementation) ====

  (T, T) _ticketSize<T extends num>(String raw, bool isLabel) {
    if (!isLabel) return (550 as T, -1 as T);
    if (raw.isEmpty) return (384 as T, 232 as T);
    final parts = raw.toLowerCase().split('x');
    if (parts.length != 2) return (450 as T, 300 as T);
    final width = num.tryParse(parts[0]) ?? 450;
    final height = num.tryParse(parts[1]) ?? 300;
    return (width as T, height as T);
  }

  int _labelMaxLine(int height) {
    if (height <= 0) return 2;
    return (height / (225 * 0.25)).floor();
  }

  List<Map<String, dynamic>> _toLegacyItems(List<PrintOrderLine> lines) {
    return lines
        .map(
          (line) => {
            'qty': line.qty,
            'name': line.name,
            'options': _toLegacyOptions(line.options),
            'categoryName': line.categoryName,
          },
        )
        .toList(growable: false);
  }

  Map<String, List<Map<String, dynamic>>> _toLegacyOptions(
    Map<String, List<PrintOrderOption>> options,
  ) {
    return options.map((key, value) {
      final opts = value
          .map((opt) => {'name': opt.name, 'qty': opt.qty})
          .toList(growable: false);
      return MapEntry(key, opts);
    });
  }

  List<PrintOrderLine> _expandLinesForLabels(PrintInfoDocument document) {
    final info = document.printInfo;
    if (info == null) return const <PrintOrderLine>[];
    final source = info.orderLinesMap.values.expand((e) => e).toList();
    final expanded = <PrintOrderLine>[];
    for (final line in source) {
      final qty = line.qty <= 0 ? 1 : line.qty;
      for (var i = 0; i < qty; i++) {
        expanded.add(line.copyWith(qty: 1));
      }
    }
    return expanded;
  }

  ATempWidget labelItem(
    String name,
    String number,
    Map<String, List<Map<String, dynamic>>> options,
    double printWidth,
    double printHeight,
    int maxLines,
    bool rotate,
    String index,
    String time,
  ) {
    return LabelConstrainedBox(
      Transform(
        transform: Matrix4.rotationZ(rotate ? pi : 0.0),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.only(right: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        name,
                        maxLines: 2,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 23,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              ' # $number',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: AutoSizeText(
                              index,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.black, thickness: 2),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.only(top: 5, left: 10),
                        width: double.infinity,
                        child: optionList(options, maxLines),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          time,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      pagerWidth: printWidth,
      pagerHeight: printHeight,
    );
  }

  ATempWidget headReceiptWidget(
    String fromPlate,
    String orderSnCode,
    String orderTime,
    int itemCount,
    String remark,
    double printWidth,
    double printHeight,
    String time,
    bool rotate,
  ) {
    return LabelConstrainedBox(
      Transform(
        transform: Matrix4.rotationZ(rotate ? pi : 0.0),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.only(right: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AutoSizeText(
                        fromPlate,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: AutoSizeText(
                              ' # $orderSnCode',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: AutoSizeText(
                              '$itemCount',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.black, thickness: 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AutoSizeText(
                      remark,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.only(top: 5),
                      child: Text(
                        time,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      pagerWidth: printWidth,
      pagerHeight: printHeight,
    );
  }

  Widget optionList(
    Map<String, List<Map<String, dynamic>>> options,
    int maxLines,
  ) {
    if (options.isEmpty) return Container();

    final optionStrings = options.entries
        .map((entry) {
          final optionName = entry.key;
          final optionValues = entry.value;
          return optionItem(optionName, optionValues);
        })
        .join('、');

    return AutoSizeText(
      optionStrings,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 28, color: Colors.black),
      overflow: TextOverflow.ellipsis,
    );
  }

  String optionItem(
    String optionName,
    List<Map<String, dynamic>> optionValues,
  ) {
    return "$optionName: ${optionValues.map((option) {
      final optionDetail = option['name']?.toString() ?? '';
      final optionQty = option['qty'] as int? ?? 1;
      final optionQtyString = optionQty == 1 ? '' : 'x $optionQty';
      return "$optionDetail $optionQtyString";
    }).join(', ')}";
  }

  Widget receiptTitle(
    String title,
    String orderTime,
    String fromPlate, {
    bool isTakeOut = false,
    bool continuous = false,
    bool isCenterPrint = false,
    String categoryName = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: continuous
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isTakeOut && !isCenterPrint)
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 28,
                      color: Colors.black,
                    ),
                  if (isTakeOut && isCenterPrint)
                    Text(
                      '$fromPlate # ',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (categoryName.isNotEmpty)
                AutoSizeText(
                  '[$categoryName]',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
          if (!continuous) const Divider(color: Colors.black, thickness: 1),
        ],
      ),
    );
  }

  Widget menuItem(
    String title,
    int qty,
    Map<String, List<Map<String, dynamic>>> option, {
    bool isUnderLine = false,
    bool needOption = true,
    bool isContinuous = false,
    String? categoryName,
  }) {
    final optionQtyString = qty == 1 ? '' : 'x $qty';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categoryName != null && categoryName.isNotEmpty && isContinuous)
            Text(
              '【$categoryName】',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 24, color: Colors.black),
                ),
              ),
              Text(
                optionQtyString,
                style: const TextStyle(fontSize: 24, color: Colors.black),
              ),
            ],
          ),
          if (option.isNotEmpty && needOption)
            ...option.entries.map((entry) {
              final optionName = entry.key;
              final optionValues = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '  $optionName',
                        style: const TextStyle(fontSize: 24),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: optionValues.map((option) {
                            final optionDetail =
                                option['name']?.toString() ?? '';
                            final optionQty = option['qty'] as int? ?? 1;
                            final optionQtyString = optionQty == 1
                                ? ''
                                : 'x $optionQty';
                            return Text(
                              '    $optionDetail $optionQtyString',
                              maxLines: 3,
                              style: const TextStyle(fontSize: 24),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
          if (isUnderLine)
            Container(
              margin: const EdgeInsets.only(top: 5),
              height: 1.5,
              color: Colors.black,
              width: double.infinity,
            ),
        ],
      ),
    );
  }

  Widget remarkTitle(String content) {
    return Text(
      content,
      style: const TextStyle(fontSize: 28, color: Colors.black),
    );
  }

  Widget _normalText(String content) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        content,
        style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _normalBoldText(String content) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        content,
        style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  ATempWidget buildReceipt({
    required String shopName,
    required String shopIcon,
    required String address,
    required String orderSnCode,
    required String telephone,
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
    required bool isTakeOut,
    required String payPrice,
    required String change,
    required String paymentMethod,
    required String tax1,
    required String baseTax1,
    required String tax2,
    required String baseTax2,
    required String total,

    String discount = '0',
    String voucherAmount = '0',
    String cardNumber = '',
  }) {
    //开头为 店铺icon + 店铺名称 + 地址
    //菜品信息
    //结尾为 时间 + 支付方式 + 支付金额 + 找零金额

    return ReceiptConstrainedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            child: Column(
              children: [
                if (shopIcon.isNotEmpty)
                  Image.network(
                    shopIcon,
                    width: 100.w,
                    height: 100.w,
                    fit: BoxFit.contain,
                  ),
                if (shopIcon.isEmpty)
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                _normalText(address),
                //電話番号
                _normalText("電話番号: $telephone"),
                _normalText(timeStamp),
                //注文番号
                _normalText("注文番号: $orderSnCode"),
                //お客様番号
                _normalBoldText("お客様番号: $number"),
                //draw a border text [領収書]
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Text(
                    '領 収 書',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          //菜品信息
          ...items.map((item) {
            final itemName = item['name'] as String? ?? '';
            final itemQty = item['qty'] as int? ?? 1;
            final price = item['price']?.toString();
            final itemOptions =
                item['options'] as Map<String, List<Map<String, dynamic>>>;
            return hReceiptMenuItem(
              itemName,
              itemQty,
              itemOptions,
              isUnderLine: false,
              needOption: false,
              price: price,
              fontSize: 18,
            );
          }),
          Divider(color: Colors.black, thickness: 2),
          //合计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '合計',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '¥$total',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Divider(color: Colors.black, thickness: 2),
          //税相关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '8% 对象',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                '¥$baseTax1',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '   内 消费税',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                '¥$tax1)',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10% 对象',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                '¥$baseTax2',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '   内 消费税',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                '¥$tax2)',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Divider(color: Colors.black, thickness: 2),
          //支付方式 + 支付金额 + 找零金额
          //如果不是现金支付
          if (paymentMethod != '現金支払')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  paymentMethod,
                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                ),
                Text(
                  '¥$payPrice',
                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          if (cardNumber.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'カード番号',
                  style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                ),
                Text(
                  cardNumber,
                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          if (paymentMethod == '現金支払')
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'お預かり',
                    style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '¥$payPrice',
                    style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '*軽減税率対象',
                    style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'お釣り',
                    style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '¥$change',
                    style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                'お明細は上記のとおりです。',
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ],          
          ),
          
        ],
      ),
    );
  }

  @override
  ATempWidget buildHReceipt({
    required String number,
    required List<Map<String, dynamic>> items,
    required String timeStamp,
  }) {
    //一行剧中标题 “お客様番号\n 12345”
    //中间显示菜品信息（每个菜 标题 -- 份数，如有options 另起一行显示）
    //底部显示时间 “2024-01-01 12:00”
    return ReceiptConstrainedBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            child: Text(
              'お客様番号\n $number',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ...items.map((item) {
            final itemName = item['name'] as String? ?? '';
            final itemQty = item['qty'] as int? ?? 1;
            final itemOptions =
                item['options'] as Map<String, List<Map<String, dynamic>>>;
            return hReceiptMenuItem(
              itemName,
              itemQty,
              itemOptions,
              isUnderLine: true,
              needOption: true,
            );
          }),
          Container(
            alignment: Alignment.centerRight,
            child: Text(timeStamp, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget hReceiptMenuItem(
    String title,
    int qty,
    Map<String, List<Map<String, dynamic>>> option, {
    bool isUnderLine = false,
    bool needOption = true,
    String? price,
    double fontSize = 20,
  }) {
    final optionQtyString = '$qty';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),


              Text(
                optionQtyString,
                style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              if (price != null)
              SizedBox(width: 20),

              if (price != null)
                Text(
                  '¥$price',
                  style: TextStyle(fontSize: fontSize, color: Colors.black, fontWeight: FontWeight.w600),
                ),

            ],
          ),
          if (option.isNotEmpty && needOption)
            ...option.entries.map((entry) {
              final optionName = entry.key;
              final optionValues = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '  $optionName',
                        style: TextStyle(fontSize: fontSize - 2, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: optionValues.map((option) {
                            final optionDetail =
                                option['name']?.toString() ?? '';
                            final optionQty = option['qty'] as int? ?? 1;
                            final optionQtyString = optionQty == 1
                                ? ''
                                : 'x $optionQty';
                            return Text(
                              '    $optionDetail $optionQtyString',
                              maxLines: 3,
                              style: TextStyle(fontSize: fontSize - 2, color: Colors.black, fontWeight: FontWeight.w600),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          if (isUnderLine)
            const Divider(color: Colors.black, thickness: 2),
        ],
      ),
    );
  }
}

class ReceiptConstrainedBox extends StatelessWidget with ATempWidget {
  const ReceiptConstrainedBox(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white, width: 550.w, child: child);
  }

  @override
  int get pixelPagerWidth => 550;

  @override
  double get pixelRatio => 1 / 1.w;
}

class LabelConstrainedBox extends StatelessWidget with ATempWidget {
  const LabelConstrainedBox(
    this.child, {
    super.key,
    this.pagerWidth = 384,
    this.pagerHeight = 232,
  });

  final Widget child;
  final double pagerWidth;
  final double pagerHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: ScreenUtil().setWidth(pagerWidth),
      height: pagerHeight.w,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        child: child,
      ),
    );
  }

  @override
  int get pixelPagerWidth => pagerWidth.toInt();

  @override
  int get pixelPagerHeight => pagerHeight.toInt();

  @override
  double get pixelRatio => 1 / 1.w;
}
