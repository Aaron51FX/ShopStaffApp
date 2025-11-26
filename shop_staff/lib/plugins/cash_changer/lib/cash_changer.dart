import 'cash_changer_define.dart';
import 'package:cash_changer/cash_changer_platform_interface.dart';
import 'package:flutter/foundation.dart';

class CashChanger {
  static int? putMoney = 0;
  static String putCurrency = "";
  static String currencyString = ""; //币种

  //监听几种状态
  static String payCubeStopCashStatus = "Error";
  static String payCubeOutMoneyStatus = "Error";
  static String payCubeEndTradeStatus = "Error";

  static Function(int)? onGetPutMoneyStringChange;
  static Function(String)? onStatusUpdateEventChange;
  static Function(OpenChangerResult)? onOpenResultReponse;

  //set event listener
  static Future<void> setEventsListener() async {
    CashChangerPlatform.instance.setEvenstListener((call) async {
      debugPrint('Cash Changer Event: ${call.method} ${call.arguments}');
      switch (call.method) {
        case 'DirectIOEvent':
          break;
        case 'DataEvent':
          putMoney = call.arguments;
          onGetPutMoneyStringChange?.call(putMoney ?? 0);
          break;
        case 'StatusUpdateEvent':
          onStatusUpdateEventChange?.call(getStatusEventMessage(call.arguments));
          break;
        default:
          debugPrint('No method found');
      }
    });
  }

  static String getStatusEventMessage(int value) {
    final result =
        cashStatusEventValuse[value] ?? StatusUpdateEvent.ChanStatusOk;
    switch (result) {
      case StatusUpdateEvent.ChanStatusOk:
        return 'OK';
      case StatusUpdateEvent.OPOS_SUE_POWER_ONLINE:
        return '電源オンでかつレディ状態です';
      case StatusUpdateEvent.OPOS_SUE_POWER_OFF:
        return '電源オフまたは本体に接続されていません';
      case StatusUpdateEvent.OPOS_SUE_POWER_OFFLINE:
        return '電源オンですがノットレディ状態です';
      case StatusUpdateEvent.CHAN_STATUS_JAM:
        return '機器障害が生じました';
      case StatusUpdateEvent.CHAN_STATUS_JAMOK:
        return '機器障害が解消しました';
      case StatusUpdateEvent.CHAN_STATUS_EMPTY:
        return 'エンプティの金種があります';
      case StatusUpdateEvent.CHAN_STATUS_NEAREMPTY:
        return 'ニアエンプティの金種があります';
      case StatusUpdateEvent.CHAN_STATUS_EMPTYOK:
        return 'OK';//'エンプティ，ニアエンプティの状態が解除されました';
      case StatusUpdateEvent.CHAN_STATUS_FULL:
        return 'FULL';
      case StatusUpdateEvent.CHAN_STATUS_NEARFULL:
        return 'NEARFULL';
      case StatusUpdateEvent.CHAN_STATUS_FULLOK:
        return 'OK';//'フル，ニアフルの状態が解除されました';
      case StatusUpdateEvent.CHAN_STATUS_ASYNC:
        return '非同期動作が終了しました';
    }
  }

  //remove event listener
  static Future<void> removeEventsListener() async {
    CashChangerPlatform.instance.removeEvenstListener();
  }

  static Future<String?> get getPlatformVersion async {
    return CashChangerPlatform.instance.getPlatformVersion();
  }

  //Open cash changer
  static Future<bool> openCashChanger(
      {required Function onSuccess,
      required Function(int, String) catchError}) async {
    Map? result = await CashChangerPlatform.instance.openCashChanger();
    var ret = false;
    await openChangerNext(
        openResult: result?['code'],
        onSuccess: () async {
          ret = true;
          onSuccess();
        },
        onRetry: () async {
          await Future.delayed(Duration(milliseconds: 200));
          openCashChanger;
        },
        showError: (error) async {
          ret = false;
          catchError(result?['code'], error);
        });
    return ret;
  }

  //Close cash changer
  static Future<int?> get closeCashChanger async {
    return CashChangerPlatform.instance.closeCashChanger();
  }

  //Get Cash Balance Info
  static Future<bool> getCashBalance(
      {required Function(String) onSuccess,
      required Function(String) catchError}) async {
    Map? result = await CashChangerPlatform.instance.getCashBalance();
    var ret = false;
    if (result == null) {
      return ret;
    }
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          ret = true;
          onSuccess(result['value'] ?? "");
        },
        onRetry: () async {
          await Future.delayed(Duration(milliseconds: 200));
          getCashBalance;
        },
        showError: (error) async {
          ret = false;
          catchError(error);
        });
    return ret;
  }

  static Future<bool> startDeposit(
      {required Function onSuccess,
      required Function(String) catchError}) async {
    var ret = false;
    final resultMap = await CashChangerPlatform.instance.startDeposit();
    await changerResultNext(
        resultCode: resultMap?['code'],
        onSuccess: () {
          onSuccess();
          ret = true;
        },
        onRetry: () async {
          await Future.delayed(Duration(milliseconds: 200));
          startDeposit(onSuccess: onSuccess, catchError: catchError);
        },
        showError: (error) async {
          catchError(error);
          ret = false;
        });
    return ret;
  }

  //Deposit Amount
  static Future<int?> get depositAmount async {
    return CashChangerPlatform.instance.depositAmount();
  }

  static Future<int?> get fixDeposit async {
    return CashChangerPlatform.instance.fixDeposit();
  }

  //end Deposit
  static Future<int?> endDeposit(int status) async {
    return CashChangerPlatform.instance.endDeposit(status);
  }

  //Dispense Change
  static Future<Map?> dispenseChange(int change) async {
    return CashChangerPlatform.instance.dispenseChange(change);
  }

  //Deposit Repay
  static Future<int?> get depositRepay async {
    return CashChangerPlatform.instance.depositRepay();
  }

  //Check Changer Status
  static Future<int?> get checkChangerStatus async {
    return CashChangerPlatform.instance.checkChangerStatus();
  }

  //supply cash
  static Future<int?> get startSupply async {
    return CashChangerPlatform.instance.startSupply();
  }

  //SUPPLYCOUNTS
  static Future<bool> supplyCounts(int mode,
      {required Function(String) onSuccess,
      required Function(String) catchError}) async {
    Map? result = await CashChangerPlatform.instance.supplyCounts(mode);
    var ret = false;
    await changerResultNext(
        resultCode: result?['code'],
        onSuccess: () {
          ret = true;
          onSuccess(result?['value'] ?? "");
        },
        onRetry: () async {
          await Future.delayed(Duration(milliseconds: 200));
          supplyCounts(mode, onSuccess: onSuccess, catchError: catchError);
        },
        showError: (error) async {
          ret = false;
          catchError(error);
        });
    return ret;
  }

  //COUNTCLR
  static Future<int?> countClear() async {
    return CashChangerPlatform.instance.countClear();
  }

  //dispenseCashOutside
  static Future<int?> dispenseCashOutside(String cashInfo) async {
    return CashChangerPlatform.instance.dispenseCashOutside(cashInfo);
  }

  //dispenseChangeOutside
  static Future<bool> dispenseChangeOutside(int count,
      {required Function() onSuccess,
      required Function(String) catchError}) async {
    int? result =
        await CashChangerPlatform.instance.dispenseChangeOutside(count);
    var ret = false;
    await changerResultNext(
        resultCode: result ?? -1,
        onSuccess: () {
          ret = true;
          onSuccess();
        },
        onRetry: () async {
          await Future.delayed(Duration(milliseconds: 200));
          dispenseChangeOutside(count,
              onSuccess: onSuccess, catchError: catchError);
        },
        showError: (error) async {
          ret = false;
          catchError(error);
        });
    return ret;
  }

  //beginCashReturn
  static Future<int?> get beginCashReturn async {
    return CashChangerPlatform.instance.beginCashReturn();
  }

  //BEGINDEPOSITOUTSIDE
  static Future<int?> get beginDepositOutside async {
    return CashChangerPlatform.instance.beginDepositOutside();
  }

  //changer di status
  static Future<String?> changerDIStatus(int pData) async {
    return CashChangerPlatform.instance.changerDIStatus(pData);
  }

  //dispense cash
  static Future<bool> dispenseCash(String cashCounts,
      {required Function onSuccess,
      required Function(String) catchError}) async {
    Map? result = await CashChangerPlatform.instance.dispenseCash(cashCounts);
    var ret = false;
    await changerResultNext(
        resultCode: result?['code'],
        onSuccess: () {
          ret = true;
          onSuccess();
        },
        onRetry: () async {
          await Future.delayed(Duration(milliseconds: 200));
          dispenseCash(cashCounts,
              onSuccess: onSuccess, catchError: catchError);
        },
        showError: (error) async {
          ret = false;
          catchError(error);
        });
    return ret;
  }

  //collectAll
  static Future<int?> collectAll({int bill = 1, int coin = 1}) async {
    return CashChangerPlatform.instance.collectAll(bill: bill, coin: coin);
  }

  static getOposResult(int? result) {
    debugPrint("getOposResult: $result");
    if (result == null) {
      return OposResult(
          resultCode: HealthResultCode.NONE,
          resultCodeExtended: ResultCodeExtended.NONE);
    }
    if (result > 200) {
      HealthResultCode resultCode = HealthResultCode.OPOS_E_EXTENDED;
      ResultCodeExtended? resultExtended =
          ResultCodeExtended.values.fromIndex(result - 200);
      return OposResult(
          resultCode: resultCode,
          resultCodeExtended: resultExtended ?? ResultCodeExtended.NONE);
    } else {
      HealthResultCode? resultCode = HealthResultCode.values
          .fromIndex(result > 100 ? result - 100 : result);
      return OposResult(
          resultCode: resultCode ?? HealthResultCode.NONE,
          resultCodeExtended: ResultCodeExtended.NONE);
    }
  }

  static Future changerResultNext(
      {required int? resultCode,
      required Function onSuccess,
      required Function onRetry,
      required Function(String) showError}) async {
    OposResult result = getOposResult(resultCode);
    debugPrint("changerResultNext: ${result.resultCode}");
    switch (result.resultCode) {
      case HealthResultCode.OPOS_SUCCESS:
        onSuccess();
        break;
      case HealthResultCode.OPOS_E_CLOSED:
        showError("cash_error_closed");
        break;
      case HealthResultCode.OPOS_E_CLAIMED:
        showError("cash_error_claimed");
        break;
      case HealthResultCode.OPOS_E_NOTCLAIMED:
        showError("cash_error_no_claimed");
        break;
      case HealthResultCode.OPOS_E_DISABLED:
        showError("cash_error_disabled");
        break;
      case HealthResultCode.OPOS_E_ILLEGAL:
        showError("cash_error_illegal");
        break;
      case HealthResultCode.OPOS_E_NOSERVICE:
        showError("cash_error_no_service");
        break;
      case HealthResultCode.OPOS_E_BUSY:
        showError("cash_error_busy");
        break;
      case HealthResultCode.OPOS_E_NOHARDWARE:
        showError("cash_error_no_hardware");
        break;
      case HealthResultCode.OPOS_E_EXTENDED:
        changerResultExtendedNext(
            resultCodeExtended: result.resultCodeExtended,
            onSuccess: onSuccess,
            onRetry: onRetry,
            showError: showError);
        break;
      default:
        showError("cash_error_common");
        break;
    }
  }

  static Future changerResultExtendedNext(
      {required ResultCodeExtended resultCodeExtended,
      required Function onSuccess,
      required Function onRetry,
      required Function(String) showError}) async {
    debugPrint("changerResultExtendedNext: $resultCodeExtended");
    switch (resultCodeExtended) {
      case ResultCodeExtended.OPOS_ECHAN_OVERDISPENSE:
      case ResultCodeExtended.OPOS_ECHAN_TOTALOVER:
        showError("cash_error_over_dispense");
        break;
      case ResultCodeExtended.OPOS_ECHAN_OVER:
        showError("cash_error_over");
        break;
      case ResultCodeExtended.OPOS_ECHAN_IFERROR: //通信异常 重试

        final result = await endDeposit(DepositAction.repay.index);
        if (result == 0) {
          onRetry();
        } else {
          showError("cash_error_if_error");
        }
        //onRetry();
        //showError("cash_error_if_error");
        break;
      case ResultCodeExtended.OPOS_ECHAN_SETERROR:
        showError("cash_error_set_error");
        break;
      case ResultCodeExtended.OPOS_ECHAN_CHARGING:
        showError("cash_error_charging");
        break;
      case ResultCodeExtended.OPOS_ECHAN_FULL:
        showError("cash_error_full");
        break;
      case ResultCodeExtended.OPOS_ECHAN_BUSY:
        showError("cash_error_busy");
        break;
      case ResultCodeExtended.OPOS_ECHAN_CASSETTEWAIT:
        showError("cash_error_cassette_wait");
        break;
      case ResultCodeExtended.OPOS_ECHAN_IMPOSSIBLE:
        showError("cash_error_impossible");
        break;
      case ResultCodeExtended.OPOS_ECHAN_DEPOSIT:
        showError("cash_error_deposit");
        break;
      case ResultCodeExtended.OPOS_ECHAN_PAUSEDEPOSIT:
        showError("cash_error_pause_deposit");
        break;
      default:
        showError("cash_error_common");
        break;
    }
  }

  static Map<int, OpenChangerResult> openChangerResultValues = {
    0: OpenChangerResult.OPEN_SUCCESS,
    300: OpenChangerResult.OPOS_OPEN_ERR,
    301: OpenChangerResult.OPOS_OR_ALREADYOPEN,
    302: OpenChangerResult.OPOS_OR_REGBADNAME,
    303: OpenChangerResult.OPOS_OR_REGPROGID,
    304: OpenChangerResult.OPOS_OR_CREATE,
    305: OpenChangerResult.OPOS_OR_BADIF,
    306: OpenChangerResult.OPOS_ORS_FAILEDOPEN,
    307: OpenChangerResult.OPOS_ORS_BADVERSION,
    400: OpenChangerResult.OPOS_OPEN_ERR_SO,
    401: OpenChangerResult.OPOS_ORS_NOPORT,
    402: OpenChangerResult.OPOS_ORS_NOPORTED,
    403: OpenChangerResult.OPOS_ORS_CONFIG,
    450: OpenChangerResult.OPOS_SPECIFIC,
  };

  static Map<int, StatusUpdateEvent> cashStatusEventValuse = {
    2001: StatusUpdateEvent.OPOS_SUE_POWER_ONLINE,
    2002: StatusUpdateEvent.OPOS_SUE_POWER_OFF,
    2003: StatusUpdateEvent.OPOS_SUE_POWER_OFFLINE,
    31: StatusUpdateEvent.CHAN_STATUS_JAM,
    32: StatusUpdateEvent.CHAN_STATUS_JAMOK,
    11: StatusUpdateEvent.CHAN_STATUS_EMPTY,
    12: StatusUpdateEvent.CHAN_STATUS_NEAREMPTY,
    13: StatusUpdateEvent.CHAN_STATUS_EMPTYOK,
    21: StatusUpdateEvent.CHAN_STATUS_FULL,
    22: StatusUpdateEvent.CHAN_STATUS_NEARFULL,
    23: StatusUpdateEvent.CHAN_STATUS_FULLOK,
    91: StatusUpdateEvent.CHAN_STATUS_ASYNC,
    0: StatusUpdateEvent.ChanStatusOk,
  };

  static Future openChangerNext(
      {required int? openResult,
      required Function onSuccess,
      Function? onRetry,
      required Function(String) showError}) async {
    if (openResult == null) {
      showError("cash_error_common");
      return;
    }

    if (openChangerResultValues[openResult] == null && openResult > 200) {
      changerResultExtendedNext(
          resultCodeExtended:
              ResultCodeExtended.values.fromIndex(openResult - 200) ??
                  ResultCodeExtended.NONE,
          onSuccess: onSuccess,
          onRetry: onRetry ?? () {},
          showError: showError);
      return;
    }

    OpenChangerResult result =
        openChangerResultValues[openResult] ?? OpenChangerResult.NONE;
    switch (result) {
      case OpenChangerResult.OPEN_SUCCESS:
      case OpenChangerResult.OPOS_OR_ALREADYOPEN:
        onSuccess();
        break;
      case OpenChangerResult.OPOS_OPEN_ERR:
        showError("cash_error_open");
        //showError("打开失败 请重试");
        break;
      case OpenChangerResult.OPOS_OR_REGBADNAME:
        showError("cash_error_reg_bad_name");
        //showError("打开名称不正确 提醒处理 打开设置工具");
        break;
      case OpenChangerResult.OPOS_OR_REGPROGID:
        showError("cash_error_reg_prog_id");
        //showError("打开名称不正确 提醒处理 打开设置工具");
        break;
      case OpenChangerResult.OPOS_OR_CREATE:
        showError("cash_error_create");
        //showError("初始化SO有问题 提醒处理 重新初始化");
        break;
      case OpenChangerResult.OPOS_OR_BADIF:
        showError("cash_error_bad_if");
        //showError("SO库无法使用 提醒处理 重新初始化");
        break;
      case OpenChangerResult.OPOS_ORS_NOPORT:
        showError("cash_error_no_port");
        //showError("端口设置有问题 提醒处理 打开设置工具");
        break;
      case OpenChangerResult.OPOS_ORS_SENSETHREAD:
        showError("cash_error_sense_thread");
        //showError("线程有问题 暂无法处理 上报记录");
        break;
      case OpenChangerResult.OPOS_ORS_CONFIG:
        showError("cash_error_config");
        //showError("配置文件有问题 提醒处理 重新初始化");
        break;
      case OpenChangerResult.OPOS_ORS_EVENTTHRREAD:
        showError("cash_error_event_thread");
        //showError("事件处理有问题 暂无法处理 上报记录");
        break;
      case OpenChangerResult.OPOS_ORS_FAILEDOPEN:
        showError("cash_error_failed_open");
        //showError("SO库无法使用 提醒处理 重新初始化");
        break;
      case OpenChangerResult.OPOS_ORS_EVENTCLASS:
        showError("cash_error_event_class");
        //showError("事件处理程序有问题 暂无法处理 上报记录");
        break;
      case OpenChangerResult.OPOS_ORS_BADVERSION:
        showError("cash_error_bad_version");
        //showError("打开名称不正确 提醒处理 打开设置工具");
        break;
      case OpenChangerResult.OPOS_OPEN_ERR_SO:
        showError("cash_error_open_so");
        //showError("SO库无法使用 提醒处理 重新初始化");
        break;
      case OpenChangerResult.OPOS_ORS_NOPORTED:
        showError("cash_error_no_ported");
        //showError("端口设置有问题 提醒处理 打开设置工具");
        break;
      case OpenChangerResult.OPOS_SPECIFIC:
        showError("cash_error_specific");
        //showError("打开名称不正确 提醒处理 打开设置工具");
        break;
      default:
        showError("cash_error_unknown");
        //showError("UNKNOWN ERROR $openResult");
        break;
    }
  }
}
