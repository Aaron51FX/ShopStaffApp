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
  String get settingsTitle => 'Settings';

  @override
  String get settingsRefreshTooltip => 'Refresh settings';

  @override
  String get settingsErrorDismissTooltip => 'Close';

  @override
  String settingsErrorLoadFailed(Object detail) {
    return 'Failed to load settings: $detail';
  }

  @override
  String settingsErrorSaveBasicFailed(Object detail) {
    return 'Failed to save business info: $detail';
  }

  @override
  String settingsErrorSaveNetworkFailed(Object detail) {
    return 'Failed to save network settings: $detail';
  }

  @override
  String settingsErrorSavePrinterFailed(Object detail) {
    return 'Failed to save printer settings: $detail';
  }

  @override
  String get settingsBusinessInfoTitle => 'Store profile';

  @override
  String get settingsBusinessInfoSubtitle =>
      'These details appear on the customer display and receipts';

  @override
  String get settingsBusinessNameLabel => 'Store name';

  @override
  String get settingsBusinessCodeLabel => 'Store code';

  @override
  String get settingsBusinessPhoneLabel => 'Contact phone';

  @override
  String get settingsBusinessAddressLabel => 'Store address';

  @override
  String get settingsBusinessHoursTitle => 'Business hours & seating';

  @override
  String get settingsBusinessHoursSubtitle =>
      'Managed in the back office store data';

  @override
  String get settingsBusinessHoursLabel => 'Business hours';

  @override
  String get settingsBusinessSeatsLabel => 'Seats';

  @override
  String get settingsLogoutButton => 'Sign out';

  @override
  String get settingsLogoutConfirmTitle => 'Sign out';

  @override
  String get settingsLogoutConfirmMessage =>
      'Are you sure you want to sign out?';

  @override
  String get settingsRoleSwitchTitle => 'Switch role';

  @override
  String settingsRoleSwitchMessage(Object role) {
    return 'Switch to \"$role\" and restart the app to load that interface?';
  }

  @override
  String settingsRoleSwitchSuccess(Object role) {
    return 'Switched to $role. Redirecting...';
  }

  @override
  String get settingsRoleSelectionTitle => 'Role selection';

  @override
  String get settingsRoleSelectionSubtitle =>
      'Choose the device role; it will restart and open the selected interface';

  @override
  String get settingsRoleSelectionDescription =>
      'Staff terminal handles checkout and management; customer display shows products and ordering.';

  @override
  String get settingsCashPaymentTitle => 'Cash payment';

  @override
  String get settingsCashPaymentSubtitle =>
      'Check the cash machine to enable or verify cash payments';

  @override
  String get settingsCashStatusLabel => 'Current status';

  @override
  String get settingsCashEnabled => 'Enabled';

  @override
  String get settingsCashDisabled => 'Disabled';

  @override
  String get settingsCashNotSupported =>
      'Not authorized or cash payments unsupported';

  @override
  String settingsCashLastCheckFailed(Object detail) {
    return 'Last check failed: $detail';
  }

  @override
  String get settingsCashChecking => 'Checking…';

  @override
  String get settingsCashCheckNow => 'Check now';

  @override
  String get settingsCashSkipOnce => 'Skip for now';

  @override
  String get settingsPosNetworkTitle => 'POS terminal network';

  @override
  String get settingsPosNetworkSubtitle =>
      'Keep the terminal and card reader on the same network';

  @override
  String get settingsPosIpLabel => 'Terminal IP';

  @override
  String get settingsPosPortLabel => 'Terminal port';

  @override
  String get settingsPrinterConfigTitle => 'Printer configuration';

  @override
  String get settingsPrinterConfigSubtitle =>
      'Manage receipts, labels, and kitchen printing';

  @override
  String get settingsPrinterEmpty =>
      'No printers configured yet. Add one in the back office.';

  @override
  String get settingsMachineInfoTitle => 'Device identifiers';

  @override
  String get settingsMachineInfoSubtitle =>
      'Active terminal and activation details';

  @override
  String get settingsMachineCodeLabel => 'Machine code';

  @override
  String get settingsStationCodeLabel => 'Station code';

  @override
  String get settingsAuthorizedShopLabel => 'Authorized shop code';

  @override
  String get settingsLanguageFeatureTitle => 'Languages & features';

  @override
  String get settingsLanguageFeatureSubtitle =>
      'Display languages and features from store authorization';

  @override
  String get settingsSupportedLanguagesLabel => 'Supported languages';

  @override
  String get settingsSupportedLanguagesEmpty => 'Not configured';

  @override
  String get settingsFeatureOnlineCall => 'Online call';

  @override
  String get settingsFeatureTaxSystem => 'Tax system';

  @override
  String get settingsFeatureDynamicCode => 'Dynamic ticket';

  @override
  String get settingsFeatureMultiplayer => 'Multi-terminal collaboration';

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
  String get settingsValueNotSet => 'Not set';

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

  @override
  String get settingsPrinterReceiptTicket => 'Receipt';

  @override
  String get settingsPrinterReceiptLabel => 'Label';

  @override
  String get settingsPrinterLabelSizeTitle => 'Label size';

  @override
  String get settingsPrinterLabelSizeNone => 'Not set';

  @override
  String get settingsPrinterDefaultTag => 'Default';

  @override
  String get settingsPrinterTypeKitchen => 'Kitchen printing';

  @override
  String get settingsPrinterTypeCenter => 'Central printing';

  @override
  String get settingsPrinterTypeFront => 'Front desk printing';

  @override
  String settingsPrinterTypeUnknown(Object type) {
    return 'Printer type $type';
  }

  @override
  String get settingsPrinterEditIpTitle => 'Edit printer IP';

  @override
  String get settingsPrinterEditIpLabel => 'Printer IP address';

  @override
  String get settingsPrinterEditPortTitle => 'Edit printer port';

  @override
  String get settingsPrinterEditPortLabel => 'Printer port';

  @override
  String get settingsPrinterIpTitle => 'Printer IP';

  @override
  String get settingsPrinterPortTitle => 'Printer port';

  @override
  String get settingsPrinterToggleContinuous => 'Continuous printing';

  @override
  String get settingsPrinterToggleOption => 'Print optional fields';

  @override
  String get settingsPrinterToggleDirection => 'Reverse printing';

  @override
  String get entryPeerDisconnectedTitle => 'Customer display disconnected';

  @override
  String get entryPeerDisconnectedMessage =>
      'Search again and try to reconnect to the customer display?';

  @override
  String get entryPeerReconnect => 'Reconnect';

  @override
  String get entryPeerConnectDialogTitle => 'Connect customer display';

  @override
  String get entryPeerSearchingCustomer =>
      'Searching for nearby customer display…';

  @override
  String get entryHistoryOrders => 'Order history';

  @override
  String get entryDatePattern => 'MMM d, y · EEEE';

  @override
  String get peerStatusConnectedPrefix => 'Connected:';

  @override
  String get peerStatusDisconnectedPrefix => 'Not connected:';

  @override
  String get peerStatusErrorPrefix => 'Connection error:';

  @override
  String get peerStatusIdle => 'Not connected yet';

  @override
  String get peerSearchInProgress => 'Searching…';

  @override
  String get peerSearchRestart => 'Restart search';

  @override
  String get peerActionDone => 'Done';

  @override
  String get peerActionClose => 'Close';

  @override
  String get peerLabelCustomer => 'Customer display';

  @override
  String get peerLabelStaff => 'Staff terminal';

  @override
  String get commonUnknownError => 'Unknown error';

  @override
  String get customerDisconnectTitle => 'Connection lost';

  @override
  String get customerDisconnectMessage =>
      'Connection to the staff terminal was lost. Please reconnect.';

  @override
  String get customerReconnect => 'Reconnect';

  @override
  String get customerLater => 'Later';

  @override
  String get customerConnectDialogTitle => 'Connect staff terminal';

  @override
  String get customerPeerSearchingStaff => 'Searching for staff terminal…';

  @override
  String get customerGreeting => 'Welcome';

  @override
  String get customerLabel => 'Customer display';

  @override
  String get optionGroupMultiple => 'Multiple';

  @override
  String get optionGroupSingle => 'Single';

  @override
  String get optionGroupMinPrefix => 'Min ';

  @override
  String get optionGroupMaxPrefix => 'Max ';

  @override
  String get optionGroupNoOptions => 'No options';

  @override
  String get optionGroupSelected => 'Selected';

  @override
  String get optionGroupNotSelected => 'Not selected';

  @override
  String get cashMachineTitle => 'Cash machine check';

  @override
  String get cashMachineCheckingMessage =>
      'Checking the cash machine, please wait…';

  @override
  String get cashMachineSuccessMessage =>
      'Cash machine is ready for cash payments.';

  @override
  String get cashMachineFailureMessage =>
      'Check failed. Please verify the device connection.';

  @override
  String get cashMachineStepsChecking =>
      'Steps: Check status → Open → Start receive → Read amount → End';

  @override
  String get cashMachineStepsFailure =>
      'Flow: Check status → Open cash machine → Start Deposit → Deposit Amount → End Deposit';

  @override
  String get cashMachineSkip => 'Skip';

  @override
  String get cashMachineRetry => 'Retry';

  @override
  String get cashMachineDone => 'Done';

  @override
  String get cashMachineClose => 'Close';

  @override
  String get suspendedOrdersTitle => 'Suspended orders';

  @override
  String get suspendedOrdersSearchHint => 'Search by ID or product name';

  @override
  String get suspendedOrdersEmpty => 'No suspended orders';

  @override
  String get suspendedOrdersItemCountPrefix => 'Items: ';

  @override
  String get suspendedOrdersItemCountSuffix => '';

  @override
  String get suspendedOrdersResume => 'Resume';

  @override
  String get suspendedOrdersDatePattern => 'MM-dd HH:mm';

  @override
  String get posClearCartTitle => 'Clear cart';

  @override
  String get posClearCartMessage => 'Are you sure you want to clear the cart?';

  @override
  String get posSuspendTitle => 'Suspend order';

  @override
  String get posSuspendMessage => 'Suspend the current order?';

  @override
  String get posPushProductToCustomerTooltip => 'Send to customer display';

  @override
  String get posClearCustomerDisplayTooltip => 'Clear customer display';

  @override
  String get posBroadcastCategoriesTooltip => 'Broadcast categories';

  @override
  String get posSearchProductHint => 'Search products...';

  @override
  String get discountInputTitle => 'Enter discount amount';

  @override
  String get discountConfirm => 'Confirm';

  @override
  String get discountKeyClear => 'Clear';

  @override
  String get discountKeyDelete => 'Delete';

  @override
  String get posOrderNumberLabel => 'Order #:';

  @override
  String get posPushCartTooltip => 'Send cart to customer display';

  @override
  String get posOrderModeDineIn => 'Dine in';

  @override
  String get posOrderModeTakeout => 'Takeout';

  @override
  String get posCartEmptyMessage =>
      'Cart is empty\nPlease select items from the left';

  @override
  String get posSubtotalLabel => 'Subtotal';

  @override
  String get posDiscountLabel => 'Discount';

  @override
  String get posTotalDueLabel => 'Total due';

  @override
  String get posSuspendButton => 'Suspend';

  @override
  String get posDiscountButton => 'Discount';

  @override
  String get posClearButton => 'Clear';

  @override
  String get posCheckoutButton => 'Checkout';

  @override
  String get posOptionGroupCurrentPrefix => 'Current ';

  @override
  String get posOptionSendGroupTooltip => 'Send this group to customer';

  @override
  String get posOptionSendAllTooltip => 'Send current options to customer';

  @override
  String get posOptionMaxReachedTitle => 'Max selections reached';

  @override
  String get posOptionMaxReachedMessageSuffix =>
      ' has reached the maximum selections';

  @override
  String get posOptionMaxReachedOk => 'Got it';

  @override
  String get posOptionAddConfirm => 'Add to cart';

  @override
  String get posOptionUpdate => 'Update';

  @override
  String get posOptionMissingTitle => 'Missing required options';

  @override
  String get posOptionMissingOk => 'OK';

  @override
  String get paymentSelectionTitle => 'Select payment method';

  @override
  String get paymentSelectionPushTooltip =>
      'Send payment options to customer display';

  @override
  String get paymentGroupCashTitle => 'Cash';

  @override
  String get paymentGroupCashSubtitle => 'Pay with cash';

  @override
  String get paymentGroupQrTitle => 'QR payment';

  @override
  String get paymentGroupCardTitle => 'Credit/Debit card';

  @override
  String get paymentGroupCardShort => 'Card';

  @override
  String get paymentGroupTransitTitle => 'Transit/IC & eMoney';

  @override
  String get paymentGroupTransitShort => 'eMoney';

  @override
  String get paymentSelectionNotConfigured => 'Not configured';

  @override
  String get orderHistoryTitle => 'Order history';

  @override
  String get orderHistoryRefreshTooltip => 'Refresh';

  @override
  String get orderHistorySearchHint => 'Search by ID or product name';

  @override
  String get orderHistoryEmpty => 'No order history';

  @override
  String get orderHistoryItemCountPrefix => 'Items: ';

  @override
  String get orderHistoryItemCountSuffix => '';

  @override
  String get orderHistoryPaid => 'Paid';

  @override
  String get orderHistoryUnpaid => 'Unpaid';

  @override
  String get orderHistoryDatePatternShort => 'MM-dd HH:mm';

  @override
  String get orderHistoryDatePatternLong => 'yyyy-MM-dd HH:mm:ss';

  @override
  String get orderHistoryDetailsTitle => 'Order details';

  @override
  String get orderHistoryCloseTooltip => 'Close';

  @override
  String get orderHistoryDetailOrderIdLabel => 'Order ID';

  @override
  String get orderHistoryDetailTimeLabel => 'Time';

  @override
  String get orderHistoryDetailStatusLabel => 'Status';

  @override
  String get orderHistoryDetailPayMethodLabel => 'Payment method';

  @override
  String get orderHistoryDetailAmountLabel => 'Amount';

  @override
  String get orderHistoryDetailModeLabel => 'Mode';

  @override
  String get orderHistoryDetailItemCountLabel => 'Items';

  @override
  String get orderHistoryDetailProductsTitle => 'Products';

  @override
  String get orderHistoryPayMethodUnknown => 'Unknown';

  @override
  String get orderHistoryReorder => 'Reorder';

  @override
  String get orderHistoryPrintReceipt => 'Print receipt';

  @override
  String get orderHistoryPrintKitchen => 'Print kitchen ticket';

  @override
  String get cancelDialogLoadingTitle => 'Canceling';

  @override
  String get cancelDialogLoadingMessage =>
      'Sending cancel request to terminal…';

  @override
  String get cancelDialogSuccessTitle => 'Canceled';

  @override
  String get cancelDialogFailureTitle => 'Cancel failed';

  @override
  String get cancelDialogSuccessMessage => 'Payment canceled';

  @override
  String get cancelDialogFailureMessage =>
      'Cancel failed. Please try again later.';

  @override
  String get cancelDialogDone => 'Done';

  @override
  String get cancelDialogConfirm => 'Confirm';

  @override
  String get cashAmountMatched => 'Amount matches order total';

  @override
  String get cashAmountChangePrefix => 'Change due ';

  @override
  String get cashAmountShortPrefix => 'Remaining ';

  @override
  String get cashAmountConfirmedLabel => 'Confirmed cash amount';

  @override
  String get cashAmountDetectingLabel => 'Detecting cash amount';

  @override
  String get cashAmountExpectedPrefix => 'Order total: ';

  @override
  String get paymentOrderIdLabel => 'Order ID';

  @override
  String get paymentChannelLabel => 'Payment method';

  @override
  String get loginActivateTitle => 'Device activation';

  @override
  String get loginMachineCodeLabel => 'Machine code';

  @override
  String get loginActivateButton => 'Activate and continue';

  @override
  String activationFailedMessage(Object detail) {
    return 'Activation failed: $detail';
  }

  @override
  String get splashInitializing => 'Initializing...';

  @override
  String splashActivationFailedMessage(Object status, Object detail) {
    return 'Activation failed ($status): $detail';
  }

  @override
  String splashLoadFailedMessage(Object detail) {
    return 'Load failed: $detail';
  }

  @override
  String get splashPossibleCauses =>
      'Possible causes: temporary network/server 502, version mismatch, or invalid machine code';

  @override
  String get splashRetry => 'Retry';

  @override
  String get splashReactivate => 'Re-activate';

  @override
  String get commonNetworkLabel => 'Network';

  @override
  String get commonUnitPriceLabel => 'Unit price';

  @override
  String customerUnknownMessage(Object type) {
    return 'Unknown message received: $type';
  }

  @override
  String customerOrderNumberTitle(Object orderNumber) {
    return 'Order #$orderNumber';
  }

  @override
  String customerTotalDueWithAmount(Object amount) {
    return 'Total due ¥$amount';
  }

  @override
  String get customerPaymentChoiceTapToSelect => 'Tap to select';

  @override
  String get customerPaymentChoiceUnavailable => 'Unavailable';

  @override
  String get customerStatusConnectedTitle => 'Connected to staff terminal';

  @override
  String customerStatusSyncing(Object name) {
    return 'Syncing: $name';
  }

  @override
  String get customerStatusSearchingDescription =>
      'Please make sure the staff terminal is open and nearby.';

  @override
  String get customerStatusErrorTitle => 'Connection issue';

  @override
  String get customerStatusErrorDescription =>
      'Please retry or check the network.';

  @override
  String get customerStatusIdleDescription =>
      'Tap \"Connect staff terminal\" above to start pairing.';

  @override
  String get posToastPeerSyncDisabled => 'Customer sync is disabled';

  @override
  String get posToastPeerNotConnected =>
      'Customer display not connected. Push failed.';

  @override
  String get posToastPushedToCustomer => 'Sent to customer display';

  @override
  String get posToastPushedConfigToCustomer =>
      'Sent current configuration to customer display';

  @override
  String get posToastPushedOptionGroupToCustomer =>
      'Sent option group to customer display';

  @override
  String get posToastCartEmptyCannotPush => 'Cart is empty. Unable to push.';

  @override
  String get posToastCartSentToCustomer => 'Sent cart to customer display';

  @override
  String get posToastClearedCustomerDisplay => 'Cleared customer display';

  @override
  String get posToastLocalOrderSaveFailed => 'Failed to save local order';

  @override
  String get posToastOrderSubmitFailed => 'Order submission failed';

  @override
  String get posToastNoPayableOrder => 'No payable order available';

  @override
  String get orderHistoryLoadFailed => 'Failed to load orders';

  @override
  String get customerOptionsBasePricePrefix => 'Base price ';

  @override
  String get customerOptionsSelectedTitle => 'Selected options';

  @override
  String get customerOptionsTotalLabel => 'Current total';
}
