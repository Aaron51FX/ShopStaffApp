extension SafeIndex<E> on List<E> {
  E? fromIndex(int index) {
    return (index >= 0 && index < length) ? this[index] : null;
  }
}
const int OPOSERREXT = 201;

enum DepositAction {
  none, // don't use
  change,
  noChange,
  repay,
}



class ChangerResult {
  final int code;
  final dynamic value;
  final String message;
  ChangerResult({required this.code, required this.value, required this.message});
}

//定义一组错误码enum
enum HealthResultCode {
  OPOS_SUCCESS,
  OPOS_E_CLOSED, //closed status use OPEN method
  OPOS_E_CLAIMED, //暂无
  OPOS_E_NOTCLAIMED,//when check status // start from Claim method
  OPOS_E_NOSERVICE, //设置问题出错 需要检查初始设置，需要外部手动检查。
  OPOS_E_DISABLED, // DeviceEnabled = false set to true
  OPOS_E_ILLEGAL, // Open 时已经打开 不需要再打开 跳过。
  OPOS_E_NOHARDWARE, //断电了或者没有连接，需要外部手动检查。
  OPOS_E_OFFLINE, //失联了 外部手动检查。
  OPOS_E_NOEXIST, //打开指定的设备名失败，需要检查设置的设备名称。
  OPOS_E_EXISTS,
  OPOS_E_FAILURE, //与出入钱有关的操作失败，无法处理只能上报记录
  OPOS_E_TIMEOUT, //Claim 时超时，设置更长超时时间。
  OPOS_E_BUSY, //本方法正在执行，需要等待。
  OPOS_E_EXTENDED, //其他 详细检查ResultCodeExtended
  NONE,
}
enum ResultCodeExtended {
  OPOS_SUCCESS,
  OPOS_ECHAN_OVERDISPENSE, //超出最大找零金额 取消订单 提醒商家补钱
  OPOS_ECHAN_TOTALOVER, //none
  OPOS_ECHAN_CHANGEERROR,
  OPOS_ECHAN_OVER, //超过指定面值的最大找零数量 取消订单 提醒商家补钱
  OPOS_ECHAN_IFERROR, //通信异常 重试
  OPOS_ECHAN_SETERROR, //脱机状态 提醒商家外部处理
  OPOS_ECHAN_ERROR,
  OPOS_ECHAN_CHARGING, //正在找零中 等待
  OPOS_ECHAN_NEAREMPTY,//none
  OPOS_ECHAN_EMPTY,//none
  OPOS_ECHAN_NEARFULL,//none
  OPOS_ECHAN_FULL, //钱满了 提醒商家取出
  OPOS_ECHAN_OVERFLOW,//none
  OPOS_ECHAN_REJECT,//none
  OPOS_ECHAN_BUSY,//处理中 等待再试
  OPOS_ECHAN_ASYNCBUSY,//none
  OPOS_ECHAN_CASSETTEWAIT,//等待提取 提醒取出
  OPOS_ECHAN_COLLECTWAIT,//none
  OPOS_ECHAN_COUNTERROR,
  OPOS_ECHAN_AMOUNTERROR,
  OPOS_ECHAN_IMPOSSIBLE,//兑换机状态，或者无法执行当前操作。
  OPOS_ECHAN_CANNOTPAY,
  OPOS_ECHAN_NOTSTORE,
  OPOS_ECHAN_NEAUTRAL,
  OPOS_ECHAN_DEPOSIT,//计数中 等待再执行
  OPOS_ECHAN_PAUSEDEPOSIT,//DirectIO 时暂停计数
  OPOS_ECHAN_UNMATCH,
  OPOS_ECHAN_DEPOSIT_ELSE_BILL,
  OPOS_ECHAN_DEPOSIT_ELSE_COIN,
  OPOS_ECHAN_DEPOSIT_MOVE_BILL,
  OPOS_ECHAN_DEPOSIT_MOVE_COIN,
  OPOS_ECHAN_DEPOSIT_ERR_BILL,
  OPOS_ECHAN_DEPOSIT_ERR_COIN,
  OPOS_ECHAN_DEPOSIT_RJ_BILL,
  OPOS_ECHAN_DEPOSIT_RJ_COIN,
  OPOS_ECHAN_DEPOSIT_CAS_BILL,
  OPOS_ECHAN_DEPOSIT_OVF_COIN,
  OPOS_ECHAN_DEPOSIT_SET_BILL,
  OPOS_ECHAN_DEPOSIT_SET_COIN,
  OPOS_ECHAN_DEPOSIT_RESET_BILL,
  OPOS_ECHAN_DEPOSIT_RESET_COIN,
  NONE,
}

// Enum parseEnum<T>(List<T> values, int value) {
//   return values.firstWhere((v) => v.index == value);
// }
enum OpenChangerResult {
  OPEN_SUCCESS,
  OPOS_OPEN_ERR,
  OPOS_OPEN_ERR_SO,//SO库无法使用 提醒处理 重新初始化
  OPOS_OR_ALREADYOPEN, //已经打开 跳过
  OPOS_OR_REGBADNAME, //打开名称不正确 提醒处理 打开设置工具
  OPOS_OR_REGPROGID,
  OPOS_OR_CREATE, //初始化SO有问题 提醒处理 重新初始化
  OPOS_OR_BADIF, //SO库无法使用 提醒处理 重新初始化
  OPOS_ORS_CONFIG, //配置文件有问题 提醒处理 重新初始化
  OPOS_ORS_NOPORT, //端口设置有问题 提醒处理 打开设置工具
  OPOS_ORS_NOPORTED, //端口设置有问题 提醒处理 打开设置工具
  OPOS_ORS_SENSETHREAD, //线程有问题 暂无法处理 上报记录
  OPOS_ORS_EVENTTHRREAD, //事件处理有问题 暂无法处理 上报记录
  OPOS_ORS_EVENTCLASS, //事件处理程序有问题 暂无法处理 上报记录
  OPOS_ORS_FAILEDOPEN, //SO库无法使用 提醒处理 重新初始化
  OPOS_ORS_BADVERSION, //SO版本不正确 提醒处理 重新初始化
  OPOS_SPECIFIC,
  NONE,
}

enum StatusUpdateEvent {
  ChanStatusOk,
  OPOS_SUE_POWER_ONLINE,
  OPOS_SUE_POWER_OFF,
  OPOS_SUE_POWER_OFFLINE,
  CHAN_STATUS_JAM,
  CHAN_STATUS_JAMOK,
  CHAN_STATUS_EMPTY,
  CHAN_STATUS_NEAREMPTY,
  CHAN_STATUS_EMPTYOK,
  CHAN_STATUS_FULL,
  CHAN_STATUS_NEARFULL,
  CHAN_STATUS_FULLOK,
  CHAN_STATUS_ASYNC,
}

class OposResult {
  late final HealthResultCode resultCode;
  late final ResultCodeExtended resultCodeExtended;
  OposResult({required this.resultCode, required this.resultCodeExtended});
}