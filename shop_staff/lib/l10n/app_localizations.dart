import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Staff POS'**
  String get appTitle;

  /// No description provided for @entryTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Ordering'**
  String get entryTitle;

  /// No description provided for @entrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to start a new order'**
  String get entrySubtitle;

  /// No description provided for @entryDineInTitle.
  ///
  /// In en, this message translates to:
  /// **'Dine In'**
  String get entryDineInTitle;

  /// No description provided for @entryDineInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ideal for in-store dining with dine-in menus and pricing'**
  String get entryDineInSubtitle;

  /// No description provided for @entryTakeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Takeout'**
  String get entryTakeoutTitle;

  /// No description provided for @entryTakeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handle takeout orders with dedicated items and promotions'**
  String get entryTakeoutSubtitle;

  /// No description provided for @entryStartOrder.
  ///
  /// In en, this message translates to:
  /// **'Start Order'**
  String get entryStartOrder;

  /// No description provided for @entryPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get entryPickup;

  /// No description provided for @entrySettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get entrySettingsTooltip;

  /// No description provided for @settingsShellTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Settings'**
  String get settingsShellTitle;

  /// No description provided for @settingsShellSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage terminal info and business configuration'**
  String get settingsShellSubtitle;

  /// No description provided for @settingsRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh settings'**
  String get settingsRefreshTooltip;

  /// No description provided for @settingsErrorDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsErrorDismissTooltip;

  /// No description provided for @settingsLanguageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settingsLanguageSectionTitle;

  /// No description provided for @settingsLanguageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the terminal'**
  String get settingsLanguageSectionSubtitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get settingsLanguageChinese;

  /// No description provided for @settingsLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get settingsLanguageJapanese;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsSectionBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business info'**
  String get settingsSectionBusinessTitle;

  /// No description provided for @settingsSectionBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store profile and outward facing details'**
  String get settingsSectionBusinessSubtitle;

  /// No description provided for @settingsSectionSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get settingsSectionSystemTitle;

  /// No description provided for @settingsSectionSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal network and printer configuration'**
  String get settingsSectionSystemSubtitle;

  /// No description provided for @settingsSectionMachineTitle.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get settingsSectionMachineTitle;

  /// No description provided for @settingsSectionMachineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active device and runtime context'**
  String get settingsSectionMachineSubtitle;

  /// No description provided for @posDiscountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter discount amount'**
  String get posDiscountDialogTitle;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirm;

  /// No description provided for @settingsEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEditAction;

  /// No description provided for @settingsNetworkEditIpTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit terminal IP'**
  String get settingsNetworkEditIpTitle;

  /// No description provided for @settingsNetworkEditIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Terminal IP address'**
  String get settingsNetworkEditIpLabel;

  /// No description provided for @settingsNetworkEditIpHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to clear the address'**
  String get settingsNetworkEditIpHint;

  /// No description provided for @settingsNetworkEditInvalidIp.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IPv4 address'**
  String get settingsNetworkEditInvalidIp;

  /// No description provided for @settingsNetworkEditPortTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit terminal port'**
  String get settingsNetworkEditPortTitle;

  /// No description provided for @settingsNetworkEditPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Terminal port'**
  String get settingsNetworkEditPortLabel;

  /// No description provided for @settingsNetworkEditPortHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to clear the port'**
  String get settingsNetworkEditPortHint;

  /// No description provided for @settingsNetworkEditInvalidPort.
  ///
  /// In en, this message translates to:
  /// **'Enter a port between 1 and 65535'**
  String get settingsNetworkEditInvalidPort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
