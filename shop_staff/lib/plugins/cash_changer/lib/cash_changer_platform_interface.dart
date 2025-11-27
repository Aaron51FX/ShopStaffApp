import 'cash_changer_define.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cash_changer_method_channel.dart';


abstract class CashChangerPlatform extends PlatformInterface {
  /// Constructs a CashChangerPlatform.
  CashChangerPlatform() : super(token: _token);

  static final Object _token = Object();

  static CashChangerPlatform _instance = MethodChannelCashChanger();

  /// The default instance of [CashChangerPlatform] to use.
  ///
  /// Defaults to [MethodChannelCashChanger].
  static CashChangerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CashChangerPlatform] when
  /// they register themselves.
  static set instance(CashChangerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  //Open cash change
  Future<Map?> openCashChanger() {
    throw UnimplementedError('openCashChanger() has not been implemented.');
  }

  //Close cash change
  Future<Map?> closeCashChanger() {
    throw UnimplementedError('closeCashChanger() has not been implemented.');
  }

  //Get Cash Balance Info
  Future<Map?> getCashBalance() {
    throw UnimplementedError('getCashBalance() has not been implemented.');
  }

  Future<Map?> startDeposit() {
    throw UnimplementedError('startDeposit() has not been implemented.');
  }

  //Deposit Amount
  Future<Map?> depositAmount() {
    throw UnimplementedError('depositAmount() has not been implemented.');
  }

  //fixDeposit
  Future<Map?> fixDeposit() {
    throw UnimplementedError('fixDeposit() has not been implemented.');
  }

  //End Deposit
  Future<Map?> endDeposit(int status) {
    throw UnimplementedError('stopDeposit() has not been implemented.');
  }

  //Dispense Change
  Future<Map?> dispenseChange(int change) {
    throw UnimplementedError('dispenseChange() has not been implemented.');
  }
  
  //Deposit Repay
  Future<Map?> depositRepay() {
    throw UnimplementedError('depositRepay() has not been implemented.');
  }

  //Check Changer Status
  Future<Map?> checkChangerStatus() {
    throw UnimplementedError('checkChangerStatus() has not been implemented.');
  }

  //startSupply
  Future<Map?> startSupply() {
    throw UnimplementedError('startSupply() has not been implemented.');
  }

  //supplyCounts
  Future<Map?> supplyCounts(int mode) {
    throw UnimplementedError('supplyCounts() has not been implemented.');
  }

  //COUNTCLR
  Future<Map?> countClear() {
    throw UnimplementedError('countClear() has not been implemented.');
  }

  //dispenseCashOutside
  Future<Map?> dispenseCashOutside(String cashInfo) {
    throw UnimplementedError('dispenseCashOutside() has not been implemented.');
  }

  //dispenseChangeOutside
  Future<Map?> dispenseChangeOutside(int count) {
    throw UnimplementedError('dispenseCashOutside() has not been implemented.');
  }

  //beginCashReturn
  Future<Map?> beginCashReturn() {
    throw UnimplementedError('beginCashReturn() has not been implemented.');
  }

  //BEGINDEPOSITOUTSIDE
  Future<Map?> beginDepositOutside() {
    throw UnimplementedError('beginDepositOutside() has not been implemented.');
  }
  
  //Set Event Listener
  Future<void> setEvenstListener(Future<void> Function(MethodCall) events) {
    throw UnimplementedError('setEvenstListener() has not been implemented.');
  }

  //Remove Event Listener
  Future<void> removeEvenstListener() {
    throw UnimplementedError('removeEvenstListener() has not been implemented.');
  }

  //Changer DI Status
  Future<Map?> changerDIStatus(int pData) {
    throw UnimplementedError('changerDIStatus() has not been implemented.');
  }

  //Dispense Cash
  Future<Map?> dispenseCash(String cashCounts) {
    throw UnimplementedError('dispenseCash() has not been implemented.');
  }

  //collectAll
  Future<Map?> collectAll({int bill = 1, int coin = 1}) {
    throw UnimplementedError('collectAll() has not been implemented.');
  }

}
