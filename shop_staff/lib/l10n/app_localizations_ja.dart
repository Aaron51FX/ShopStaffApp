// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ショップスタッフPOS';

  @override
  String get entryTitle => 'スマートオーダーへようこそ';

  @override
  String get entrySubtitle => '新しい注文を開始する方法を選択してください';

  @override
  String get entryDineInTitle => '店内飲食';

  @override
  String get entryDineInSubtitle => '店内利用に最適。店内メニューと価格を自動で適用します';

  @override
  String get entryTakeoutTitle => 'テイクアウト';

  @override
  String get entryTakeoutSubtitle => 'テイクアウト注文を迅速に処理し、専用メニューと特典を表示します';

  @override
  String get entryStartOrder => '注文を開始';

  @override
  String get entryPickup => '受取';

  @override
  String get entrySettingsTooltip => '設定を開く';

  @override
  String get settingsShellTitle => 'アプリ設定';

  @override
  String get settingsShellSubtitle => '端末情報と業務設定を管理';

  @override
  String get settingsRefreshTooltip => '設定を更新';

  @override
  String get settingsErrorDismissTooltip => '閉じる';

  @override
  String get settingsLanguageSectionTitle => '表示言語';

  @override
  String get settingsLanguageSectionSubtitle => '端末全体で使用する言語を選択してください';

  @override
  String get settingsLanguageSystem => 'システムに合わせる';

  @override
  String get settingsLanguageChinese => '中国語';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageEnglish => '英語';

  @override
  String get settingsSectionBusinessTitle => '営業情報';

  @override
  String get settingsSectionBusinessSubtitle => '店舗プロフィールと対外情報';

  @override
  String get settingsSectionSystemTitle => 'システム設定';

  @override
  String get settingsSectionSystemSubtitle => '端末ネットワークとプリンターの設定';

  @override
  String get settingsSectionMachineTitle => '機器情報';

  @override
  String get settingsSectionMachineSubtitle => '現在の端末と稼働環境';

  @override
  String get posDiscountDialogTitle => '割引金額を入力してください';

  @override
  String get dialogCancel => 'キャンセル';

  @override
  String get dialogConfirm => '決定';

  @override
  String get settingsEditAction => '編集';

  @override
  String get settingsNetworkEditIpTitle => '端末IPを編集';

  @override
  String get settingsNetworkEditIpLabel => '端末IPアドレス';

  @override
  String get settingsNetworkEditIpHint => '空欄にすると値がクリアされます';

  @override
  String get settingsNetworkEditInvalidIp => '有効なIPv4アドレスを入力してください';

  @override
  String get settingsNetworkEditPortTitle => '端末ポートを編集';

  @override
  String get settingsNetworkEditPortLabel => '端末ポート';

  @override
  String get settingsNetworkEditPortHint => '空欄にすると値がクリアされます';

  @override
  String get settingsNetworkEditInvalidPort => '1～65535のポート番号を入力してください';

  @override
  String get settingsPrinterReceiptTicket => 'レシート';

  @override
  String get settingsPrinterReceiptLabel => 'ラベル';

  @override
  String get settingsPrinterLabelSizeTitle => 'ラベルサイズ';

  @override
  String get settingsPrinterLabelSizeNone => '未設定';

  @override
  String get settingsPrinterEditIpTitle => 'プリンターIPを編集';

  @override
  String get settingsPrinterEditIpLabel => 'プリンターIPアドレス';

  @override
  String get settingsPrinterEditPortTitle => 'プリンターポートを編集';

  @override
  String get settingsPrinterEditPortLabel => 'プリンターポート';

  @override
  String get settingsPrinterIpTitle => 'プリンターIP';

  @override
  String get settingsPrinterPortTitle => 'プリンターポート';

  @override
  String get settingsPrinterToggleContinuous => '連続印刷';

  @override
  String get settingsPrinterToggleOption => 'オプション項目を印刷';

  @override
  String get settingsPrinterToggleDirection => '逆向き印刷';
}
