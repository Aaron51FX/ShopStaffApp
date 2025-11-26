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
  Future<int?> closeCashChanger() async {
    final result = await methodChannel.invokeMethod<int>('closeCashChanger');
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
  Future<int?> depositAmount() async {
    final result = await methodChannel.invokeMethod<int>('depositAmount');
    return result;
  }

  @override
  Future<int?> fixDeposit() async {
    final result = await methodChannel.invokeMethod<int>('fixDeposit');
    return result;
  }

  @override
  Future<int?> endDeposit(int status) async {
    final result =
        await methodChannel.invokeMethod<int>('endDeposit', <String, dynamic>{
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
  Future<int?> depositRepay() async {
    final result = await methodChannel.invokeMethod<int>('depositRepay');
    return result;
  }

  @override
  Future<int?> checkChangerStatus() async {
    final result = await methodChannel.invokeMethod<int>('checkChangerStatus');
    return result;
  }

  @override
  Future<String?> changerDIStatus(int pData) async {
    final result = await methodChannel
        .invokeMethod<String>('changer_di_status', <String, dynamic>{
      'pData': pData,
    });
    return result;
  }

  @override
  Future<int?> startSupply() async {
    final result = await methodChannel.invokeMethod<int>('startSupply');
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
  Future<int?> countClear() async {
    final result = await methodChannel.invokeMethod<int>('countClear');
    return result;
  }

  //dispenseCashOutside
  Future<int?> dispenseCashOutside(String cashInfo) async {
    final result = await methodChannel.invokeMethod<int>('dispenseCashOutside',
        <String, dynamic>{'cashInfo': cashInfo});
    return result;
  }

  //dispenseChangeOutside
  Future<int?> dispenseChangeOutside(int count) async {
    final result = await methodChannel.invokeMethod<int>('dispenseChangeOutside',
        <String, dynamic>{'count': count});
    return result;
  }


  //beginCashReturn
  Future<int?> beginCashReturn() async {
    final result = await methodChannel.invokeMethod<int>('beginCashReturn');
    return result;
  }

  //BEGINDEPOSITOUTSIDE
  Future<int?> beginDepositOutside() async {
    final result = await methodChannel.invokeMethod<int>('beginDepositOutside');
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
  Future<int?> collectAll({int bill = 1, int coin = 1}) async {
    final result = await methodChannel.invokeMethod<int>('collectAll',
        <String, dynamic>{'Bill': bill, 'Coin': coin});
    return result;
  }
}
