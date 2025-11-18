// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '店员POS系统';

  @override
  String get entryTitle => '欢迎使用智能点餐系统';

  @override
  String get entrySubtitle => '请选择点餐方式以开始新的订单';

  @override
  String get entryDineInTitle => '店内堂食';

  @override
  String get entryDineInSubtitle => '适用于店内用餐，自动匹配堂食菜单与价格';

  @override
  String get entryTakeoutTitle => '外带打包';

  @override
  String get entryTakeoutSubtitle => '快速处理外带订单，展示外带专属菜品与优惠';

  @override
  String get entryStartOrder => '开始点餐';

  @override
  String get entryPickup => '取单';

  @override
  String get entrySettingsTooltip => '打开设置';

  @override
  String get settingsShellTitle => '应用设置';

  @override
  String get settingsShellSubtitle => '管理终端信息与业务配置';

  @override
  String get settingsRefreshTooltip => '刷新设置';

  @override
  String get settingsErrorDismissTooltip => '关闭';

  @override
  String get settingsLanguageSectionTitle => '界面语言';

  @override
  String get settingsLanguageSectionSubtitle => '选择用于终端界面的显示语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageJapanese => '日语';

  @override
  String get settingsLanguageEnglish => '英语';

  @override
  String get settingsSectionBusinessTitle => '营业信息';

  @override
  String get settingsSectionBusinessSubtitle => '店铺档案与对外展示信息';

  @override
  String get settingsSectionSystemTitle => '系统设置';

  @override
  String get settingsSectionSystemSubtitle => '终端网络与打印配置';

  @override
  String get settingsSectionMachineTitle => '机器信息';

  @override
  String get settingsSectionMachineSubtitle => '当前设备与运行环境';

  @override
  String get posDiscountDialogTitle => '输入折扣金额';

  @override
  String get dialogCancel => '取消';

  @override
  String get dialogConfirm => '确定';

  @override
  String get settingsEditAction => '编辑';

  @override
  String get settingsNetworkEditIpTitle => '编辑终端IP';

  @override
  String get settingsNetworkEditIpLabel => '终端IP地址';

  @override
  String get settingsNetworkEditIpHint => '留空可清除该地址';

  @override
  String get settingsNetworkEditInvalidIp => '请输入合法的IPv4地址';

  @override
  String get settingsNetworkEditPortTitle => '编辑终端端口';

  @override
  String get settingsNetworkEditPortLabel => '终端端口';

  @override
  String get settingsNetworkEditPortHint => '留空可清除该端口';

  @override
  String get settingsNetworkEditInvalidPort => '请输入1到65535之间的端口号';

  @override
  String get settingsPrinterReceiptTicket => '小票';

  @override
  String get settingsPrinterReceiptLabel => '标签';

  @override
  String get settingsPrinterLabelSizeTitle => '标签尺寸';

  @override
  String get settingsPrinterLabelSizeNone => '未设置';

  @override
  String get settingsPrinterEditIpTitle => '编辑打印机IP';

  @override
  String get settingsPrinterEditIpLabel => '打印机IP地址';

  @override
  String get settingsPrinterEditPortTitle => '编辑打印机端口';

  @override
  String get settingsPrinterEditPortLabel => '打印机端口';

  @override
  String get settingsPrinterIpTitle => '打印机IP';

  @override
  String get settingsPrinterPortTitle => '打印机端口';

  @override
  String get settingsPrinterToggleContinuous => '连续打印';

  @override
  String get settingsPrinterToggleOption => '打印可选字段';

  @override
  String get settingsPrinterToggleDirection => '倒转打印';
}
