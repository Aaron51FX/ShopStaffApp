import 'cash_changer_define.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cash_changer_platform_interface.dart';

/// An implementation of [CashChangerPlatform] that uses method channels.
class MethodChannelCashChanger extends CashChangerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cash_changer');

  @override
  Future<void> setEvenstListener(
      Future<void> Function(MethodCall) events) async {
        debugPrint('---setEvenstListener---');
    methodChannel.setMethodCallHandler(events);
  }

  @override
  Future<void> removeEvenstListener() async {
    debugPrint('---removeEvenstListener---');
    try {
      methodChannel.setMethodCallHandler(null);
    } catch (e) {
      debugPrint('停止监听失败: $e');
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Map?> openCashChanger() async {
    final result = await methodChannel.invokeMethod<Map>('openCashChanger');
    return result;
  }

  @override
  Future<Map?> closeCashChanger() async {
    final result = await methodChannel.invokeMethod<Map>('closeCashChanger');
    return result;
  }

  @override
  Future<Map?> getCashBalance() async {
    final result = await methodChannel.invokeMethod<Map>('getCashBalance');
    return result;
  }

  @override
  Future<Map?> startDeposit() async {
    final result = await methodChannel.invokeMethod<Map>('startDeposit');
    return result;
  }

  @override
  Future<Map?> depositAmount() async {
    final result = await methodChannel.invokeMethod<Map>('depositAmount');
    return result;
  }

  @override
  Future<Map?> fixDeposit() async {
    final result = await methodChannel.invokeMethod<Map>('fixDeposit');
    return result;
  }

  @override
  Future<Map?> endDeposit(int status) async {
    final result =
        await methodChannel.invokeMethod<Map>('endDeposit', <String, dynamic>{
      'end_deposit': status,
    });
    return result;
  }

  @override
  Future<Map?> dispenseChange(int change) async {
    final result = await methodChannel
        .invokeMethod<Map>('dispenseChange', <String, dynamic>{
      'dispense': change,
    });




    return result;
  }

  @override
  Future<Map?> depositRepay() async {
    final result = await methodChannel.invokeMethod<Map>('depositRepay');
    return result;
  }

  @override
  Future<Map?> checkChangerStatus() async {
    final result = await methodChannel.invokeMethod<Map>('checkChangerStatus');
    return result;
  }

  @override
  Future<Map?> changerDIStatus(int pData) async {
    final result = await methodChannel
        .invokeMethod<Map>('changer_di_status', <String, dynamic>{
      'pData': pData,
    });
    return result;
  }

  @override
  Future<Map?> startSupply() async {
    final result = await methodChannel.invokeMethod<Map>('startSupply');
    return result;
  }

  @override
  Future<Map?> supplyCounts(int mode) async {
    final result = await methodChannel
        .invokeMethod<Map>('supplyCounts', <String, dynamic>{
      'pData': mode,
    });
    return result;
  }

  @override
  Future<Map?> countClear() async {
    final result = await methodChannel.invokeMethod<Map>('countClear');
    return result;
  }

  //dispenseCashOutside
  Future<Map?> dispenseCashOutside(String cashInfo) async {
    final result = await methodChannel.invokeMethod<Map>('dispenseCashOutside',
        <String, dynamic>{'cashInfo': cashInfo});
    return result;
  }

  //dispenseChangeOutside
  Future<Map?> dispenseChangeOutside(int count) async {
    final result = await methodChannel.invokeMethod<Map>('dispenseChangeOutside',
        <String, dynamic>{'count': count});
    return result;
  }


  //beginCashReturn
  Future<Map?> beginCashReturn() async {
    final result = await methodChannel.invokeMethod<Map>('beginCashReturn');
    return result;
  }

  //BEGINDEPOSITOUTSIDE
  Future<Map?> beginDepositOutside() async {
    final result = await methodChannel.invokeMethod<Map>('beginDepositOutside');
    return result;
  }


  @override
  Future<Map?> dispenseCash(String cashCounts) async {
    debugPrint('---dispenseCash--- $cashCounts');
    final result =
        await methodChannel.invokeMethod<Map>('dispenseCash', <String, dynamic>{
      'cashCounts': cashCounts,
    });
    return result;
  }

  @override
  Future<Map?> collectAll({int bill = 1, int coin = 1}) async {
    final result = await methodChannel.invokeMethod<Map>('collectAll',
        <String, dynamic>{'Bill': bill, 'Coin': coin});
    return result;
  }
}
