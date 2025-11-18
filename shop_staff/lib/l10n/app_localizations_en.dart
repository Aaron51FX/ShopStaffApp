// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shop Staff POS';

  @override
  String get entryTitle => 'Welcome to Smart Ordering';

  @override
  String get entrySubtitle => 'Choose how you\'d like to start a new order';

  @override
  String get entryDineInTitle => 'Dine In';

  @override
  String get entryDineInSubtitle =>
      'Ideal for in-store dining with dine-in menus and pricing';

  @override
  String get entryTakeoutTitle => 'Takeout';

  @override
  String get entryTakeoutSubtitle =>
      'Handle takeout orders with dedicated items and promotions';

  @override
  String get entryStartOrder => 'Start Order';

  @override
  String get entryPickup => 'Pickup';

  @override
  String get entrySettingsTooltip => 'Open settings';

  @override
  String get settingsShellTitle => 'Application Settings';

  @override
  String get settingsShellSubtitle =>
      'Manage terminal info and business configuration';

  @override
  String get settingsRefreshTooltip => 'Refresh settings';

  @override
  String get settingsErrorDismissTooltip => 'Close';

  @override
  String get settingsLanguageSectionTitle => 'Display language';

  @override
  String get settingsLanguageSectionSubtitle =>
      'Choose the language used across the terminal';

  @override
  String get settingsLanguageSystem => 'Follow system';

  @override
  String get settingsLanguageChinese => 'Chinese';

  @override
  String get settingsLanguageJapanese => 'Japanese';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsSectionBusinessTitle => 'Business info';

  @override
  String get settingsSectionBusinessSubtitle =>
      'Store profile and outward facing details';

  @override
  String get settingsSectionSystemTitle => 'System settings';

  @override
  String get settingsSectionSystemSubtitle =>
      'Terminal network and printer configuration';

  @override
  String get settingsSectionMachineTitle => 'Device info';

  @override
  String get settingsSectionMachineSubtitle =>
      'Active device and runtime context';

  @override
  String get posDiscountDialogTitle => 'Enter discount amount';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogConfirm => 'Confirm';

  @override
  String get settingsEditAction => 'Edit';

  @override
  String get settingsNetworkEditIpTitle => 'Edit terminal IP';

  @override
  String get settingsNetworkEditIpLabel => 'Terminal IP address';

  @override
  String get settingsNetworkEditIpHint => 'Leave empty to clear the address';

  @override
  String get settingsNetworkEditInvalidIp => 'Enter a valid IPv4 address';

  @override
  String get settingsNetworkEditPortTitle => 'Edit terminal port';

  @override
  String get settingsNetworkEditPortLabel => 'Terminal port';

  @override
  String get settingsNetworkEditPortHint => 'Leave empty to clear the port';

  @override
  String get settingsNetworkEditInvalidPort =>
      'Enter a port between 1 and 65535';
}
