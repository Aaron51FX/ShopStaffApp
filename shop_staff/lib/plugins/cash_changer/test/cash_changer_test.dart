import 'package:flutter/src/services/message_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_changer/cash_changer.dart';
import 'package:cash_changer/cash_changer_platform_interface.dart';
import 'package:cash_changer/cash_changer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCashChangerPlatform
    with MockPlatformInterfaceMixin
    implements CashChangerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  
  @override
  Future<int?> checkChangerStatus() {
    // TODO: implement checkChangerStatus
    throw UnimplementedError();
  }
  
  @override
  Future<int?> closeCashChanger() {
    // TODO: implement closeCashChanger
    throw UnimplementedError();
  }
  
  @override
  Future<int?> depositAmount() {
    // TODO: implement depositAmount
    throw UnimplementedError();
  }
  
  @override
  Future<int?> depositRepay() {
    // TODO: implement depositRepay
    throw UnimplementedError();
  }
  
  @override
  Future<int?> dispenseChange(int change) {
    // TODO: implement dispenseChange
    throw UnimplementedError();
  }
  
  @override
  Future<int?> endDeposit(int status) {
    // TODO: implement endDeposit
    throw UnimplementedError();
  }
  
  @override
  Future<String?> getCashBalance() {
    // TODO: implement getCashBalance
    throw UnimplementedError();
  }
  
  @override
  Future<int?> openCashChanger() {
    // TODO: implement openCashChanger
    throw UnimplementedError();
  }
  
  @override
  Future<int?> startDeposit() {
    // TODO: implement startDeposit
    throw UnimplementedError();
  }

  @override
  Future<String?> changerDIStatus(int pData) {
    // TODO: implement changerDIStatus
    throw UnimplementedError();
  }

  @override
  Future<int?> dispenseCash(String cashCounts) {
    // TODO: implement dispenseCash
    throw UnimplementedError();
  }

  @override
  Future<void> removeEvenstListener() {
    // TODO: implement removeEvenstListener
    throw UnimplementedError();
  }

  @override
  Future<void> setEvenstListener(Future<void> Function(MethodCall p1) events) {
    // TODO: implement setEvenstListener
    throw UnimplementedError();
  }
}

void main() {
  final CashChangerPlatform initialPlatform = CashChangerPlatform.instance;

  test('$MethodChannelCashChanger is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCashChanger>());
  });

  test('getPlatformVersion', () async {
    CashChanger cashChangerPlugin = CashChanger();
    MockCashChangerPlatform fakePlatform = MockCashChangerPlatform();
    CashChangerPlatform.instance = fakePlatform;

    //expect(await cashChangerPlugin.getPlatformVersion(), '42');
  });
}
