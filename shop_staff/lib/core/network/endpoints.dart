import 'app_environment.dart';

class Endpoints {
  final AppConfig config;
  Endpoints(this.config);

  String get _b => config.apiBase;
  String get _face => config.faceBase;

  String get bootIndex => '$_b/pad/web/boot/index';
  String get bootIndexV1 => '$_b/pad/web/boot/index/v1';
  String get bootIndexCategoryV2 => '$_b/pad/web/boot/index/category/v2';
  String get bootIndexCategoryEdit => '$_b/pad/web/boot/index/category/v0';
  String get bootIndexMenuV2 => '$_b/pad/web/boot/index/menu/v2';
  String get bootIndexMenuV3 => '$_b/pad/web/boot/index/menu/v3';
  String get bootIndexMenuEdit => '$_b/pad/web/boot/index/menu/v0';

  String get stockBooking => '$_b/pad/web/boot/stock-booking';

  String get orderV4 => '$_b/pad/web/boot/v4/order';
  String get calculateOrder => '$_b/pad/web/boot/v3/calculate/order';
  String get toPay => '$_b/pad/web/boot/toPay';
  String get toPayV2 => '$_b/pad/web/boot/toPay/v2';
  String get posPayReport => '$_b/pad/web/boot/pos/pay/report';

  String get printV5 => '$_b/pad/web/boot/v5/print';
  String get printV6 => '$_b/pad/web/boot/v6/print';
  String get printV7 => '$_b/pad/web/boot/v7/print';
  String get printV8 => '$_b/pad/web/boot/v8/print';
  String get retryPrint => '$_b/pad/web/boot/retry/print';

  String get reportV1 => '$_b/pad/web/boot/v1/report';

  String get cancel => '$_b/pad/web/boot/cancel';
  String get cancelV1 => '$_b/pad/web/boot/v1/cancel';

  String get changeState => '$_b/pad/web/boot/change/state/v1';
  String get changeInfo => '$_b/pad/web/boot/information';
  String get changeReset => '$_b/pad/web/boot/reset';
  String get changeSet => '$_b/pad/web/boot/change/add';

  String get linePayConfirm => '$_b/pad/web/boot/linePay/confirm';

  String get creditCard => '$_b/pad/web/boot/creditCard';
  String get creditCardCancel => '$_b/pad/web/boot/creditCard/back';

  String get logUpload => '$_b/pad/web/boot/log/upload';

  String get activate => '$_b/pad/web/boot/activate';
  String get activateV2 => '$_b/pad/web/boot/activate/v2';
  String get activateV3 => '$_b/pad/web/boot/activate/v3';
  String get activateV4 => '$_b/pad/web/boot/activate/v4';

  String get shopOrderTableNum => '$_b/pad/web/table/shopOrderTableNum';
  String get bootCalculate => '$_b/pad/web/boot/calculate';
  String get bootCalculateV2 => '$_b/web/boot/calculate/v2';
  String get checkOutOrderDetails => '$_b/pad/web/table/checkOutOrderDetails';

  String get toPayConfirm => '$_b/pad/web/boot/toPay/confirm';

  String get barCodeQuery => '$_b/pad/web/boot/bar_code/query';

  String get reimburseQuery => '$_b/pad/web/boot/reimburse/query';
  String get reimburseExecute => '$_b/pad/web/boot/reimburse/execute';
  String get reimburseNotify => '$_b/pad/web/boot/reimburse/notify';

  String get receiptQuery => '$_b/pad/web/boot/retry/printByQuery';
  String get receiptQueryV2 => '$_b/pad/web/boot/retry/printByQuery/v2';

  String get closePrintInfo => '$_b/pad/web/boot/query/printInfo';
  String get gloryClosePrintInfo => '$_b/pad/web/glory/query/printInfo';
  String get emailList => '$_b/pad/web/boot/emails';
  String get adminVerify => '$_b/pad/web/boot/sendVerifyCode';
  String get closeConfirm => '$_b/pad/web/boot/confirm/close';

  String get posTest => '$_b/pad/web/boot/pos/test';
  String get troubleNotify => '$_b/pad/web/boot/notice';

  String get glorySupplement => '$_b/web/glory/supplement';
  String get gloryConfirmSync => '$_b/web/glory/confirm/sync';
  String get gloryExchange => '$_b/web/glory/exchange';
  String get gloryConfirmClose => '$_b/web/glory/confirm/close';
  String get gloryEmpty => '$_b/web/glory/empty';
  String get gloryInformation => '$_b/web/glory/information';
  String get calculateConfirm => '$_b/web/boot/calculate/confirm';

  String get machineNearFull => '$_b/web/glory/full/notice';
  String get machineFull => '$_b/web/glory/stop/notice';

  String get startSelling => '$_b/web/boot/start/selling';
  String get stopSelling => '$_b/web/boot/stop/selling';

  String sseSubscribePanda(String id) =>
      '${config.isProd ? config.apiProfileBase : "http://172.20.10.56:38081/"}web/subscribe/panda/$id';
  String sseSubscribeSmartWe(String id) =>
      '${config.isProd ? config.apiProfileBase : "http://172.20.10.56:38081/"}web/subscribe/smartWe/$id';
  String get sseCallback => '$_b/web/sse/received/callback';

  String get faceOldSearch => '${_face}oa/face/recognition/old/search';
  String get faceRegister => '${_face}oa/face/recognition/register';
}
