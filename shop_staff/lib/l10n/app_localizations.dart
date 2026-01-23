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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

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

  /// No description provided for @settingsErrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {detail}'**
  String settingsErrorLoadFailed(Object detail);

  /// No description provided for @settingsErrorSaveBasicFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save business info: {detail}'**
  String settingsErrorSaveBasicFailed(Object detail);

  /// No description provided for @settingsErrorSaveNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save network settings: {detail}'**
  String settingsErrorSaveNetworkFailed(Object detail);

  /// No description provided for @settingsErrorSavePrinterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save printer settings: {detail}'**
  String settingsErrorSavePrinterFailed(Object detail);

  /// No description provided for @settingsBusinessInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Store profile'**
  String get settingsBusinessInfoTitle;

  /// No description provided for @settingsBusinessInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These details appear on the customer display and receipts'**
  String get settingsBusinessInfoSubtitle;

  /// No description provided for @settingsBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get settingsBusinessNameLabel;

  /// No description provided for @settingsBusinessCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Store code'**
  String get settingsBusinessCodeLabel;

  /// No description provided for @settingsBusinessPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get settingsBusinessPhoneLabel;

  /// No description provided for @settingsBusinessAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Store address'**
  String get settingsBusinessAddressLabel;

  /// No description provided for @settingsBusinessHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Business hours & seating'**
  String get settingsBusinessHoursTitle;

  /// No description provided for @settingsBusinessHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Managed in the back office store data'**
  String get settingsBusinessHoursSubtitle;

  /// No description provided for @settingsBusinessHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get settingsBusinessHoursLabel;

  /// No description provided for @settingsBusinessSeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get settingsBusinessSeatsLabel;

  /// No description provided for @settingsLogoutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutButton;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsLogoutConfirmMessage;

  /// No description provided for @settingsRoleSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get settingsRoleSwitchTitle;

  /// No description provided for @settingsRoleSwitchMessage.
  ///
  /// In en, this message translates to:
  /// **'Switch to \"{role}\" and restart the app to load that interface?'**
  String settingsRoleSwitchMessage(Object role);

  /// No description provided for @settingsRoleSwitchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Switched to {role}. Redirecting...'**
  String settingsRoleSwitchSuccess(Object role);

  /// No description provided for @settingsRoleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Role selection'**
  String get settingsRoleSelectionTitle;

  /// No description provided for @settingsRoleSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the device role; it will restart and open the selected interface'**
  String get settingsRoleSelectionSubtitle;

  /// No description provided for @settingsRoleSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Staff terminal handles checkout and management; customer display shows products and ordering.'**
  String get settingsRoleSelectionDescription;

  /// No description provided for @settingsCashPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get settingsCashPaymentTitle;

  /// No description provided for @settingsCashPaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the cash machine to enable or verify cash payments'**
  String get settingsCashPaymentSubtitle;

  /// No description provided for @settingsCashStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Current status'**
  String get settingsCashStatusLabel;

  /// No description provided for @settingsCashEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsCashEnabled;

  /// No description provided for @settingsCashDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsCashDisabled;

  /// No description provided for @settingsCashNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Not authorized or cash payments unsupported'**
  String get settingsCashNotSupported;

  /// No description provided for @settingsCashLastCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Last check failed: {detail}'**
  String settingsCashLastCheckFailed(Object detail);

  /// No description provided for @settingsCashChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settingsCashChecking;

  /// No description provided for @settingsCashCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get settingsCashCheckNow;

  /// No description provided for @settingsCashSkipOnce.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get settingsCashSkipOnce;

  /// No description provided for @settingsPosNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'POS terminal network'**
  String get settingsPosNetworkTitle;

  /// No description provided for @settingsPosNetworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the terminal and card reader on the same network'**
  String get settingsPosNetworkSubtitle;

  /// No description provided for @settingsPosIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Terminal IP'**
  String get settingsPosIpLabel;

  /// No description provided for @settingsPosPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Terminal port'**
  String get settingsPosPortLabel;

  /// No description provided for @settingsPrinterConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Printer configuration'**
  String get settingsPrinterConfigTitle;

  /// No description provided for @settingsPrinterConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage receipts, labels, and kitchen printing'**
  String get settingsPrinterConfigSubtitle;

  /// No description provided for @settingsPrinterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No printers configured yet. Add one in the back office.'**
  String get settingsPrinterEmpty;

  /// No description provided for @settingsMachineInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Device identifiers'**
  String get settingsMachineInfoTitle;

  /// No description provided for @settingsMachineInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active terminal and activation details'**
  String get settingsMachineInfoSubtitle;

  /// No description provided for @settingsMachineCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Machine code'**
  String get settingsMachineCodeLabel;

  /// No description provided for @settingsStationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Station code'**
  String get settingsStationCodeLabel;

  /// No description provided for @settingsAuthorizedShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorized shop code'**
  String get settingsAuthorizedShopLabel;

  /// No description provided for @settingsLanguageFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages & features'**
  String get settingsLanguageFeatureTitle;

  /// No description provided for @settingsLanguageFeatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display languages and features from store authorization'**
  String get settingsLanguageFeatureSubtitle;

  /// No description provided for @settingsSupportedLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Supported languages'**
  String get settingsSupportedLanguagesLabel;

  /// No description provided for @settingsSupportedLanguagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsSupportedLanguagesEmpty;

  /// No description provided for @settingsFeatureOnlineCall.
  ///
  /// In en, this message translates to:
  /// **'Online call'**
  String get settingsFeatureOnlineCall;

  /// No description provided for @settingsFeatureTaxSystem.
  ///
  /// In en, this message translates to:
  /// **'Tax system'**
  String get settingsFeatureTaxSystem;

  /// No description provided for @settingsFeatureDynamicCode.
  ///
  /// In en, this message translates to:
  /// **'Dynamic ticket'**
  String get settingsFeatureDynamicCode;

  /// No description provided for @settingsFeatureMultiplayer.
  ///
  /// In en, this message translates to:
  /// **'Multi-terminal collaboration'**
  String get settingsFeatureMultiplayer;

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

  /// No description provided for @settingsValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsValueNotSet;

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

  /// No description provided for @settingsPrinterReceiptTicket.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get settingsPrinterReceiptTicket;

  /// No description provided for @settingsPrinterReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get settingsPrinterReceiptLabel;

  /// No description provided for @settingsPrinterLabelSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Label size'**
  String get settingsPrinterLabelSizeTitle;

  /// No description provided for @settingsPrinterLabelSizeNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsPrinterLabelSizeNone;

  /// No description provided for @settingsPrinterDefaultTag.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsPrinterDefaultTag;

  /// No description provided for @settingsPrinterTypeKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen printing'**
  String get settingsPrinterTypeKitchen;

  /// No description provided for @settingsPrinterTypeCenter.
  ///
  /// In en, this message translates to:
  /// **'Central printing'**
  String get settingsPrinterTypeCenter;

  /// No description provided for @settingsPrinterTypeFront.
  ///
  /// In en, this message translates to:
  /// **'Front desk printing'**
  String get settingsPrinterTypeFront;

  /// No description provided for @settingsPrinterTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Printer type {type}'**
  String settingsPrinterTypeUnknown(Object type);

  /// No description provided for @settingsPrinterEditIpTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit printer IP'**
  String get settingsPrinterEditIpTitle;

  /// No description provided for @settingsPrinterEditIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Printer IP address'**
  String get settingsPrinterEditIpLabel;

  /// No description provided for @settingsPrinterEditPortTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit printer port'**
  String get settingsPrinterEditPortTitle;

  /// No description provided for @settingsPrinterEditPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Printer port'**
  String get settingsPrinterEditPortLabel;

  /// No description provided for @settingsPrinterIpTitle.
  ///
  /// In en, this message translates to:
  /// **'Printer IP'**
  String get settingsPrinterIpTitle;

  /// No description provided for @settingsPrinterPortTitle.
  ///
  /// In en, this message translates to:
  /// **'Printer port'**
  String get settingsPrinterPortTitle;

  /// No description provided for @settingsPrinterToggleContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous printing'**
  String get settingsPrinterToggleContinuous;

  /// No description provided for @settingsPrinterToggleOption.
  ///
  /// In en, this message translates to:
  /// **'Print optional fields'**
  String get settingsPrinterToggleOption;

  /// No description provided for @settingsPrinterToggleDirection.
  ///
  /// In en, this message translates to:
  /// **'Reverse printing'**
  String get settingsPrinterToggleDirection;

  /// No description provided for @entryPeerDisconnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer display disconnected'**
  String get entryPeerDisconnectedTitle;

  /// No description provided for @entryPeerDisconnectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Search again and try to reconnect to the customer display?'**
  String get entryPeerDisconnectedMessage;

  /// No description provided for @entryPeerReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get entryPeerReconnect;

  /// No description provided for @entryPeerConnectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect customer display'**
  String get entryPeerConnectDialogTitle;

  /// No description provided for @entryPeerSearchingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby customer display…'**
  String get entryPeerSearchingCustomer;

  /// No description provided for @entryHistoryOrders.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get entryHistoryOrders;

  /// No description provided for @entryDatePattern.
  ///
  /// In en, this message translates to:
  /// **'MMM d, y · EEEE'**
  String get entryDatePattern;

  /// No description provided for @peerStatusConnectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Connected:'**
  String get peerStatusConnectedPrefix;

  /// No description provided for @peerStatusDisconnectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Not connected:'**
  String get peerStatusDisconnectedPrefix;

  /// No description provided for @peerStatusErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Connection error:'**
  String get peerStatusErrorPrefix;

  /// No description provided for @peerStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet'**
  String get peerStatusIdle;

  /// No description provided for @peerSearchInProgress.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get peerSearchInProgress;

  /// No description provided for @peerSearchRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart search'**
  String get peerSearchRestart;

  /// No description provided for @peerActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get peerActionDone;

  /// No description provided for @peerActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get peerActionClose;

  /// No description provided for @peerLabelCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer display'**
  String get peerLabelCustomer;

  /// No description provided for @peerLabelStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff terminal'**
  String get peerLabelStaff;

  /// No description provided for @commonUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get commonUnknownError;

  /// No description provided for @customerDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get customerDisconnectTitle;

  /// No description provided for @customerDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Connection to the staff terminal was lost. Please reconnect.'**
  String get customerDisconnectMessage;

  /// No description provided for @customerReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get customerReconnect;

  /// No description provided for @customerLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get customerLater;

  /// No description provided for @customerConnectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect staff terminal'**
  String get customerConnectDialogTitle;

  /// No description provided for @customerPeerSearchingStaff.
  ///
  /// In en, this message translates to:
  /// **'Searching for staff terminal…'**
  String get customerPeerSearchingStaff;

  /// No description provided for @customerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get customerGreeting;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer display'**
  String get customerLabel;

  /// No description provided for @optionGroupMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple'**
  String get optionGroupMultiple;

  /// No description provided for @optionGroupSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get optionGroupSingle;

  /// No description provided for @optionGroupMinPrefix.
  ///
  /// In en, this message translates to:
  /// **'Min '**
  String get optionGroupMinPrefix;

  /// No description provided for @optionGroupMaxPrefix.
  ///
  /// In en, this message translates to:
  /// **'Max '**
  String get optionGroupMaxPrefix;

  /// No description provided for @optionGroupNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No options'**
  String get optionGroupNoOptions;

  /// No description provided for @optionGroupSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get optionGroupSelected;

  /// No description provided for @optionGroupNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get optionGroupNotSelected;

  /// No description provided for @cashMachineTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash machine check'**
  String get cashMachineTitle;

  /// No description provided for @cashMachineCheckingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking the cash machine, please wait…'**
  String get cashMachineCheckingMessage;

  /// No description provided for @cashMachineSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Cash machine is ready for cash payments.'**
  String get cashMachineSuccessMessage;

  /// No description provided for @cashMachineFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Check failed. Please verify the device connection.'**
  String get cashMachineFailureMessage;

  /// No description provided for @cashMachineStepsChecking.
  ///
  /// In en, this message translates to:
  /// **'Steps: Check status → Open → Start receive → Read amount → End'**
  String get cashMachineStepsChecking;

  /// No description provided for @cashMachineStepsFailure.
  ///
  /// In en, this message translates to:
  /// **'Flow: Check status → Open cash machine → Start Deposit → Deposit Amount → End Deposit'**
  String get cashMachineStepsFailure;

  /// No description provided for @cashMachineSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get cashMachineSkip;

  /// No description provided for @cashMachineRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cashMachineRetry;

  /// No description provided for @cashMachineDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cashMachineDone;

  /// No description provided for @cashMachineClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cashMachineClose;

  /// No description provided for @suspendedOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspended orders'**
  String get suspendedOrdersTitle;

  /// No description provided for @suspendedOrdersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ID or product name'**
  String get suspendedOrdersSearchHint;

  /// No description provided for @suspendedOrdersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suspended orders'**
  String get suspendedOrdersEmpty;

  /// No description provided for @suspendedOrdersItemCountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Items: '**
  String get suspendedOrdersItemCountPrefix;

  /// No description provided for @suspendedOrdersItemCountSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get suspendedOrdersItemCountSuffix;

  /// No description provided for @suspendedOrdersResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get suspendedOrdersResume;

  /// No description provided for @suspendedOrdersDatePattern.
  ///
  /// In en, this message translates to:
  /// **'MM-dd HH:mm'**
  String get suspendedOrdersDatePattern;

  /// No description provided for @posClearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get posClearCartTitle;

  /// No description provided for @posClearCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the cart?'**
  String get posClearCartMessage;

  /// No description provided for @posSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend order'**
  String get posSuspendTitle;

  /// No description provided for @posSuspendMessage.
  ///
  /// In en, this message translates to:
  /// **'Suspend the current order?'**
  String get posSuspendMessage;

  /// No description provided for @posPushProductToCustomerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send to customer display'**
  String get posPushProductToCustomerTooltip;

  /// No description provided for @posClearCustomerDisplayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear customer display'**
  String get posClearCustomerDisplayTooltip;

  /// No description provided for @posBroadcastCategoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Broadcast categories'**
  String get posBroadcastCategoriesTooltip;

  /// No description provided for @posSearchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get posSearchProductHint;

  /// No description provided for @discountInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter discount amount'**
  String get discountInputTitle;

  /// No description provided for @discountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get discountConfirm;

  /// No description provided for @discountKeyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get discountKeyClear;

  /// No description provided for @discountKeyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get discountKeyDelete;

  /// No description provided for @posOrderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order #:'**
  String get posOrderNumberLabel;

  /// No description provided for @posPushCartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send cart to customer display'**
  String get posPushCartTooltip;

  /// No description provided for @posOrderModeDineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine in'**
  String get posOrderModeDineIn;

  /// No description provided for @posOrderModeTakeout.
  ///
  /// In en, this message translates to:
  /// **'Takeout'**
  String get posOrderModeTakeout;

  /// No description provided for @posCartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty\nPlease select items from the left'**
  String get posCartEmptyMessage;

  /// No description provided for @posSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get posSubtotalLabel;

  /// No description provided for @posDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get posDiscountLabel;

  /// No description provided for @posTotalDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get posTotalDueLabel;

  /// No description provided for @posSuspendButton.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get posSuspendButton;

  /// No description provided for @posDiscountButton.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get posDiscountButton;

  /// No description provided for @posClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get posClearButton;

  /// No description provided for @posCheckoutButton.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get posCheckoutButton;

  /// No description provided for @posOptionGroupCurrentPrefix.
  ///
  /// In en, this message translates to:
  /// **'Current '**
  String get posOptionGroupCurrentPrefix;

  /// No description provided for @posOptionSendGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send this group to customer'**
  String get posOptionSendGroupTooltip;

  /// No description provided for @posOptionSendAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send current options to customer'**
  String get posOptionSendAllTooltip;

  /// No description provided for @posOptionMaxReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Max selections reached'**
  String get posOptionMaxReachedTitle;

  /// No description provided for @posOptionMaxReachedMessageSuffix.
  ///
  /// In en, this message translates to:
  /// **' has reached the maximum selections'**
  String get posOptionMaxReachedMessageSuffix;

  /// No description provided for @posOptionMaxReachedOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get posOptionMaxReachedOk;

  /// No description provided for @posOptionAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get posOptionAddConfirm;

  /// No description provided for @posOptionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get posOptionUpdate;

  /// No description provided for @posOptionMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing required options'**
  String get posOptionMissingTitle;

  /// No description provided for @posOptionMissingOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get posOptionMissingOk;

  /// No description provided for @paymentSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get paymentSelectionTitle;

  /// No description provided for @paymentSelectionPushTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send payment options to customer display'**
  String get paymentSelectionPushTooltip;

  /// No description provided for @paymentGroupCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentGroupCashTitle;

  /// No description provided for @paymentGroupCashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with cash'**
  String get paymentGroupCashSubtitle;

  /// No description provided for @paymentGroupQrTitle.
  ///
  /// In en, this message translates to:
  /// **'QR payment'**
  String get paymentGroupQrTitle;

  /// No description provided for @paymentGroupCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit card'**
  String get paymentGroupCardTitle;

  /// No description provided for @paymentGroupCardShort.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentGroupCardShort;

  /// No description provided for @paymentGroupTransitTitle.
  ///
  /// In en, this message translates to:
  /// **'Transit/IC & eMoney'**
  String get paymentGroupTransitTitle;

  /// No description provided for @paymentGroupTransitShort.
  ///
  /// In en, this message translates to:
  /// **'eMoney'**
  String get paymentGroupTransitShort;

  /// No description provided for @paymentSelectionNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get paymentSelectionNotConfigured;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get orderHistoryTitle;

  /// No description provided for @orderHistoryRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get orderHistoryRefreshTooltip;

  /// No description provided for @orderHistorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ID or product name'**
  String get orderHistorySearchHint;

  /// No description provided for @orderHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No order history'**
  String get orderHistoryEmpty;

  /// No description provided for @orderHistoryItemCountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Items: '**
  String get orderHistoryItemCountPrefix;

  /// No description provided for @orderHistoryItemCountSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get orderHistoryItemCountSuffix;

  /// No description provided for @orderHistoryPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get orderHistoryPaid;

  /// No description provided for @orderHistoryUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get orderHistoryUnpaid;

  /// No description provided for @orderHistoryDatePatternShort.
  ///
  /// In en, this message translates to:
  /// **'MM-dd HH:mm'**
  String get orderHistoryDatePatternShort;

  /// No description provided for @orderHistoryDatePatternLong.
  ///
  /// In en, this message translates to:
  /// **'yyyy-MM-dd HH:mm:ss'**
  String get orderHistoryDatePatternLong;

  /// No description provided for @orderHistoryDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderHistoryDetailsTitle;

  /// No description provided for @orderHistoryCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get orderHistoryCloseTooltip;

  /// No description provided for @orderHistoryDetailOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderHistoryDetailOrderIdLabel;

  /// No description provided for @orderHistoryDetailTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get orderHistoryDetailTimeLabel;

  /// No description provided for @orderHistoryDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderHistoryDetailStatusLabel;

  /// No description provided for @orderHistoryDetailPayMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get orderHistoryDetailPayMethodLabel;

  /// No description provided for @orderHistoryDetailAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get orderHistoryDetailAmountLabel;

  /// No description provided for @orderHistoryDetailModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get orderHistoryDetailModeLabel;

  /// No description provided for @orderHistoryDetailItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderHistoryDetailItemCountLabel;

  /// No description provided for @orderHistoryDetailProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get orderHistoryDetailProductsTitle;

  /// No description provided for @orderHistoryPayMethodUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get orderHistoryPayMethodUnknown;

  /// No description provided for @orderHistoryReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get orderHistoryReorder;

  /// No description provided for @orderHistoryPrintReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get orderHistoryPrintReceipt;

  /// No description provided for @orderHistoryPrintKitchen.
  ///
  /// In en, this message translates to:
  /// **'Print kitchen ticket'**
  String get orderHistoryPrintKitchen;

  /// No description provided for @cancelDialogLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Canceling'**
  String get cancelDialogLoadingTitle;

  /// No description provided for @cancelDialogLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Sending cancel request to terminal…'**
  String get cancelDialogLoadingMessage;

  /// No description provided for @cancelDialogSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get cancelDialogSuccessTitle;

  /// No description provided for @cancelDialogFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed'**
  String get cancelDialogFailureTitle;

  /// No description provided for @cancelDialogSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Payment canceled'**
  String get cancelDialogSuccessMessage;

  /// No description provided for @cancelDialogFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed. Please try again later.'**
  String get cancelDialogFailureMessage;

  /// No description provided for @cancelDialogDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cancelDialogDone;

  /// No description provided for @cancelDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get cancelDialogConfirm;

  /// No description provided for @cashAmountMatched.
  ///
  /// In en, this message translates to:
  /// **'Amount matches order total'**
  String get cashAmountMatched;

  /// No description provided for @cashAmountChangePrefix.
  ///
  /// In en, this message translates to:
  /// **'Change due '**
  String get cashAmountChangePrefix;

  /// No description provided for @cashAmountShortPrefix.
  ///
  /// In en, this message translates to:
  /// **'Remaining '**
  String get cashAmountShortPrefix;

  /// No description provided for @cashAmountConfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed cash amount'**
  String get cashAmountConfirmedLabel;

  /// No description provided for @cashAmountDetectingLabel.
  ///
  /// In en, this message translates to:
  /// **'Detecting cash amount'**
  String get cashAmountDetectingLabel;

  /// No description provided for @cashAmountExpectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order total: '**
  String get cashAmountExpectedPrefix;

  /// No description provided for @paymentOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get paymentOrderIdLabel;

  /// No description provided for @paymentChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentChannelLabel;

  /// No description provided for @loginActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Device activation'**
  String get loginActivateTitle;

  /// No description provided for @loginMachineCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Machine code'**
  String get loginMachineCodeLabel;

  /// No description provided for @loginActivateButton.
  ///
  /// In en, this message translates to:
  /// **'Activate and continue'**
  String get loginActivateButton;

  /// No description provided for @activationFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Activation failed: {detail}'**
  String activationFailedMessage(Object detail);

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get splashInitializing;

  /// No description provided for @splashActivationFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Activation failed ({status}): {detail}'**
  String splashActivationFailedMessage(Object status, Object detail);

  /// No description provided for @splashLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {detail}'**
  String splashLoadFailedMessage(Object detail);

  /// No description provided for @splashPossibleCauses.
  ///
  /// In en, this message translates to:
  /// **'Possible causes: temporary network/server 502, version mismatch, or invalid machine code'**
  String get splashPossibleCauses;

  /// No description provided for @splashRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get splashRetry;

  /// No description provided for @splashReactivate.
  ///
  /// In en, this message translates to:
  /// **'Re-activate'**
  String get splashReactivate;

  /// No description provided for @commonNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get commonNetworkLabel;

  /// No description provided for @commonUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get commonUnitPriceLabel;

  /// No description provided for @customerUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'Unknown message received: {type}'**
  String customerUnknownMessage(Object type);

  /// No description provided for @customerOrderNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNumber}'**
  String customerOrderNumberTitle(Object orderNumber);

  /// No description provided for @customerTotalDueWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Total due ¥{amount}'**
  String customerTotalDueWithAmount(Object amount);

  /// No description provided for @customerPaymentChoiceTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get customerPaymentChoiceTapToSelect;

  /// No description provided for @customerPaymentChoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get customerPaymentChoiceUnavailable;

  /// No description provided for @customerStatusConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected to staff terminal'**
  String get customerStatusConnectedTitle;

  /// No description provided for @customerStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing: {name}'**
  String customerStatusSyncing(Object name);

  /// No description provided for @customerStatusSearchingDescription.
  ///
  /// In en, this message translates to:
  /// **'Please make sure the staff terminal is open and nearby.'**
  String get customerStatusSearchingDescription;

  /// No description provided for @customerStatusErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection issue'**
  String get customerStatusErrorTitle;

  /// No description provided for @customerStatusErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Please retry or check the network.'**
  String get customerStatusErrorDescription;

  /// No description provided for @customerStatusIdleDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Connect staff terminal\" above to start pairing.'**
  String get customerStatusIdleDescription;

  /// No description provided for @posToastPeerSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Customer sync is disabled'**
  String get posToastPeerSyncDisabled;

  /// No description provided for @posToastPeerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Customer display not connected. Push failed.'**
  String get posToastPeerNotConnected;

  /// No description provided for @posToastPushedToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Sent to customer display'**
  String get posToastPushedToCustomer;

  /// No description provided for @posToastPushedConfigToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Sent current configuration to customer display'**
  String get posToastPushedConfigToCustomer;

  /// No description provided for @posToastPushedOptionGroupToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Sent option group to customer display'**
  String get posToastPushedOptionGroupToCustomer;

  /// No description provided for @posToastCartEmptyCannotPush.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty. Unable to push.'**
  String get posToastCartEmptyCannotPush;

  /// No description provided for @posToastCartSentToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Sent cart to customer display'**
  String get posToastCartSentToCustomer;

  /// No description provided for @posToastClearedCustomerDisplay.
  ///
  /// In en, this message translates to:
  /// **'Cleared customer display'**
  String get posToastClearedCustomerDisplay;

  /// No description provided for @posToastLocalOrderSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save local order'**
  String get posToastLocalOrderSaveFailed;

  /// No description provided for @posToastOrderSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Order submission failed'**
  String get posToastOrderSubmitFailed;

  /// No description provided for @posToastNoPayableOrder.
  ///
  /// In en, this message translates to:
  /// **'No payable order available'**
  String get posToastNoPayableOrder;

  /// No description provided for @orderHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get orderHistoryLoadFailed;

  /// No description provided for @customerOptionsBasePricePrefix.
  ///
  /// In en, this message translates to:
  /// **'Base price '**
  String get customerOptionsBasePricePrefix;

  /// No description provided for @customerOptionsSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected options'**
  String get customerOptionsSelectedTitle;

  /// No description provided for @customerOptionsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Current total'**
  String get customerOptionsTotalLabel;
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
