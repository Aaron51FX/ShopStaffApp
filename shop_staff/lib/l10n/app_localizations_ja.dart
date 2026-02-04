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
  String get settingsTitle => '設定';

  @override
  String get settingsRefreshTooltip => '設定を更新';

  @override
  String get settingsErrorDismissTooltip => '閉じる';

  @override
  String settingsErrorLoadFailed(Object detail) {
    return '設定の読み込みに失敗しました: $detail';
  }

  @override
  String settingsErrorSaveBasicFailed(Object detail) {
    return '基本情報の保存に失敗しました: $detail';
  }

  @override
  String settingsErrorSaveNetworkFailed(Object detail) {
    return 'ネットワーク設定の保存に失敗しました: $detail';
  }

  @override
  String settingsErrorSavePrinterFailed(Object detail) {
    return 'プリンター設定の保存に失敗しました: $detail';
  }

  @override
  String get settingsBusinessInfoTitle => '店舗基本情報';

  @override
  String get settingsBusinessInfoSubtitle => 'これらの情報は顧客端とレシートに表示されます';

  @override
  String get settingsBusinessNameLabel => '店舗名';

  @override
  String get settingsBusinessCodeLabel => '店舗番号';

  @override
  String get settingsBusinessPhoneLabel => '連絡先電話';

  @override
  String get settingsBusinessAddressLabel => '店舗住所';

  @override
  String get settingsBusinessHoursTitle => '営業時間・席数';

  @override
  String get settingsBusinessHoursSubtitle => '店舗マスターデータで管理されます';

  @override
  String get settingsBusinessHoursLabel => '営業時間';

  @override
  String get settingsBusinessSeatsLabel => '席数';

  @override
  String get settingsLogoutButton => 'ログアウト';

  @override
  String get settingsLogoutConfirmTitle => 'ログアウト';

  @override
  String get settingsLogoutConfirmMessage => 'ログアウトしますか？';

  @override
  String get settingsRoleSwitchTitle => '役割の切り替え';

  @override
  String settingsRoleSwitchMessage(Object role) {
    return '「$role」に切り替えるにはアプリを再起動する必要があります。今すぐ再起動しますか？';
  }

  @override
  String settingsRoleSwitchSuccess(Object role) {
    return '「$role」に切り替えました。画面を移動します...';
  }

  @override
  String get settingsRoleSelectionTitle => '役割選択';

  @override
  String get settingsRoleSelectionSubtitle => '端末の役割を選択すると再起動して対象画面に切り替わります';

  @override
  String get settingsRoleSelectionDescription =>
      'スタッフ端末は会計・管理用、顧客端は商品表示と注文用です。';

  @override
  String get settingsCashPaymentTitle => '現金支払い';

  @override
  String get settingsCashPaymentSubtitle => '現金機を確認して現金支払いを有効化または検証します';

  @override
  String get settingsCashStatusLabel => '現在の状態';

  @override
  String get settingsCashEnabled => '有効';

  @override
  String get settingsCashDisabled => '無効';

  @override
  String get settingsCashNotSupported => '未認証または現金支払いが未対応';

  @override
  String settingsCashLastCheckFailed(Object detail) {
    return '直近の検査に失敗しました: $detail';
  }

  @override
  String get settingsCashChecking => '検査中…';

  @override
  String get settingsCashCheckNow => '今すぐ検査';

  @override
  String get settingsCashSkipOnce => '今回はスキップ';

  @override
  String get settingsPosNetworkTitle => 'POS端末ネットワーク';

  @override
  String get settingsPosNetworkSubtitle => '端末とカードリーダーを同一ネットワークに保ってください';

  @override
  String get settingsPosIpLabel => '端末IP';

  @override
  String get settingsPosPortLabel => '端末ポート';

  @override
  String get settingsPrinterConfigTitle => 'プリンター設定';

  @override
  String get settingsPrinterConfigSubtitle => 'レシート・ラベル・キッチン印刷を管理';

  @override
  String get settingsPrinterEmpty => 'プリンターが未設定です。管理画面で追加してください。';

  @override
  String get settingsMachineInfoTitle => '端末識別情報';

  @override
  String get settingsMachineInfoSubtitle => '現在の端末と有効化情報';

  @override
  String get settingsMachineCodeLabel => '機器コード';

  @override
  String get settingsStationCodeLabel => 'ワークステーションコード';

  @override
  String get settingsAuthorizedShopLabel => '許可された店舗コード';

  @override
  String get settingsLanguageFeatureTitle => '言語と機能';

  @override
  String get settingsLanguageFeatureSubtitle => '店舗権限に基づいて表示言語と機能を調整します';

  @override
  String get settingsSupportedLanguagesLabel => '対応言語';

  @override
  String get settingsSupportedLanguagesEmpty => '未設定';

  @override
  String get settingsFeatureOnlineCall => 'オンライン呼び出し';

  @override
  String get settingsFeatureTaxSystem => '税制';

  @override
  String get settingsFeatureDynamicCode => '動的発券';

  @override
  String get settingsFeatureMultiplayer => 'マルチ端末連携';

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
  String get settingsValueNotSet => '未設定';

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
  String get settingsPrinterDefaultTag => 'デフォルト';

  @override
  String get settingsPrinterTypeKitchen => '厨房印刷';

  @override
  String get settingsPrinterTypeCenter => 'センター印刷';

  @override
  String get settingsPrinterTypeFront => 'フロント印刷';

  @override
  String settingsPrinterTypeUnknown(Object type) {
    return '印刷タイプ $type';
  }

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
  String get settingsPrinterToggleDirection => '逆方向印刷';

  @override
  String get entryPeerDisconnectedTitle => '顧客端が切断されました';

  @override
  String get entryPeerDisconnectedMessage => '顧客端を再検索して再接続しますか？';

  @override
  String get entryPeerReconnect => '再接続';

  @override
  String get entryPeerConnectDialogTitle => '顧客端に接続';

  @override
  String get entryPeerSearchingCustomer => '近くの顧客端を検索中…';

  @override
  String get entryHistoryOrders => '履歴注文';

  @override
  String get entryDatePattern => 'y年M月d日 · EEEE';

  @override
  String get peerStatusConnectedPrefix => '接続済み:';

  @override
  String get peerStatusDisconnectedPrefix => '未接続:';

  @override
  String get peerStatusErrorPrefix => '接続エラー:';

  @override
  String get peerStatusIdle => '未接続';

  @override
  String get peerSearchInProgress => '検索中…';

  @override
  String get peerSearchRestart => '検索を再開';

  @override
  String get peerActionDone => '完了';

  @override
  String get peerActionClose => '閉じる';

  @override
  String get peerLabelCustomer => 'お客様端末';

  @override
  String get peerLabelStaff => 'スタッフ端末';

  @override
  String get commonUnknownError => '不明なエラー';

  @override
  String get customerDisconnectTitle => '接続が切断されました';

  @override
  String get customerDisconnectMessage => '店員端末との接続が切断されました。再接続してください。';

  @override
  String get customerReconnect => '再接続';

  @override
  String get customerLater => '後で';

  @override
  String get customerConnectDialogTitle => 'スタッフ端末に接続';

  @override
  String get customerPeerSearchingStaff => 'スタッフ端末を検索中…';

  @override
  String get customerGreeting => 'いらっしゃいませ';

  @override
  String get customerLabel => '顧客端';

  @override
  String get optionGroupMultiple => '複数選択';

  @override
  String get optionGroupSingle => '単一選択';

  @override
  String get optionGroupMinPrefix => '最少';

  @override
  String get optionGroupMaxPrefix => '最大';

  @override
  String get optionGroupNoOptions => 'オプションなし';

  @override
  String get optionGroupSelected => '選択済み';

  @override
  String get optionGroupNotSelected => '未選択';

  @override
  String get cashMachineTitle => '現金機チェック';

  @override
  String get cashMachineCheckingMessage => '現金機を確認しています。しばらくお待ちください…';

  @override
  String get cashMachineSuccessMessage => '現金機は正常です。現金支払いが可能です。';

  @override
  String get cashMachineFailureMessage => 'チェックに失敗しました。機器の接続を確認してください。';

  @override
  String get cashMachineStepsChecking => '手順: 状態確認 → 開く → 受け付け開始 → 金額読み取り → 終了';

  @override
  String get cashMachineStepsFailure =>
      'フロー: 状態確認 → 現金機を開く → Start Deposit → Deposit Amount → End Deposit';

  @override
  String get cashMachineSkip => 'スキップ';

  @override
  String get cashMachineRetry => '再試行';

  @override
  String get cashMachineDone => '完了';

  @override
  String get cashMachineClose => '閉じる';

  @override
  String get suspendedOrdersTitle => '保留注文';

  @override
  String get suspendedOrdersSearchHint => '番号または商品名で検索';

  @override
  String get suspendedOrdersEmpty => '保留注文はありません';

  @override
  String get suspendedOrdersItemCountPrefix => '合計';

  @override
  String get suspendedOrdersItemCountSuffix => '件';

  @override
  String get suspendedOrdersResume => '再開';

  @override
  String get suspendedOrdersDatePattern => 'MM-dd HH:mm';

  @override
  String get posClearCartTitle => 'カートを空にする';

  @override
  String get posClearCartMessage => 'カートを空にしますか？';

  @override
  String get posSuspendTitle => '注文を保留';

  @override
  String get posSuspendMessage => '現在の注文を保留しますか？';

  @override
  String get posPushProductToCustomerTooltip => '顧客端に送信';

  @override
  String get posClearCustomerDisplayTooltip => '顧客端表示をクリア';

  @override
  String get posBroadcastCategoriesTooltip => 'カテゴリを顧客端に送信';

  @override
  String get posSearchProductHint => '商品を検索 ...';

  @override
  String get discountInputTitle => '割引金額を入力';

  @override
  String get discountConfirm => '確定';

  @override
  String get discountKeyClear => 'クリア';

  @override
  String get discountKeyDelete => '削除';

  @override
  String get posOrderNumberLabel => '注文番号:';

  @override
  String get posPushCartTooltip => 'カートを顧客端に送信';

  @override
  String get posOrderModeDineIn => '店内';

  @override
  String get posOrderModeTakeout => '持ち帰り';

  @override
  String get posCartEmptyMessage => 'カートは空です\n左側から商品を選択してください';

  @override
  String get posSubtotalLabel => '小計';

  @override
  String get posDiscountLabel => '割引';

  @override
  String get posTotalDueLabel => '合計';

  @override
  String get posSuspendButton => '保留';

  @override
  String get posDiscountButton => '割引';

  @override
  String get posClearButton => 'クリア';

  @override
  String get posCheckoutButton => '会計';

  @override
  String get posOptionGroupCurrentPrefix => '現在';

  @override
  String get posOptionSendGroupTooltip => 'このグループを顧客に送信';

  @override
  String get posOptionSendAllTooltip => '現在のオプションを顧客端に送信';

  @override
  String get posOptionMaxReachedTitle => '最大数に達しました';

  @override
  String get posOptionMaxReachedMessageSuffix => ' の最大選択数に達しました';

  @override
  String get posOptionMaxReachedOk => '了解';

  @override
  String get posOptionAddConfirm => '追加';

  @override
  String get posOptionUpdate => '更新';

  @override
  String get posOptionMissingTitle => '必須項目が未選択';

  @override
  String get posOptionMissingOk => 'OK';

  @override
  String get paymentSelectionTitle => '支払い方法を選択';

  @override
  String get paymentSelectionPushTooltip => '支払い方法を顧客端に送信';

  @override
  String get paymentGroupCashTitle => '現金';

  @override
  String get paymentGroupCashSubtitle => '現金支払い';

  @override
  String get paymentGroupQrTitle => 'QR決済';

  @override
  String get paymentGroupCardTitle => 'クレジット/デビット';

  @override
  String get paymentGroupCardShort => 'カード';

  @override
  String get paymentGroupTransitTitle => '交通系/電子マネー';

  @override
  String get paymentGroupTransitShort => '電子マネー';

  @override
  String get paymentSelectionNotConfigured => '未設定';

  @override
  String get orderHistoryTitle => '履歴注文';

  @override
  String get orderHistoryRefreshTooltip => '更新';

  @override
  String get orderHistorySearchHint => '番号または商品名で検索';

  @override
  String get orderHistoryEmpty => '履歴注文はありません';

  @override
  String get orderHistoryItemCountPrefix => '合計';

  @override
  String get orderHistoryItemCountSuffix => '件';

  @override
  String get orderHistoryPaid => '支払済み';

  @override
  String get orderHistoryUnpaid => '未払い';

  @override
  String get orderHistoryDatePatternShort => 'MM-dd HH:mm';

  @override
  String get orderHistoryDatePatternLong => 'yyyy-MM-dd HH:mm:ss';

  @override
  String get orderHistoryDetailsTitle => '注文詳細';

  @override
  String get orderHistoryCloseTooltip => '閉じる';

  @override
  String get orderHistoryDetailOrderIdLabel => '注文番号';

  @override
  String get orderHistoryDetailTimeLabel => '時間';

  @override
  String get orderHistoryDetailStatusLabel => '状態';

  @override
  String get orderHistoryDetailPayMethodLabel => '支払い方法';

  @override
  String get orderHistoryDetailAmountLabel => '金額';

  @override
  String get orderHistoryDetailModeLabel => 'モード';

  @override
  String get orderHistoryDetailItemCountLabel => '商品数';

  @override
  String get orderHistoryDetailProductsTitle => '商品';

  @override
  String get orderHistoryPayMethodUnknown => '不明';

  @override
  String get orderHistoryReorder => '再注文';

  @override
  String get orderHistoryPrintReceipt => 'レシート印刷';

  @override
  String get orderHistoryPrintKitchen => 'キッチン伝票印刷';

  @override
  String get cancelDialogLoadingTitle => '取消中';

  @override
  String get cancelDialogLoadingMessage => '端末へ取消リクエストを送信中…';

  @override
  String get cancelDialogSuccessTitle => '取消完了';

  @override
  String get cancelDialogFailureTitle => '取消失敗';

  @override
  String get cancelDialogSuccessMessage => '支払いを取消しました';

  @override
  String get cancelDialogFailureMessage => '取消に失敗しました。時間をおいて再試行してください。';

  @override
  String get cancelDialogDone => '完了';

  @override
  String get cancelDialogConfirm => '確認';

  @override
  String get cashAmountMatched => '注文金額と一致しました';

  @override
  String get cashAmountChangePrefix => 'おつり ';

  @override
  String get cashAmountShortPrefix => '不足 ';

  @override
  String get cashAmountConfirmedLabel => '確定した現金金額';

  @override
  String get cashAmountDetectingLabel => '現金金額を認識中';

  @override
  String get cashAmountExpectedPrefix => '注文金額：';

  @override
  String get paymentOrderIdLabel => '注文番号';

  @override
  String get paymentChannelLabel => '選択方式';

  @override
  String get loginActivateTitle => '端末アクティベーション';

  @override
  String get loginMachineCodeLabel => '機器コード (Machine Code)';

  @override
  String get loginActivateButton => '有効化して続行';

  @override
  String activationFailedMessage(Object detail) {
    return 'アクティベーションに失敗しました: $detail';
  }

  @override
  String get splashInitializing => '初期化中...';

  @override
  String splashActivationFailedMessage(Object status, Object detail) {
    return 'アクティベーションに失敗しました($status): $detail';
  }

  @override
  String splashLoadFailedMessage(Object detail) {
    return '読み込みに失敗しました: $detail';
  }

  @override
  String get splashPossibleCauses =>
      '考えられる原因: 一時的なネットワーク/サーバー 502、バージョン不一致、または機器番号が無効';

  @override
  String get splashRetry => '再試行';

  @override
  String get splashReactivate => '再アクティベーション';

  @override
  String get commonNetworkLabel => 'ネットワーク';

  @override
  String get commonUnitPriceLabel => '単価';

  @override
  String customerUnknownMessage(Object type) {
    return '不明なメッセージを受信: $type';
  }

  @override
  String customerOrderNumberTitle(Object orderNumber) {
    return '注文 #$orderNumber';
  }

  @override
  String customerTotalDueWithAmount(Object amount) {
    return 'お会計 ¥$amount';
  }

  @override
  String get customerPaymentChoiceTapToSelect => 'タップして選択';

  @override
  String get customerPaymentChoiceUnavailable => '利用不可';

  @override
  String get customerStatusConnectedTitle => 'スタッフ端末に接続済み';

  @override
  String customerStatusSyncing(Object name) {
    return '同期中: $name';
  }

  @override
  String get customerStatusSearchingDescription =>
      'スタッフ端末が開いていて近くにあることを確認してください。';

  @override
  String get customerStatusErrorTitle => '接続エラー';

  @override
  String get customerStatusErrorDescription => '再試行するかネットワークを確認してください。';

  @override
  String get customerStatusIdleDescription =>
      '上の「スタッフ端末に接続」をタップしてペアリングを開始してください。';

  @override
  String get posToastPeerSyncDisabled => '顧客端同期が無効です';

  @override
  String get posToastPeerNotConnected => '顧客端が未接続のため送信できません';

  @override
  String get posToastPushedToCustomer => '顧客端に送信しました';

  @override
  String get posToastPushedConfigToCustomer => '現在の設定を顧客端に送信しました';

  @override
  String get posToastPushedOptionGroupToCustomer => 'オプショングループを顧客端に送信しました';

  @override
  String get posToastCartEmptyCannotPush => 'カートが空のため送信できません';

  @override
  String get posToastCartSentToCustomer => 'カートを顧客端に送信しました';

  @override
  String get posToastClearedCustomerDisplay => '顧客端表示をクリアしました';

  @override
  String get posToastLocalOrderSaveFailed => 'ローカル注文の保存に失敗しました';

  @override
  String get posToastOrderSubmitFailed => '注文送信に失敗しました';

  @override
  String get posToastNoPayableOrder => '支払い可能な注文がありません';

  @override
  String get orderHistoryLoadFailed => '注文履歴の読み込みに失敗しました';

  @override
  String get customerOptionsBasePricePrefix => '基本価格 ';

  @override
  String get customerOptionsSelectedTitle => '選択済みトッピング';

  @override
  String get customerOptionsTotalLabel => '現在合計';

  @override
  String paymentFlowStarted(Object channel) {
    return '決済フロー開始（$channel）';
  }

  @override
  String get paymentStatusInitialized => '初期化中';

  @override
  String get paymentStatusPending => '待機中';

  @override
  String get paymentStatusWaitingUser => 'お客様の操作待ち';

  @override
  String get paymentStatusProcessing => '処理中';

  @override
  String get paymentStatusSuccess => '支払い成功';

  @override
  String get paymentStatusFailure => '支払い失敗';

  @override
  String get paymentStatusCancelled => '支払いキャンセル';

  @override
  String get paymentStatusNoUpdates => 'ステータス更新なし';

  @override
  String get paymentCardInitTerminal => 'カード端末を初期化中';

  @override
  String get paymentCardSuccess => 'カード決済完了';

  @override
  String get paymentCardFailure => 'カード決済失敗';

  @override
  String get paymentCardCancelled => 'カード決済キャンセル';

  @override
  String paymentCardCancelFailed(Object detail) {
    return 'カード決済のキャンセルに失敗しました：$detail';
  }

  @override
  String paymentCardInitFailed(Object detail) {
    return 'カード決済の初期化に失敗しました：$detail';
  }

  @override
  String get paymentPosStreamClosed => 'POS端末の接続が切断されました';

  @override
  String get paymentQrWaitScan => 'QRコードをスキャナーに合わせてください';

  @override
  String get paymentQrRequestBackend => 'QR認識済み、バックエンドに問い合わせ中…';

  @override
  String get paymentQrPosPrompt => 'POS端末の案内に従って決済を完了してください';

  @override
  String get paymentQrSuccess => 'QR決済完了';

  @override
  String paymentQrFailure(Object detail) {
    return 'QR決済失敗：$detail';
  }

  @override
  String get paymentQrCancelled => 'QR決済キャンセル';

  @override
  String get paymentQrConfigMissing => 'POS端末設定が不足しています。QR決済を完了できません。';

  @override
  String get paymentPosWaitingResponse => '端末の応答待ち';

  @override
  String get paymentPosProcessing => '端末処理中';

  @override
  String get paymentCashPrepare => '現金決済の準備中';

  @override
  String get paymentCashAwaitConfirm => '投入金額を確認し「確認支払い」を押してください';

  @override
  String get paymentCashConfirming => 'バックエンドに通知中…';

  @override
  String get paymentCashSuccess => '現金決済完了';

  @override
  String paymentCashFailure(Object detail) {
    return '現金決済失敗：$detail';
  }

  @override
  String paymentCashConfirmFailed(Object detail) {
    return '現金確定に失敗しました：$detail';
  }

  @override
  String get paymentCashCancelled => '現金決済キャンセル';

  @override
  String get paymentCashStageIdle => '現金機は準備完了';

  @override
  String get paymentCashStageChecking => '現金機を検査中…';

  @override
  String get paymentCashStageOpening => '現金機を開いています…';

  @override
  String get paymentCashStageAccepting => '現金投入待ち';

  @override
  String get paymentCashStageCounting => '投入金額を確認中…';

  @override
  String get paymentCashStageClosing => '現金操作を終了中…';

  @override
  String get paymentCashStageCompleted => '現金機の操作が完了しました';

  @override
  String get paymentCashStageNearFull => '現金箱がもうすぐ満杯です。空にしてください';

  @override
  String get paymentCashStageFull => '現金箱が満杯です。空にしてください';

  @override
  String get paymentCashStageError => '現金機エラー';

  @override
  String get paymentCashStageChange => 'お釣り中…';

  @override
  String get paymentCashStageChangeFailed => 'お釣り失敗';

  @override
  String paymentCashAmountCurrent(Object amount) {
    return '現在認識された現金金額：¥$amount';
  }

  @override
  String paymentCashAmountFinal(Object amount) {
    return '確認済み現金金額：¥$amount';
  }

  @override
  String get paymentSessionMissing => '決済セッションが見つかりません';

  @override
  String get paymentFlowEnded => '決済フローが終了しました';

  @override
  String get paymentFallbackCardConnecting => '端末に接続中…';

  @override
  String get paymentFallbackCardFollowPos => 'POS端末の案内に従ってください';

  @override
  String get paymentFallbackCardProcessing => 'カード決済処理中';

  @override
  String get paymentFallbackCashPrepare => '現金をご準備ください';

  @override
  String get paymentFallbackCashWaiting => '現金投入待ち';

  @override
  String get paymentFallbackCashProcessing => '現金決済処理中';

  @override
  String get paymentFallbackQrAlign => 'QRコードをスキャナーに合わせてください';

  @override
  String get paymentFallbackQrProcessing => 'QR決済処理中';

  @override
  String get paymentFallbackProcessing => '決済処理中';

  @override
  String get paymentInstructionCard =>
      '端末の案内に従って挿入・スワイプ・タッチし、完了するまでカードを抜かないでください。';

  @override
  String get paymentInstructionCash => '現金投入後、お釣りを待ってレシートをお受け取りください。';

  @override
  String get paymentInstructionQr => 'お客様のQRコードをスキャナーに合わせてください。';

  @override
  String get paymentInstructionDefault => '画面または端末の案内に従って決済を完了してください。';

  @override
  String get paymentErrorHintDevice => '機器の問題：POS端末または現金機の接続を確認してください。';

  @override
  String get paymentErrorHintConfig => '設定不足：端末IP/ポートや決済設定を確認してください。';

  @override
  String get paymentErrorHintNetwork => 'ネットワークの問題：接続を確認して再試行してください。';

  @override
  String get paymentErrorHintBackend => 'バックエンドの問題：後でもう一度お試しください。';

  @override
  String get paymentErrorHintCancelled => 'この決済はキャンセルされました。';

  @override
  String get paymentRetryDevice => '機器再接続';

  @override
  String get paymentRetryNetwork => 'ネットワーク再試行';

  @override
  String get paymentRetryDefault => '再試行';

  @override
  String get paymentRetryRestart => '再開';

  @override
  String get paymentActionReturnPos => 'POSに戻る';

  @override
  String get paymentActionDoneReturn => '完了して戻る';

  @override
  String get paymentActionConfirm => '支払い確認';

  @override
  String paymentActionConfirmAmount(Object amount) {
    return '¥$amount を支払い確認';
  }

  @override
  String get paymentActionConfirming => '確認中…';

  @override
  String get paymentActionCancel => '支払い取消';

  @override
  String get paymentActionCancelling => '取消中…';

  @override
  String paymentErrorUnknown(Object detail) {
    return '不明なエラー：$detail';
  }
}
