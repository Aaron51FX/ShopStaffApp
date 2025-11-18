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
}
