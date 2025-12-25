// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_printer_plus/flutter_printer_plus.dart' as printerPlus;
// import 'package:print_image_generate_tool/print_image_generate_tool.dart';


// class PrintService extends GetxService {
//   final MachineInfoController _machineInfo;

//   PrintService(this._machineInfo);

//   get printerList => _machineInfo.printerList;
//   get sseList => _machineInfo.sseSettingList;

//   //Label打印先存在在一个队列中
//   //final Queue<Widget> labelPrintQueue = Queue<Widget>();

//   final testData = [
//     {
//       "uuid": "YK-0HObr4iVk_NaDfVw9WoEH",
//       "bizId": 462461846396796928,
//       "orderTime": "19:12",
//       "remark": "",
//       "from_plate": "Shop",
//       "order_sn_code": "A17",
//       "payment_code": "",
//       "order_type": "Shop_In",
//       "pay_type": "Paid",
//       "orderLinesMap": {
//         "12": [
//           {
//             "categoryName": "ドリンク",
//             "name": "ジンジャーエール",
//             "price": 600,
//             "qty": 1,
//             "bizId": 462461855189106697,
//             "options": {},
//             "extend2qr": null
//           }
//         ],
//         "10": [
//           {
//             "categoryName": "メインディッシュ",
//             "name": "お刺身5種盛り",
//             "price": 3000,
//             "qty": 1,
//             "bizId": 462461855189106688,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "ポテサラ",
//             "price": 1400,
//             "qty": 1,
//             "bizId": 462461855189106689,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "ローストビーフサラダ",
//             "price": 2800,
//             "qty": 1,
//             "bizId": 462461855189106690,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "おでん",
//             "price": 1500,
//             "qty": 1,
//             "bizId": 462461855189106691,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "おすすめ",
//             "name": "和牛煮込み",
//             "price": 1200,
//             "qty": 1,
//             "bizId": 462461855189106692,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "すき焼き",
//             "price": 8000,
//             "qty": 2,
//             "bizId": 462461855189106693,
//             "options": {
//               "トッピング": [
//                 {
//                   "name": "うどん",
//                   "price": null,
//                   "qty": 1
//                 }
//               ]
//             },
//             "extend2qr": null
//           },
//           {
//             "categoryName": "小食",
//             "name": "追い 卵",
//             "price": 600,
//             "qty": 3,
//             "bizId": 462461855189106695,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "おすすめ",
//             "name": "和牛フレーク丼",
//             "price": 2500,
//             "qty": 1,
//             "bizId": 462461855189106696,
//             "options": {},
//             "extend2qr": null
//           }
//         ]
//       },
//       "orderLines": null
//     },
//     {
//       "uuid": "eg36fyjt5igDZVTl7yNzEs7j",
//       "bizId": 462461756707897344,
//       "orderTime": "19:56",
//       "remark": "",
//       "from_plate": "Shop",
//       "order_sn_code": "A9",
//       "payment_code": "",
//       "order_type": "Shop_In",
//       "pay_type": "Paid",
//       "orderLinesMap": {
//         "10": [
//           {
//             "categoryName": "アイス",
//             "name": "アイス",
//             "price": 1000,
//             "qty": 1,
//             "bizId": 462462547208372224,
//             "options": {
//               "味": [
//                 {"name": "ココナツ", "price": null, "qty": 1}
//               ]
//             },
//             "extend2qr": null
//           }
//         ]
//       },
//       "orderLines": null
//     },
//     {
//       "uuid": "XsBjuzH1zlwqCPWDInYd3iDr",
//       "bizId": 462461756707897344,
//       "orderTime": "19:58",
//       "remark": "",
//       "from_plate": "Shop",
//       "order_sn_code": "A9",
//       "payment_code": "",
//       "order_type": "Shop_In",
//       "pay_type": "Paid",
//       "orderLinesMap": {
//         "10": [
//           {
//             "categoryName": "メインディッシュ",
//             "name": "和牛煮込み",
//             "price": 1200,
//             "qty": 1,
//             "bizId": 462462566741508096,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "ホッケ",
//             "price": 2500,
//             "qty": 1,
//             "bizId": 462462566741508097,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "焼鳥-かわ",
//             "price": 750,
//             "qty": 3,
//             "bizId": 462462566741508098,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "メインディッシュ",
//             "name": "カツレツ",
//             "price": 2400,
//             "qty": 1,
//             "bizId": 462462566741508099,
//             "options": {},
//             "extend2qr": null
//           }
//         ]
//       },
//       "orderLines": null
//     },
//     {
//       "uuid": "mLhBiJaR0KPV0FaElX-fed42",
//       "bizId": 462460811105992704,
//       "orderTime": "20:03",
//       "remark": "",
//       "from_plate": "Shop",
//       "order_sn_code": "A15",
//       "payment_code": "",
//       "order_type": "Shop_In",
//       "pay_type": "Paid",
//       "orderLinesMap": {
//         "12": [
//           {
//             "categoryName": "ドリンク",
//             "name": "ウーロン茶",
//             "price": 600,
//             "qty": 1,
//             "bizId": 462462655712133120,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "ドリンク",
//             "name": "ジンジャーエール",
//             "price": 600,
//             "qty": 1,
//             "bizId": 462462655712133121,
//             "options": {},
//             "extend2qr": null
//           },
//           {
//             "categoryName": "ドリンク",
//             "name": "コーラ",
//             "price": 600,
//             "qty": 1,
//             "bizId": 462462655712133122,
//             "options": {},
//             "extend2qr": null
//           }
//         ]
//       },
//       "orderLines": null
//     },
//     {
//       "uuid": "QRNRA_Q5ZQX_vASszPuqGjV-",
//       "bizId": 462461756707897344,
//       "orderTime": "20:14",
//       "remark": "",
//       "from_plate": "Shop",
//       "order_sn_code": "A9",
//       "payment_code": "",
//       "order_type": "Shop_In",
//       "pay_type": "Paid",
//       "orderLinesMap": {
//         "10": [
//           {
//             "categoryName": "メインディッシュ",
//             "name": "和牛煮込み",
//             "price": 1200,
//             "qty": 1,
//             "bizId": 462462819377020928,
//             "options": {},
//             "extend2qr": null
//           }
//         ]
//       },
//       "orderLines": null
//     }
//   ];

//   // 全局队列 + 是否正在排队
//   final Queue<Widget> _labelQueue = Queue<Widget>();
//   bool _labelDraining = false;

//   void processLabelPrintQueueNew(
//       String printerIp, Queue<Widget> labelPrintQueue) {
//     if (labelPrintQueue.isEmpty) return;
//     _labelQueue.addAll(labelPrintQueue); // 合并到全局队列
//     _ensureLabelDrain(printerIp); // 启动/复用单次循环
//   }

//   void _ensureLabelDrain(String printerIp) {
//     if (_labelDraining) return;
//     _labelDraining = true;
//     _drainLabelQueue(printerIp);
//   }

//   Future<void> _drainLabelQueue(String printerIp) async {
//     try {
//       while (_labelQueue.isNotEmpty) {
//         final widget = _labelQueue.removeFirst();
//         PictureGeneratorProvider.instance.addPicGeneratorTask(
//           PicGenerateTask<PrinterInfo>(
//             tempWidget: widget as ATempWidget,
//             printTypeEnum: PrintTypeEnum.label,
//             params: PrinterInfo(ip: printerIp), // 不做 IP 检查
//           ),
//         );
//         await Future.delayed(const Duration(seconds: 1)); // 每张间隔 1 秒
//       }
//     } finally {
//       _labelDraining = false;
//       // 若刚结束又入队了，补一次启动
//       if (_labelQueue.isNotEmpty) {
//         _ensureLabelDrain(printerIp);
//       }
//     }
//   }

//   //创建一个方法来处理打印队列
//   void processLabelPrintQueue(String printerIp, Queue<Widget> labelPrintQueue) {
//     Timer.periodic(Duration(milliseconds: 1000), (timer) {
//       if (labelPrintQueue.isEmpty) {
//         timer.cancel(); // 停止定时器
//         return;
//       }

//       final widget = labelPrintQueue.removeFirst();
//       PictureGeneratorProvider.instance.addPicGeneratorTask(
//         PicGenerateTask<PrinterInfo>(
//           tempWidget: widget as ATempWidget,
//           printTypeEnum: PrintTypeEnum.label,
//           params: PrinterInfo(ip: printerIp),
//         ),
//       );
//     });
//   }

//   callbackBeforePrint(String event, Map data, {int retryCount = 0}) async {
//     // if (event == 'efficientPrint') {
//     //     _printEfficientLabel(data);
//     // }
//     String uuid = data['uuid'] ?? '';
//     if (uuid.isEmpty) return;

//     try {
//       logI("callbackBeforePrint uuid: $uuid send"); //会出现发送没有回复的现象15秒超时了。
//       final val = await request('sseCallback',
//           method: 'POST',
//           parameters: {'uuid': uuid}).timeout(const Duration(seconds: 15));
//       var response = json.decode(val.toString());
//       if (response != null &&
//           response['code'] == 200 &&
//           response['data'] != null) {
//         logI("callbackBeforePrint uuid: $uuid send success");
//         if (event == 'message' || event == 'rePrint') {
//           printData(data);
//         }
//         if (event == 'print') {
//           printTableSeatInfo(data);
//         }
//         if (event == 'expiryPrint') {
//           _printEfficientLabel(data);
//         }
//       }
//     } on TimeoutException catch (e) {
//       logI('TimeoutException:${e.toString()}');
//       if (retryCount < 3) {
//         // 如果超时，重试最多3次
//         logI("callbackBeforePrint uuid: $uuid retrying... ($retryCount)");
//         await Future.delayed(Duration(seconds: 2));
//         callbackBeforePrint(event, data, retryCount: retryCount + 1);
//       } else {
//         logI("callbackBeforePrint uuid: $uuid failed after retries");
//       }
//     } catch (e) {
//       logI('error Exception:${e.toString()}');
//       if (retryCount < 3) {
//         // 如果发生错误，重试最多3次
//         logI("callbackBeforePrint uuid: $uuid retrying... ($retryCount)");
//         await Future.delayed(Duration(seconds: 2));
//         callbackBeforePrint(event, data, retryCount: retryCount + 1);
//       } else {
//         logI("callbackBeforePrint uuid: $uuid failed after retries");
//       }
//     }
//   }

//   Future<void> testPrint() async {
//     int index = 0;
//     for (var data in testData) {
//       //间隔2秒打印
//       index += 1;
//       printData(data);
//       await Future.delayed(Duration(seconds: 15));
//       if (index > 1) {
//         break;
//       }
//     }
//   }

//   void printData(Map data, {bool fromSSE = true, String orderId = ""}) async {
//     logI("---printData---");
//     final fromPlate = data["from_plate"] ?? "";
//     final orderType = data["order_type"] ?? "";
//     final orderSnCode = data["order_sn_code"] ?? "";
//     final orderTime = data["orderTime"] ?? "";
//     final orderLinesMap = data["orderLinesMap"] ?? {};
//     final remark = data["remark"] ?? "";
//     var payment_code = data["payment_code"] ?? "";
//     bool isInShop = data["from_plate"] == "Shop";
//     bool isTakeOut = orderType != 'Shop_In';// || orderType == 'takeout' || orderType == 'pickup' || orderType == 'Takeout';

//     final centerPrinter = printerList.firstWhere(
//       (p) => p["type"] == 11,
//       orElse: () => null,
//     );
//     final smartWeSSE = sseList.firstWhere(
//       (sse) => sse["name"] == 'SmartWe SSE',
//       orElse: () => null,
//     );

//     bool isCenterPrintOn = centerPrinter != null && !centerPrinter["isOff"] && centerPrinter["printIp"] != null && centerPrinter["printIp"].isNotEmpty;
//     bool smartWeCenterOn = smartWeSSE != null && smartWeSSE["centerOn"] && isCenterPrintOn;
//     List orderLineItems = [];

//     for (var key in orderLinesMap.keys) {

//       final items = orderLinesMap[key];
//       orderLineItems = orderLineItems + items;

//       final printer = printerList.firstWhere(
//         (p) => p["type"].toString() == key && !p["isOff"],
//         orElse: () => null,
//       );
//       if (printer == null) {
//         logI("Printer IP not configured for key: $key");
//         continue;
//       }
//       final printerIp = printer["printIp"];
//       if (printerIp == null || printerIp.isEmpty) {
//         logI("Printer IP is empty for key: $key");
//         continue;
//       }

//       bool isLabelPrint = printer['receipt'] == 1; // Label printing
//       bool isContinuous = printer['continuous'] == 1; // Continuous printing


//       final rotate = printer["direction"] == 1; // Rotate if direction is 1
//       bool printCategory =
//           printer['printCategory'] ?? false; // Print category name



//       if (isLabelPrint) {
//         // If label printing is enabled, print each item separately
//         // 先打印票号和基本信息
//         final Queue<Widget> labelPrintQueue = Queue<Widget>();
//         final printSize = printer['labelSize'] ?? '300x225';
//         final printWidth = int.tryParse(printSize.split('x')[0]) ?? 300; // 获取标签宽度
//         final printHeight = int.tryParse(printSize.split('x')[1]) ?? 225; // 获取标签高度
//         // Add the head receipt widget to the print queue
//         debugPrint("Label Print Width: $printWidth, Height: $printHeight");
//         final time =
//             orderId + "#" + await DateTime.now().toString().substring(5, 16);
//         var totalQty = 0;
//         for (var item in items) {
//           totalQty += (item["qty"] ?? 0) as int;
//         }

//         int itemCount = 0;

//         for (var item in items) {
//           final qty = item["qty"] ?? 1;
//           final name = item["name"] ?? "";
//           final options = item["options"] ?? {};

//           for (var i = 0; i < qty; i++) {
//             // Generate the receipt widget
//             itemCount += 1;
//             final receiptWidget = labelItem(
//                 name,
//                 orderSnCode,
//                 options,
//                 printWidth.toDouble(),
//                 printHeight.toDouble(),
//                 _labelMaxLine(printHeight),
//                 rotate,
//                 '$totalQty-$itemCount',
//                 time);
//             labelPrintQueue.add(receiptWidget);
//           }
//         }

//         if (isTakeOut) {
//           final headReceipt = headReceiptWidget(
//             fromPlate,
//             orderSnCode,
//             orderTime,
//             //orderType,
//             itemCount,
//             remark,
//             printWidth.toDouble(),
//             printHeight.toDouble(),
//             time,
//             rotate,
//           );

//           labelPrintQueue.addFirst(headReceipt);
//         }

//         processLabelPrintQueue(printerIp, labelPrintQueue);
//         // If center printing is enabled, print the same data to the center printer
//         // if (isCenterPrintOn || smartWeCenterOn) {
//         //   final printIp = centerPrinter["printIp"];
//         //   final rotate = centerPrinter["direction"] == 1;
//         //
//         //   printContinuousData(fromPlate, isTakeOut, orderSnCode, orderTime,
//         //       printIp, true, rotate, items, remark, isCenterPrint: true);
//         // }
//         continue;
//       }

//       if (isContinuous) {
//         // If continuous printing is enabled, print all items in one go
//         printContinuousData(fromPlate, isTakeOut, orderSnCode, orderTime,
//             printerIp, isContinuous, rotate, items, remark,
//             printCategory: printCategory);
//       } else {
//         // If label printing is enabled, print each item separately
//         printSingleData(fromPlate, isTakeOut, orderSnCode, orderTime, printerIp,
//             isContinuous, rotate, items, printCategory, remark);
//       }
//       // If center printing is enabled, print the same data to the center printer
//       // if (isTakeOut && isCenterPrintOn || smartWeCenterOn) {
//       //   final printIp = centerPrinter["printIp"];
//       //   final rotate = centerPrinter["direction"] == 1;
//       //
//       //   printContinuousData(fromPlate, isTakeOut, orderSnCode, orderTime,
//       //       printIp, true, rotate, items, remark, isCenterPrint: true);
//       // }
//     }

//     if ((isCenterPrintOn && isTakeOut) || (fromSSE && smartWeCenterOn && isInShop)) {
//       final printIp = centerPrinter["printIp"];
//       final rotate = centerPrinter["direction"] == 1;
//       bool option = centerPrinter['option'] ?? false; // 是否打印选项
//       //假设 payment_code = https://mobile.smartwe.jp/index?p=jM6JKGOpPij9OHl-xlsgl 获取 jM6JKGOpPij9OHl-xlsgl
//       if (payment_code.isNotEmpty) {
//         //如果有支付码，打印支付码
//         payment_code = payment_code.split("=").last;
//       }

//       printContinuousData(fromPlate, isTakeOut, orderSnCode, orderTime,
//           printIp, true, rotate, orderLineItems, remark, isCenterPrint: true,
//           printOption: option, printQrCode: payment_code);
//     }


//   }

//   _labelMaxLine(int height) {
//     //计算标签最大行数
//     //假设每行高度为 50
//     return (height / (225 * 0.25)).floor();
//   }
//   // shopCode=UGE4RRQR,
//   // number=MAT009,
//   // name=オレンジスライス,
//   // saveMethod=冷蔵庫内＋蓋付き,
//   // expiredNumber=0,
//   // efficientType=CURRENT_DATE,
//   // expiredTimeStr=2025-11-21  店じまい廃棄,
//   // printTimeStr=2025-11-21 16:30:31,
//   // operatorName=倪圣

//   //_printEfficientLabel
//   _printEfficientLabel(Map data) async {
//     logI("_printEfficientLabel data: $data");

//     final printer = printerList.firstWhere(
//       (p) => p["type"] == 10 && !p["isOff"] && p['receipt'] == 1,
//       orElse: () => null,
//     );
//     if (printer == null) {
//       logI("Printer IP not configured for type 10");
//       return;
//     }

//     double rotate =
//         printer["direction"] == 1 ? pi : 0.0; // Rotate if direction is 1
//     final printSize = printer['labelSize'] ?? '300x225';
//     final printWidth = double.parse(printSize.split('x')[0]); // 获取标签宽度
//     final printHeight = double.parse(printSize.split('x')[1]); // 获取标签高度
//     debugPrint(
//         "Print size: $printSize, Width: $printWidth, Height: $printHeight");

//     //final number = data["number"] ?? "";
//     final name = data["name"] ?? "";
//     final saveMethod = data["saveMethod"] ?? "";
//     //final expexpiredNumber = data["expiredNumber"] ?? "";
//     //final efficientType = data["efficientType"] ?? "";
//     final expiredTimeStr = data["expiredTimeStr"] ?? "";
//     final printTimeStr = data["printTimeStr"] ?? "";
//     final operatorName = data["operatorName"] ?? "";
//     //String expiredTime = "当日廃棄";
//     // if (efficientType.isEmpty) {
//     //   logI("efficientType is empty");
//     //   return;
//     // }
//     // if (efficientType == "HOURS") {
//     //   expiredTime = "+ $expexpiredNumber 時間";
//     // } else if (efficientType == "DAYS") {
//     //   expiredTime = "+ $expexpiredNumber 日";
//     // }

//     final imageWidget = await _efficientLabel(name, saveMethod, expiredTimeStr,
//         printTimeStr, operatorName, printWidth, printHeight, rotate);

//     //show print preview
//     // Get.dialog(
//     //   AlertDialog(
//     //     title: Text('Print Preview'),
//     //     content: Container(
//     //       width: printWidth,
//     //       height: printHeight,
//     //       child: imageWidget,
//     //     ),
//     //     actions: [
//     //       TextButton(
//     //         onPressed: () {
//     //           Get.back();

//     //         },
//     //         child: Text('Close'),
//     //       ),
//     //     ],
//     //   ),
//     // );

//     //生成打印图层任务，指定任务类型为标签
//     PictureGeneratorProvider.instance.addPicGeneratorTask(
//       PicGenerateTask<PrinterInfo>(
//         tempWidget: imageWidget as ATempWidget,
//         printTypeEnum: PrintTypeEnum.label,
//         params: PrinterInfo(ip: printer["printIp"]),
//       ),
//     );
//   }

//   _efficientLabel(
//       String name,
//       String saveMethod,
//       String expiredTimeStr,
//       String printTimeStr,
//       String operatorName,
//       double printWidth,
//       double printHeight,
//       rotate) async {
//     final printMenus = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           margin: EdgeInsets.only(top: 16, bottom: 3),
//           child: Text(
//             name,
//             maxLines: 2,
//             textAlign: TextAlign.left,
//             style: TextStyle(
//               fontSize: 26,
//               color: Colors.black,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         Container(
//           margin: EdgeInsets.only(bottom: 4),
//           child: AutoSizeText(saveMethod,
//               textAlign: TextAlign.right,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               )),
//         ),
//         Container(
//           margin: EdgeInsets.only(bottom: 4),
//           child: AutoSizeText("開封：$printTimeStr",
//               maxLines: 1,
//               textAlign: TextAlign.left,
//               style: TextStyle(
//                 fontSize: 22,
//                 color: Colors.black,
//                 fontWeight: FontWeight.w500,
//               )),
//         ),
//         Container(
//           margin: EdgeInsets.only(bottom: 4),
//           child: AutoSizeText("期限切れ：$expiredTimeStr",
//               maxLines: 2,
//               textAlign: TextAlign.left,
//               style: TextStyle(
//                 fontSize: 22,
//                 color: Colors.black,
//                 fontWeight: FontWeight.w500,
//               )),
//         ),
//       ],
//     );

//     return LabelConstrainedBox(
//       Transform(
//         transform: Matrix4.rotationZ(rotate),
//         alignment: Alignment.center,
//         child: printMenus,
//       ),
//       pagerWidth: printWidth,
//       pagerHeight: printHeight,
//     );
//   }

// //{description: いらっしゃいませ。お客様のスマートフォンで、QRコードをスキャンしてご注文をお願いします。お帰りの際は、QRコードを精算機にスキャンして、お支払いくださいますようお願いいたします。ご不明な点がございましたら、スタッフまでお声がけくださいませ。, line1: 卓番：Ａ０２, line2: セルフオーダーQR票, qrCode: a1ght77ycN0OnMBijXzt_}
//   printTableSeatInfo(Map data) async {
//     logI("---printTableSeatInfo---");
//     final smartWeSSE = sseList.firstWhere(
//       (sse) => sse["name"] == 'SmartWe SSE',
//       orElse: () => null,
//     );
    

//     if (smartWeSSE == null || !(smartWeSSE["printSeat"] ?? true)) {
//       debugPrint("SmartWe SSE printSeat is off");
//       return;
//     }

//       //find pinter with type 11
//       final printer = printerList.firstWhere(
//         (p) => p["type"] == 11 && !p["isOff"],
//         orElse: () => null,
//       );
//       if (printer == null) {
//         print("Printer IP not configured for type 11");
//         return;
//       }

//       double rotate = printer["direction"] == 1 ? pi : 0.0; // Rotate if direction is 1

//       //final currentTime = DateTime.now().toString().substring(0, 19).replaceAll(" ", "\n");
//       final description = data["description"] ?? "";
//       final qrCode = data["qrCode"] ?? "";
//       final seatNumber = data["line1"] ?? "";
//       final line2 = data["line2"] ?? "";

//       final imageWidget = await _tableSeat(seatNumber, line2, description, qrCode, rotate);

//       // 生成打印图层任务，指定任务类型为标签
//       //TaskQueueUtils().addTask(task_smartwe_print)?.then((result) {
//       PictureGeneratorProvider.instance.addPicGeneratorTask(
//           PicGenerateTask<PrinterInfo>(
//             tempWidget: imageWidget as ATempWidget,
//             printTypeEnum: PrintTypeEnum.receipt,
//             params: PrinterInfo(ip: printer["printIp"]),
//           ),
//       );
//       //});


//   }

//   _tableSeat(String line1, String line2, String description, String qrCode, rotate) async {
//     List<Widget> printMenus = [];
//     printMenus.add(
//       Column(
//         children: [
//           Container(
//             margin: EdgeInsets.only(bottom: 8),
//             child: Directionality(
//                 textDirection: ui.TextDirection.ltr,
//                 child: Text(line1,
//                     style: TextStyle(
//                       fontSize: 45.sp,
//                       fontWeight: FontWeight.w500,
//                       color: ColorsUtil.hexToColor("#000000"),
//                     ))),
//           ),
//           Container(
//             margin: EdgeInsets.only(bottom: 8),
//             child: Directionality(
//                 textDirection: ui.TextDirection.ltr,
//                 child: Text(line2,
//                     style: TextStyle(
//                       fontSize: 40.sp,
//                       fontWeight: FontWeight.w500,
//                       color: ColorsUtil.hexToColor("#000000"),
//                     ))),
//           ),
//           Container(
//             margin: EdgeInsets.only(bottom: 4),
//             width: 270.w,
//             height: 280.h,
//             child: BarcodeWidget(
//               height: 280,
//               barcode: Barcode.qrCode(),
//               data: qrCode,
//             )

//             // QrImage(
//             //   size: 380,
//             //   data: orderKey,
//             // ),
//           ),
//           Container(
//             margin: EdgeInsets.only(bottom: 5),
//             child: Directionality(
//                 textDirection: ui.TextDirection.ltr,
//                 child: Text(
//                     description,
//                     style: TextStyle(
//                       fontSize: 32.sp,
//                       fontWeight: FontWeight.w400,
//                       color: ColorsUtil.hexToColor("#000000"),
//                     ))),
//           ),

//         ],
//       ),
//     );

//     return ReceiptConstrainedBox(
//         Transform(
//             transform: Matrix4.rotationZ(rotate),
//             alignment: Alignment.center,
//             child:Container(
//               //width: 560,
//               //height: 720,
//               padding: EdgeInsets.only(left: 0.5, right: 0.5),
//               color: Colors.white,
//               alignment: Alignment.topCenter,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: printMenus,
//               ),
//             )));
//   }


//   Widget labelItem(
//     String name,
//     String number,
//     Map options,
//     double printWidth,
//     double printHeight,
//     int maxLines,
//     bool rotate,
//     String index,
//     String time,
//   ) {

//     return LabelConstrainedBox(
//       Transform(
//         transform: Matrix4.rotationZ(rotate ? pi : 0.0),
//         alignment: Alignment.center,
//         child: Container(
//           padding: EdgeInsets.only(right: 3),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(
//                 height: 80.h,
//                 //flex: 1,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: Text(
//                         //
//                         name,
//                         maxLines: 2,
//                         textAlign: TextAlign.left,
//                         style: TextStyle(
//                           fontSize: 23,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         overflow: TextOverflow.ellipsis, // 超出部分显示省略号
//                       ),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Expanded(
//                             flex: 1,
//                             child: AutoSizeText(
//                               ' # ' + number,
//                               textAlign: TextAlign.right,
//                               maxLines: 1,
//                               style: TextStyle(
//                                 fontSize: 30,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis, // 超出部分显示省略号
//                             ),
//                           ),
//                           Expanded(
//                             flex: 1,
//                             child: AutoSizeText(
//                               index,
//                               textAlign: TextAlign.right,
//                               maxLines: 1,
//                               style: TextStyle(
//                                 fontSize: 30,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis, // 超出部分显示省略号
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(
//                 color: Colors.black,
//                 thickness: 2,
//               ),
//               Expanded(
//                 //flex: 2,
//                 child: Column(
//                   children: [
//                     Expanded(
//                       flex: 4,
//                       child: Container(
//                         margin: EdgeInsets.only(top: 5, left: 10),
//                         width: double.infinity,
//                         child: optionList(options, maxLines),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 1,
//                       child: Container(
//                         alignment: Alignment.centerRight,
//                         margin: EdgeInsets.only(top: 5),
//                         child: Text(
//                           time,
//                           textAlign: TextAlign.right,
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       pagerWidth: printWidth,
//       pagerHeight: printHeight,
//     );
//   }

//   Widget headReceiptWidget(
//       String fromPlate,
//       String orderSnCode,
//       String orderTime,
//       //String orderType,
//       int itemCount,
//       String remark,
//       double printWidth,
//       double printHeight,
//       String time,
//       bool rotate) {
//     return LabelConstrainedBox(
//         Transform(
//             transform: Matrix4.rotationZ(rotate ? pi : 0.0),
//             alignment: Alignment.center,
//             child: Container(
//               padding: EdgeInsets.only(right: 3),
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(
//                       height: 80.h,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             flex: 3,
//                             child: AutoSizeText(
//                               fromPlate,
//                               textAlign: TextAlign.left,
//                               maxLines: 2,
//                               style: TextStyle(
//                                 fontSize: 50,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               overflow: TextOverflow.ellipsis, // 超出部分显示省略号
//                             ),
//                           ),
//                           Expanded(
//                             flex: 2,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Expanded(
//                                   flex: 1,
//                                   child: AutoSizeText(
//                                     ' # ' + orderSnCode,
//                                     textAlign: TextAlign.right,
//                                     maxLines: 1,
//                                     style: TextStyle(
//                                       fontSize: 30,
//                                       color: Colors.black,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     overflow:
//                                         TextOverflow.ellipsis, // 超出部分显示省略号
//                                   ),
//                                 ),
//                                 Expanded(
//                                   flex: 1,
//                                   child: AutoSizeText(
//                                     '$itemCount',
//                                     textAlign: TextAlign.right,
//                                     maxLines: 1,
//                                     style: TextStyle(
//                                       fontSize: 30,
//                                       color: Colors.black,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     overflow:
//                                         TextOverflow.ellipsis, // 超出部分显示省略号
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Divider(
//                       color: Colors.black,
//                       thickness: 2,
//                     ),
//                     Expanded(
//                       //flex: 2,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           AutoSizeText(
//                             remark,
//                             maxLines: 4,
//                             style: TextStyle(
//                               fontSize: 24,
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             overflow: TextOverflow.ellipsis, // 超出部分显示省略号
//                           ),
//                           Container(
//                             alignment: Alignment.centerRight,
//                             margin: EdgeInsets.only(top: 5),
//                             child: Text(
//                               time,
//                               textAlign: TextAlign.right,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ]),
//             )),
//         pagerWidth: printWidth,
//         pagerHeight: printHeight);
//   }

//   Widget optionItem1(String optionName, List optionValues) {
//     return Container(
//       child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "$optionName：",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black
//                   ),
//                 ),
//                 ...optionValues.map((option) {
//                   final optionDetail = option["name"] ?? "";
//                   final optionQty = option["qty"] ?? 1;
//                   final optionQtyString = optionQty == 1 ? "" : "x $optionQty";
//                   return Text(
//                     " $optionDetail $optionQtyString ",
//                     style: TextStyle(
//                       fontSize: 20,
//                         color: Colors.black,
//                     ),
//                   );
//                 }).toList(),
//               ],
//             ),
//     );
//   }

//   String optionItem(String optionName, List optionValues) {

//     //返回Option字符串组合 格式 optionName: optionDetail1, optionDetail2 x qty2;
//     return "$optionName: " +
//         optionValues.map((option) {
//           final optionDetail = option["name"] ?? "";
//           final optionQty = option["qty"] ?? 1;
//           final optionQtyString = optionQty == 1 ? "" : "x $optionQty";
//           return "$optionDetail $optionQtyString";
//         }).join(", ");
//   }

//   Widget optionList(Map options, int maxLines) {
//     //合并所有Option为一个字符串格式为 optionName: optionDetail1 x qty1, optionDetail2 x qty2;
//     if (options.isEmpty) {
//       return Container(); // 如果没有选项，返回空容器
//     }

//     String optionStrings = options.entries.map((entry) {
//       final optionName = entry.key;
//       final optionValues = entry.value;
//       return optionItem(optionName, optionValues);
//     }).join("、");

//     //使用 AutoText来自动调整文本大小
//     return AutoSizeText(
//       optionStrings,
//       maxLines: maxLines, // 最多显示两行
//       style: TextStyle(
//         fontSize: 28,
//         color: Colors.black,
//       ),
//       overflow: TextOverflow.ellipsis, // 超出部分显示省略号
//     );
//   }


//   //打印逻辑为 连票打印时 只有一个标题receiptTitle 中间为菜品menuItem，最后右下角为下单时间
//   //使用 printData 的同样参数实现这个需求

//   printContinuousData(
//       String fromPlate,
//       bool isTakeOut,
//       String orderSnCode,
//       String orderTime,
//       String printerIp,
//       bool isContinuous,
//       bool isRotate,
//       List items,
//       String remark,
//   {bool isCenterPrint = false,
//     bool printOption = true,
//     String? printQrCode,
//     bool printCategory = false,
//   }) async {
//     final rotate = isRotate ? pi : 0.0;

//     // Generate the receipt widget
//     final receiptWidget = ReceiptConstrainedBox(
//       Transform(
//         transform: Matrix4.rotationZ(rotate),
//         alignment: Alignment.center,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             receiptTitle(orderSnCode, orderTime, fromPlate,
//                 isTakeOut: isTakeOut, continuous: true, isCenterPrint: isCenterPrint),
//             ...items.map((item) {
//               final qty = item["qty"] ?? 1;
//               final name = item["name"] ?? "";
//               final options = item["options"] ?? {};
//               final categoryName = item["categoryName"] ?? "";
//               return menuItem(name, qty, options,
//                   isUnderLine: true,
//                   needOption: printOption,
//                   isContinuous: true,
//                   categoryName: printCategory ? categoryName : null);
//             }).toList(),
//             Container(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 orderTime,
//                 style: TextStyle(
//                   fontSize: 45,
//                 ),
//               ),
//             ),

//             if (isCenterPrint && remark.isNotEmpty)
//             remarkTitle(remark),

//             if (printQrCode != null && printQrCode.isNotEmpty)
//               Row(
//                 spacing: 20,
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child:
//                     Container(
//                       //margin: EdgeInsets.all(20),
//                       child: Text(
//                         "お会計について、QRコードを精算機にかざしていただき、お支払いくださいますようお願い申し上げます。\nご不明な点がございましたら、恐れ入りますがスタッフまでお声がけくださいませ。",
//                         //maxLines: 4,
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.normal,
//                         ),
//                       ),
//                     ),
//                   ),

//                     Expanded(
//                       flex: 2,
//                       child: Container(
//                             //margin: EdgeInsets.all(20),
//                             // width: 200.w,
//                             // height: 200.h,
//                             child: BarcodeWidget(
//                               height: 200,
//                               width: 200,
//                               barcode: Barcode.qrCode(),
//                               data: printQrCode,
//                           )
//                       ),
//                     ),

//                 ],
//               ),

//           ],
//         ),
//       ),
//     );

//     // Add the receipt widget to the print queue
//     PictureGeneratorProvider.instance.addPicGeneratorTask(
//       PicGenerateTask<PrinterInfo>(
//         tempWidget: receiptWidget as ATempWidget,
//         printTypeEnum: PrintTypeEnum.receipt,
//         params: PrinterInfo(ip: printerIp),
//       ),
//     );
//   }

//   //单票打印时 每个菜品分开打印 分别有receiptTitle 和menuItem 最后右下角没有不需要时间

//   printSingleData(
//       String fromPlate,
//       bool isTakeOut,
//       String orderSnCode,
//       String orderTime,
//       String printerIp,
//       bool isContinuous,
//       bool isRotate,
//       List items,
//       bool printCategory,
//       String remark) async {
//     final rotate = isRotate ? pi : 0.0;
//     for (var item in items) {
//       final qty = item["qty"] ?? 1;
//       final name = item["name"] ?? "";
//       final options = item["options"] ?? {};
//       final categoryName = item["categoryName"] ?? "";

//       // Generate the receipt widget
//       final receiptWidget = ReceiptConstrainedBox(
//         Transform(
//           transform: Matrix4.rotationZ(rotate),
//           alignment: Alignment.center,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               receiptTitle(orderSnCode, orderTime, fromPlate,
//                   isTakeOut: isTakeOut, categoryName: printCategory ? categoryName : ""),
//               menuItem(name, qty, options,
//                   categoryName: printCategory ? categoryName : ""),
//               //remarkTitle(remark)
//               Container(
//                 alignment: Alignment.centerRight,
//                 child: Text(
//                   orderTime,
//                   style: TextStyle(
//                     fontSize: 40,
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ),
//       );

//       // Add the receipt widget to the print queue
//       PictureGeneratorProvider.instance.addPicGeneratorTask(
//         PicGenerateTask<PrinterInfo>(
//           tempWidget: receiptWidget as ATempWidget,
//           printTypeEnum: PrintTypeEnum.receipt,
//           params: PrinterInfo(ip: printerIp),
//         ),
//       );
//     }
//   }

//   Widget remarkTitle(String content) {
//     return Container(
//       child: Text(
//         content,
//         style: TextStyle(
//           fontSize: 32,
//           color: ColorsUtil.hexToColor("#000000"),
//         ),
//       ),
//     );
//   }

//   //标题
//   Widget receiptTitle(String title, String orderTime, String fromPlate,
//       {bool isTakeOut = false, bool continuous = false, bool isCenterPrint = false,
//         String categoryName = ""
//       }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: continuous
//                 ? MainAxisAlignment.center
//                 : MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (isTakeOut && !isCenterPrint)
//                   Icon(
//                     Icons.shopping_bag_outlined,
//                     size: 50,
//                     color: Colors.black,
//                   ),
//                   if (isTakeOut && isCenterPrint)
//                   Text(
//                     fromPlate + ' # ',
//                     style: TextStyle(
//                       fontSize: 50,
//                       color: Colors.black,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 50,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//               if (categoryName.isNotEmpty)
//                 AutoSizeText(
//                   "[$categoryName]",
//                   style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
//                 ),
//             ],
//           ),
//           // if (!continuous)
//           //   Text(
//           //     orderTime,
//           //     style: TextStyle(
//           //       fontSize: 40,
//           //       color: ColorsUtil.hexToColor("#000000"),
//           //     ),
//           //   ),
//           if (!continuous)
//             Divider(
//               color: ColorsUtil.hexToColor("#000000"),
//               thickness: 1,
//             )
//         ],
//       ),
//     );
//   }

//   //单个菜品显示 左标题右分量，如果有Options 换行锁进50 左Option标题 右分量
//   Widget menuItem(String title, int qty, Map option,
//       { bool isUnderLine = false,
//         bool needOption = true,
//         bool isContinuous = false,
//       String? categoryName}) {
//     final optionQtyString = qty == 1 ? "" : "x $qty";
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (categoryName != null && isContinuous)
//             Container(
//               child: Text(
//                 "【$categoryName】",
//                 style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
//               ),
//             ),
//           SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 40,
//                     color: ColorsUtil.hexToColor("#000000"),
//                     //fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Text(
//                 optionQtyString,
//                 style: TextStyle(
//                   fontSize: 40,
//                   color: ColorsUtil.hexToColor("#000000"),
//                   //fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           if (option.isNotEmpty && needOption)
//             ...option.entries.map((entry) {
//               final optionName = entry.key;
//               final optionValues = entry.value;
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "  $optionName",
//                         style: TextStyle(
//                           fontSize: 36,
//                           //fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             ...optionValues.map((option) {
//                               final optionDetail = option["name"] ?? "";
//                               final optionQty = option["qty"] ?? 1;
//                               final optionQtyString =
//                                   optionQty == 1 ? "" : "x $optionQty";
//                               return Text(
//                                       maxLines: 3,
//                                 "    $optionDetail $optionQtyString",
//                                 style: TextStyle(
//                                   fontSize: 36,
//                                 ),
//                               );
//                             }).toList(),
//                           ],
//                         ),
//                       )
//                     ],
//                   ),
//                   SizedBox(height: 20)
//                 ],
//               );
//             }).toList(),
//           if (isUnderLine)
//             Container(
//               margin: EdgeInsets.only(top: 5),
//               height: 1.5,
//               color: ColorsUtil.hexToColor("#000000"),
//               width: double.infinity,
//             ),
//         ],
//       ),
//     );
//   }

// }

// /*return LabelConstrainedBox(
//         Padding(
//           padding: const EdgeInsets.only(
//             //left: 5,
//             top: 5,
//             //right: 5,
//           ),
//           child: Container(

//             child: Column(
//               mainAxisAlignment:MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               textDirection: TextDirection.ltr,
//               children: [

//                 Container(
//                   decoration: BoxDecoration(
//                     //color: Colors.red,
//                     border: Border(
//                       bottom: BorderSide(color: ColorsUtil.hexToColor("#000000"), width: 2.5),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment:MainAxisAlignment.start,
//                     textDirection: TextDirection.ltr,
//                     children: [
//                       Directionality(
//                           textDirection: TextDirection.ltr,
//                           child: Expanded(child: ConstrainedBox(
//                             constraints: BoxConstraints(
//                               minWidth: ScreenAdapter.width(20),
//                               maxWidth: ScreenAdapter.width(400),
//                               minHeight: ScreenAdapter.height(30),
//                               maxHeight: ScreenAdapter.height(70),
//                             ),
//                             child: AutoSizeText(
//                               "${orderprintData["printTitleText"]}",
//                               style: GoogleFonts.zenKakuGothicAntique(fontSize: ScreenAdapter.fontSize(32),fontWeight: FontWeight.w500),
//                               maxLines: 2,
//                               textAlign: TextAlign.left,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           )
//                           )
//                       ),
//                     ],
//                   ),
//                 ),

//                 Row(
//                   mainAxisAlignment:MainAxisAlignment.start,
//                   textDirection: TextDirection.ltr,
//                   children: [
//                     Directionality(
//                         textDirection: TextDirection.ltr,
//                         child: Expanded(child: ConstrainedBox(
//                           constraints: BoxConstraints(
//                             minWidth: ScreenAdapter.width(20),
//                             maxWidth: ScreenAdapter.width(400),
//                             minHeight: ScreenAdapter.height(30),
//                             maxHeight: ScreenAdapter.height(210),
//                           ),
//                           child: AutoSizeText(
//                             orderprintData["printText"],
//                             style: GoogleFonts.zenKakuGothicAntique(fontSize: ScreenAdapter.fontSize(26),fontWeight: FontWeight.w500),
//                             maxLines: 4,
//                             textAlign: TextAlign.left,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         )
//                         )
//                     ),
//                   ],
//                 ),

//               ],
//             ),
//           ),
//         )
//     );*/
// //}