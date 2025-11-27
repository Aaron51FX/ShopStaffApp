import 'cash_changer_define.dart';
import 'package:cash_changer/cash_changer_platform_interface.dart';
import 'package:flutter/foundation.dart';

class CashOperationResult<T> {
  final T? data;
  final CashOperationError? error;

  const CashOperationResult._({this.data, this.error});

  bool get isSuccess => error == null;

  factory CashOperationResult.success([T? data]) =>
      CashOperationResult._(data: data);

  factory CashOperationResult.failure({
    required int code,
    String? message,
    bool retriable = false,
  }) =>
      CashOperationResult._(
        error: CashOperationError(code: code, message: message, retriable: retriable),
      );
}

class CashOperationError {
  final int code;
  final String? message;
  final bool retriable;

  const CashOperationError({required this.code, this.message, this.retriable = false});
}

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
  
      // {required Function onSuccess,
      // required Function(int, String) catchError}
  //Open cash changer
  static Future<CashOperationResult<bool>> openCashChanger() async {
    Map? result = await CashChangerPlatform.instance.openCashChanger();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<bool>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success(true);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //Close cash changer
  static Future<CashOperationResult<void>> get closeCashChanger async {
    Map? result = await CashChangerPlatform.instance.closeCashChanger();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () => response = CashOperationResult.success(),
        showError: (error) => response = CashOperationResult.failure(code: result['code'] ?? -1, message: error),
    );
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //Get Cash Balance Info
  static Future<CashOperationResult<String>> getCashBalance() async {
    Map? result = await CashChangerPlatform.instance.getCashBalance();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<String>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          String value = result['value'] ?? "";
          response = CashOperationResult.success(value);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  static Future<CashOperationResult<bool>> startDeposit() async {
    
    final resultMap = await CashChangerPlatform.instance.startDeposit();
    if (resultMap == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<bool>? response;
    await changerResultNext(
        resultCode: resultMap['code'],
        onSuccess: () {
          response = CashOperationResult.success(true);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: resultMap['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //Deposit Amount
  static Future<CashOperationResult<int>> get depositAmount async {
     final resultMap = await CashChangerPlatform.instance.depositAmount();
      if (resultMap == null) {
        return CashOperationResult.failure(code: -1, message: 'cash_error_common');
      }
      CashOperationResult<int>? response;
      await changerResultNext(
          resultCode: resultMap['code'],
          onSuccess: () {
            int value = resultMap['value'] ?? 0;
            response = CashOperationResult.success(value);
          },
          showError: (error) {
            response = CashOperationResult.failure(code: resultMap['code'] ?? -1, message: error);
          });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  static Future<CashOperationResult<int>> get fixDeposit async {
    final resultMap = await CashChangerPlatform.instance.fixDeposit();
    if (resultMap == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<int>? response;
    await changerResultNext(
        resultCode: resultMap['code'],
        onSuccess: () {
          int value = resultMap['value'] ?? 0;
          response = CashOperationResult.success(value);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: resultMap['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //end Deposit
  static Future<CashOperationResult<void>> endDeposit(int status) async {
    final result = await CashChangerPlatform.instance.endDeposit(status);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //Dispense Change
  static Future<CashOperationResult<void>> dispenseChange(int change) async {
    final result = await CashChangerPlatform.instance.dispenseChange(change);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //Deposit Repay
  static Future<CashOperationResult<void>> get depositRepay async {
    final result = await CashChangerPlatform.instance.depositRepay();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //Check Changer Status
  static Future<CashOperationResult<int>> get checkChangerStatus async {
    final result = await CashChangerPlatform.instance.checkChangerStatus();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<int>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          int value = result['value'] ?? 0;
          response = CashOperationResult.success(value);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //supply cash
  static Future<CashOperationResult<void>> get startSupply async {
    final result = await CashChangerPlatform.instance.startSupply();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //SUPPLYCOUNTS
  static Future<CashOperationResult<String>> supplyCounts(int mode) async {
    final result = await CashChangerPlatform.instance.supplyCounts(mode);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<String>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          String value = result['value'] ?? "";
          response = CashOperationResult.success(value);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });

    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //COUNTCLR
  static Future<CashOperationResult<void>> countClear() async {
    final result = await CashChangerPlatform.instance.countClear();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //dispenseCashOutside
  static Future<CashOperationResult<void>> dispenseCashOutside(String cashInfo) async {
    final result = await CashChangerPlatform.instance.dispenseCashOutside(cashInfo);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //dispenseChangeOutside
  static Future<CashOperationResult<void>> dispenseChangeOutside(int count) async {
    Map? result  =
        await CashChangerPlatform.instance.dispenseChangeOutside(count);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //beginCashReturn
  static Future<CashOperationResult<void>> get beginCashReturn async {
    final result = await CashChangerPlatform.instance.beginCashReturn();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //BEGINDEPOSITOUTSIDE
  static Future<CashOperationResult<void>> get beginDepositOutside async {
    final result = await CashChangerPlatform.instance.beginDepositOutside();
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //changer di status
  static Future<CashOperationResult<String>> changerDIStatus(int pData) async {
    final result = await CashChangerPlatform.instance.changerDIStatus(pData);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<String>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          String value = result['value'] ?? "";
          response = CashOperationResult.success(value);
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //dispense cash
  static Future<CashOperationResult<void>> dispenseCash(String cashCounts) async {
    Map? result = await CashChangerPlatform.instance.dispenseCash(cashCounts);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
  }

  //collectAll
  static Future<CashOperationResult<void>> collectAll({int bill = 1, int coin = 1}) async {
    final result = await CashChangerPlatform.instance.collectAll(bill: bill, coin: coin);
    if (result == null) {
      return CashOperationResult.failure(code: -1, message: 'cash_error_common');
    }
    CashOperationResult<void>? response;
    await changerResultNext(
        resultCode: result['code'],
        onSuccess: () {
          response = CashOperationResult.success();
        },
        showError: (error) {
          response = CashOperationResult.failure(code: result['code'] ?? -1, message: error);
        });
    return response ?? CashOperationResult.failure(code: -1, message: 'cash_error_common');
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
      //required Function onRetry,
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
            //onRetry: onRetry,
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
      //required Function onRetry,
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

        // final result = await endDeposit(DepositAction.repay.index);
        // if (result == 0) {
        //   onRetry();
        // } else {
          showError("cash_error_if_error");
        //}
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
      //Function? onRetry,
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
          //onRetry: onRetry ?? () {},
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
