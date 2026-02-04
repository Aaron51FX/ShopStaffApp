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
  String get settingsTitle => '设置';

  @override
  String get settingsRefreshTooltip => '刷新设置';

  @override
  String get settingsErrorDismissTooltip => '关闭';

  @override
  String settingsErrorLoadFailed(Object detail) {
    return '加载设置失败: $detail';
  }

  @override
  String settingsErrorSaveBasicFailed(Object detail) {
    return '保存基础信息失败: $detail';
  }

  @override
  String settingsErrorSaveNetworkFailed(Object detail) {
    return '保存网络设置失败: $detail';
  }

  @override
  String settingsErrorSavePrinterFailed(Object detail) {
    return '保存打印机设置失败: $detail';
  }

  @override
  String get settingsBusinessInfoTitle => '店铺基本信息';

  @override
  String get settingsBusinessInfoSubtitle => '这些信息将展示在前台与票据上';

  @override
  String get settingsBusinessNameLabel => '店铺名称';

  @override
  String get settingsBusinessCodeLabel => '店铺编号';

  @override
  String get settingsBusinessPhoneLabel => '联系电话';

  @override
  String get settingsBusinessAddressLabel => '店铺地址';

  @override
  String get settingsBusinessHoursTitle => '营业时间 & 座位';

  @override
  String get settingsBusinessHoursSubtitle => '来自门店主数据，可在后台系统维护';

  @override
  String get settingsBusinessHoursLabel => '营业时间';

  @override
  String get settingsBusinessSeatsLabel => '座位数';

  @override
  String get settingsLogoutButton => '退出登录';

  @override
  String get settingsLogoutConfirmTitle => '注销';

  @override
  String get settingsLogoutConfirmMessage => '确认要注销吗？';

  @override
  String get settingsRoleSwitchTitle => '切换角色';

  @override
  String settingsRoleSwitchMessage(Object role) {
    return '切换到“$role”需要重启应用以加载对应界面，是否立即重启？';
  }

  @override
  String settingsRoleSwitchSuccess(Object role) {
    return '已切换为$role，即将跳转...';
  }

  @override
  String get settingsRoleSelectionTitle => '角色选择';

  @override
  String get settingsRoleSelectionSubtitle => '选择设备扮演的端，保存后会重启并进入对应界面';

  @override
  String get settingsRoleSelectionDescription => '店员端用于收银与管理；顾客端用于商品展示与下单。';

  @override
  String get settingsCashPaymentTitle => '现金支付';

  @override
  String get settingsCashPaymentSubtitle => '检测现金机以启用或验证现金支付能力';

  @override
  String get settingsCashStatusLabel => '当前状态';

  @override
  String get settingsCashEnabled => '已启用';

  @override
  String get settingsCashDisabled => '未启用';

  @override
  String get settingsCashNotSupported => '未授权或不支持现金支付';

  @override
  String settingsCashLastCheckFailed(Object detail) {
    return '最近一次检测失败: $detail';
  }

  @override
  String get settingsCashChecking => '检测中…';

  @override
  String get settingsCashCheckNow => '立即检测';

  @override
  String get settingsCashSkipOnce => '跳过本次';

  @override
  String get settingsPosNetworkTitle => 'POS终端网络';

  @override
  String get settingsPosNetworkSubtitle => '确保终端与刷卡设备保持在同一网络';

  @override
  String get settingsPosIpLabel => '终端 IP';

  @override
  String get settingsPosPortLabel => '终端端口';

  @override
  String get settingsPrinterConfigTitle => '打印机配置';

  @override
  String get settingsPrinterConfigSubtitle => '控制小票、标签及厨房打印';

  @override
  String get settingsPrinterEmpty => '暂无打印机配置，可在后台新增';

  @override
  String get settingsMachineInfoTitle => '设备标识';

  @override
  String get settingsMachineInfoSubtitle => '当前终端与激活信息';

  @override
  String get settingsMachineCodeLabel => '机器码';

  @override
  String get settingsStationCodeLabel => '工作站编码';

  @override
  String get settingsAuthorizedShopLabel => '授权门店号';

  @override
  String get settingsLanguageFeatureTitle => '语言与功能';

  @override
  String get settingsLanguageFeatureSubtitle => '根据门店授权调整显示语言与能力';

  @override
  String get settingsSupportedLanguagesLabel => '支持语言';

  @override
  String get settingsSupportedLanguagesEmpty => '未配置';

  @override
  String get settingsFeatureOnlineCall => '线上叫号';

  @override
  String get settingsFeatureTaxSystem => '税制';

  @override
  String get settingsFeatureDynamicCode => '动态取票';

  @override
  String get settingsFeatureMultiplayer => '多人协同';

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
  String get settingsValueNotSet => '未设置';

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
  String get settingsPrinterDefaultTag => '默认';

  @override
  String get settingsPrinterTypeKitchen => '厨房打印';

  @override
  String get settingsPrinterTypeCenter => '中心打印';

  @override
  String get settingsPrinterTypeFront => '前台打印';

  @override
  String settingsPrinterTypeUnknown(Object type) {
    return '打印类型 $type';
  }

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
  String get settingsPrinterToggleDirection => '反向打印';

  @override
  String get entryPeerDisconnectedTitle => '顾客端已断开';

  @override
  String get entryPeerDisconnectedMessage => '是否重新搜索并尝试连接顾客端？';

  @override
  String get entryPeerReconnect => '重新连接';

  @override
  String get entryPeerConnectDialogTitle => '连接顾客端';

  @override
  String get entryPeerSearchingCustomer => '正在搜索附近的顾客端…';

  @override
  String get entryHistoryOrders => '历史订单';

  @override
  String get entryDatePattern => 'y年M月d日 · EEEE';

  @override
  String get peerStatusConnectedPrefix => '已连接:';

  @override
  String get peerStatusDisconnectedPrefix => '未连接:';

  @override
  String get peerStatusErrorPrefix => '连接异常:';

  @override
  String get peerStatusIdle => '未开始连接';

  @override
  String get peerSearchInProgress => '搜索中…';

  @override
  String get peerSearchRestart => '重启搜索';

  @override
  String get peerActionDone => '完成';

  @override
  String get peerActionClose => '关闭';

  @override
  String get peerLabelCustomer => '顾客端';

  @override
  String get peerLabelStaff => '店员端';

  @override
  String get commonUnknownError => '未知错误';

  @override
  String get customerDisconnectTitle => '连接已断开';

  @override
  String get customerDisconnectMessage => '与店员端的连接已断开，请重新连接。';

  @override
  String get customerReconnect => '重新连接';

  @override
  String get customerLater => '稍后';

  @override
  String get customerConnectDialogTitle => '连接店员端';

  @override
  String get customerPeerSearchingStaff => '正在搜索店员端…';

  @override
  String get customerGreeting => '欢迎光临';

  @override
  String get customerLabel => '顾客端';

  @override
  String get optionGroupMultiple => '可多选';

  @override
  String get optionGroupSingle => '单选';

  @override
  String get optionGroupMinPrefix => '最少';

  @override
  String get optionGroupMaxPrefix => '最多';

  @override
  String get optionGroupNoOptions => '暂无选项';

  @override
  String get optionGroupSelected => '已选';

  @override
  String get optionGroupNotSelected => '未选';

  @override
  String get cashMachineTitle => '现金机检测';

  @override
  String get cashMachineCheckingMessage => '正在检测现金机，请稍候…';

  @override
  String get cashMachineSuccessMessage => '现金机工作正常，可以进行现金支付。';

  @override
  String get cashMachineFailureMessage => '检测失败，请检查设备连接。';

  @override
  String get cashMachineStepsChecking => '步骤: 检查状态 → 打开 → 开始接收 → 读取金额 → 结束';

  @override
  String get cashMachineStepsFailure =>
      '流程: 检查状态 → 打开现金机 → Start Deposit → Deposit Amount → End Deposit';

  @override
  String get cashMachineSkip => '跳过';

  @override
  String get cashMachineRetry => '重试';

  @override
  String get cashMachineDone => '完成';

  @override
  String get cashMachineClose => '关闭';

  @override
  String get suspendedOrdersTitle => '挂单列表';

  @override
  String get suspendedOrdersSearchHint => '搜索 按编号或商品名';

  @override
  String get suspendedOrdersEmpty => '暂无挂单';

  @override
  String get suspendedOrdersItemCountPrefix => '共';

  @override
  String get suspendedOrdersItemCountSuffix => '件';

  @override
  String get suspendedOrdersResume => '取单';

  @override
  String get suspendedOrdersDatePattern => 'MM-dd HH:mm';

  @override
  String get posClearCartTitle => '清空购物车';

  @override
  String get posClearCartMessage => '确认要清空购物车吗？';

  @override
  String get posSuspendTitle => '挂单';

  @override
  String get posSuspendMessage => '确认要挂单吗？';

  @override
  String get posPushProductToCustomerTooltip => '推送到顾客端';

  @override
  String get posClearCustomerDisplayTooltip => '清除顾客端展示';

  @override
  String get posBroadcastCategoriesTooltip => '推送分类到顾客端';

  @override
  String get posSearchProductHint => '搜索商品 ...';

  @override
  String get discountInputTitle => '输入折扣金额';

  @override
  String get discountConfirm => '确定';

  @override
  String get discountKeyClear => '清空';

  @override
  String get discountKeyDelete => '删除';

  @override
  String get posOrderNumberLabel => '订单号:';

  @override
  String get posPushCartTooltip => '推送购物车到顾客端';

  @override
  String get posOrderModeDineIn => '堂食';

  @override
  String get posOrderModeTakeout => '外带';

  @override
  String get posCartEmptyMessage => '购物车是空的\n请从左侧选择商品';

  @override
  String get posSubtotalLabel => '小计';

  @override
  String get posDiscountLabel => '折扣';

  @override
  String get posTotalDueLabel => '应付总额';

  @override
  String get posSuspendButton => '挂单';

  @override
  String get posDiscountButton => '折扣';

  @override
  String get posClearButton => '清空';

  @override
  String get posCheckoutButton => '结 账';

  @override
  String get posOptionGroupCurrentPrefix => '当前';

  @override
  String get posOptionSendGroupTooltip => '发送此分组给顾客';

  @override
  String get posOptionSendAllTooltip => '发送当前选项到顾客端';

  @override
  String get posOptionMaxReachedTitle => '已达到最大可选';

  @override
  String get posOptionMaxReachedMessageSuffix => ' 已达到最多可选数量';

  @override
  String get posOptionMaxReachedOk => '知道了';

  @override
  String get posOptionAddConfirm => '确认添加';

  @override
  String get posOptionUpdate => '更新';

  @override
  String get posOptionMissingTitle => '缺少必选项';

  @override
  String get posOptionMissingOk => '好的';

  @override
  String get paymentSelectionTitle => '选择支付方式';

  @override
  String get paymentSelectionPushTooltip => '推送支付方式到顾客端';

  @override
  String get paymentGroupCashTitle => '现金';

  @override
  String get paymentGroupCashSubtitle => '现金支付';

  @override
  String get paymentGroupQrTitle => '二维码支付';

  @override
  String get paymentGroupCardTitle => '信用卡/刷卡';

  @override
  String get paymentGroupCardShort => '信用卡';

  @override
  String get paymentGroupTransitTitle => '交通系/电子货币';

  @override
  String get paymentGroupTransitShort => '电子货币';

  @override
  String get paymentSelectionNotConfigured => '未配置';

  @override
  String get orderHistoryTitle => '历史订单';

  @override
  String get orderHistoryRefreshTooltip => '刷新';

  @override
  String get orderHistorySearchHint => '搜索 按编号或商品名';

  @override
  String get orderHistoryEmpty => '暂无历史订单';

  @override
  String get orderHistoryItemCountPrefix => '共';

  @override
  String get orderHistoryItemCountSuffix => '件';

  @override
  String get orderHistoryPaid => '已支付';

  @override
  String get orderHistoryUnpaid => '未支付';

  @override
  String get orderHistoryDatePatternShort => 'MM-dd HH:mm';

  @override
  String get orderHistoryDatePatternLong => 'yyyy-MM-dd HH:mm:ss';

  @override
  String get orderHistoryDetailsTitle => '订单详情';

  @override
  String get orderHistoryCloseTooltip => '关闭';

  @override
  String get orderHistoryDetailOrderIdLabel => '订单号';

  @override
  String get orderHistoryDetailTimeLabel => '时间';

  @override
  String get orderHistoryDetailStatusLabel => '状态';

  @override
  String get orderHistoryDetailPayMethodLabel => '支付方式';

  @override
  String get orderHistoryDetailAmountLabel => '金额';

  @override
  String get orderHistoryDetailModeLabel => '模式';

  @override
  String get orderHistoryDetailItemCountLabel => '商品数';

  @override
  String get orderHistoryDetailProductsTitle => '商品';

  @override
  String get orderHistoryPayMethodUnknown => '未知';

  @override
  String get orderHistoryReorder => '再次下单(取单)';

  @override
  String get orderHistoryPrintReceipt => '打印 receipt';

  @override
  String get orderHistoryPrintKitchen => '打印厨房票';

  @override
  String get cancelDialogLoadingTitle => '正在取消';

  @override
  String get cancelDialogLoadingMessage => '正在向终端发送取消指令…';

  @override
  String get cancelDialogSuccessTitle => '取消成功';

  @override
  String get cancelDialogFailureTitle => '取消失败';

  @override
  String get cancelDialogSuccessMessage => '支付已取消';

  @override
  String get cancelDialogFailureMessage => '取消失败，请稍后重试';

  @override
  String get cancelDialogDone => '完成';

  @override
  String get cancelDialogConfirm => '确定';

  @override
  String get cashAmountMatched => '金额已匹配订单金额';

  @override
  String get cashAmountChangePrefix => '需找零 ';

  @override
  String get cashAmountShortPrefix => '仍差 ';

  @override
  String get cashAmountConfirmedLabel => '已确认现金金额';

  @override
  String get cashAmountDetectingLabel => '识别中的现金金额';

  @override
  String get cashAmountExpectedPrefix => '订单金额：';

  @override
  String get paymentOrderIdLabel => '订单号';

  @override
  String get paymentChannelLabel => '选择方式';

  @override
  String get loginActivateTitle => '设备激活';

  @override
  String get loginMachineCodeLabel => '机器码 (Machine Code)';

  @override
  String get loginActivateButton => '激活并进入';

  @override
  String activationFailedMessage(Object detail) {
    return '激活失败: $detail';
  }

  @override
  String get splashInitializing => '正在初始化...';

  @override
  String splashActivationFailedMessage(Object status, Object detail) {
    return '激活失败($status): $detail';
  }

  @override
  String splashLoadFailedMessage(Object detail) {
    return '加载失败: $detail';
  }

  @override
  String get splashPossibleCauses => '可能原因: 临时网络/服务器 502, 版本号不匹配, 或机号无效';

  @override
  String get splashRetry => '重试';

  @override
  String get splashReactivate => '重新激活';

  @override
  String get commonNetworkLabel => '网络';

  @override
  String get commonUnitPriceLabel => '单价';

  @override
  String customerUnknownMessage(Object type) {
    return '收到未知消息: $type';
  }

  @override
  String customerOrderNumberTitle(Object orderNumber) {
    return '订单 #$orderNumber';
  }

  @override
  String customerTotalDueWithAmount(Object amount) {
    return '应付 ¥$amount';
  }

  @override
  String get customerPaymentChoiceTapToSelect => '点击选择';

  @override
  String get customerPaymentChoiceUnavailable => '暂不可用';

  @override
  String get customerStatusConnectedTitle => '已连接店员端';

  @override
  String customerStatusSyncing(Object name) {
    return '同步中: $name';
  }

  @override
  String get customerStatusSearchingDescription => '请确保店员端已打开连接且设备靠近。';

  @override
  String get customerStatusErrorTitle => '连接异常';

  @override
  String get customerStatusErrorDescription => '请重试或检查网络。';

  @override
  String get customerStatusIdleDescription => '点击上方“连接店员端”开始配对。';

  @override
  String get posToastPeerSyncDisabled => '顾客端同步已关闭';

  @override
  String get posToastPeerNotConnected => '顾客端未连接，推送失败';

  @override
  String get posToastPushedToCustomer => '已推送到顾客端';

  @override
  String get posToastPushedConfigToCustomer => '已推送当前配置到顾客端';

  @override
  String get posToastPushedOptionGroupToCustomer => '已推送分组选项给顾客';

  @override
  String get posToastCartEmptyCannotPush => '购物车为空，无法推送';

  @override
  String get posToastCartSentToCustomer => '已将购物车发送到顾客端';

  @override
  String get posToastClearedCustomerDisplay => '已清除顾客端展示';

  @override
  String get posToastLocalOrderSaveFailed => '本地订单保存失败';

  @override
  String get posToastOrderSubmitFailed => '下单失败';

  @override
  String get posToastNoPayableOrder => '当前没有可支付的订单';

  @override
  String get orderHistoryLoadFailed => '加载失败';

  @override
  String get customerOptionsBasePricePrefix => '基础价 ';

  @override
  String get customerOptionsSelectedTitle => '已选配料';

  @override
  String get customerOptionsTotalLabel => '当前总价';

  @override
  String paymentFlowStarted(Object channel) {
    return '支付流程启动（$channel）';
  }

  @override
  String get paymentStatusInitialized => '初始化';

  @override
  String get paymentStatusPending => '待处理';

  @override
  String get paymentStatusWaitingUser => '等待顾客操作';

  @override
  String get paymentStatusProcessing => '处理中';

  @override
  String get paymentStatusSuccess => '支付成功';

  @override
  String get paymentStatusFailure => '支付失败';

  @override
  String get paymentStatusCancelled => '支付已取消';

  @override
  String get paymentStatusNoUpdates => '暂无状态更新';

  @override
  String get paymentCardInitTerminal => '初始化信用卡终端';

  @override
  String get paymentCardSuccess => '信用卡支付成功';

  @override
  String get paymentCardFailure => '信用卡支付失败';

  @override
  String get paymentCardCancelled => '信用卡支付取消';

  @override
  String paymentCardCancelFailed(Object detail) {
    return '信用卡支付取消失败：$detail';
  }

  @override
  String paymentCardInitFailed(Object detail) {
    return '信用卡支付初始化失败：$detail';
  }

  @override
  String get paymentPosStreamClosed => 'POS终端连接已关闭';

  @override
  String get paymentQrWaitScan => '请将二维码对准扫描区域';

  @override
  String get paymentQrRequestBackend => '二维码已识别，正在请求后台…';

  @override
  String get paymentQrPosPrompt => '请按照POS终端提示完成支付';

  @override
  String get paymentQrSuccess => '二维码支付完成';

  @override
  String paymentQrFailure(Object detail) {
    return '二维码支付失败：$detail';
  }

  @override
  String get paymentQrCancelled => '操作员取消二维码支付';

  @override
  String get paymentQrConfigMissing => '缺少POS终端配置，无法完成扫码支付';

  @override
  String get paymentPosWaitingResponse => '等待终端响应';

  @override
  String get paymentPosProcessing => '终端处理中';

  @override
  String get paymentCashPrepare => '准备现金支付';

  @override
  String get paymentCashAwaitConfirm => '请核对投入金额，确认后点击“确认支付”';

  @override
  String get paymentCashConfirming => '正在通知后台…';

  @override
  String get paymentCashSuccess => '现金支付完成';

  @override
  String paymentCashFailure(Object detail) {
    return '现金支付失败：$detail';
  }

  @override
  String paymentCashConfirmFailed(Object detail) {
    return '确认现金支付失败：$detail';
  }

  @override
  String get paymentCashCancelled => '操作员取消现金支付';

  @override
  String get paymentCashStageIdle => '现金机已就绪';

  @override
  String get paymentCashStageChecking => '正在检测现金机…';

  @override
  String get paymentCashStageOpening => '正在打开现金机…';

  @override
  String get paymentCashStageAccepting => '等待顾客投入现金';

  @override
  String get paymentCashStageCounting => '正在确认投入金额…';

  @override
  String get paymentCashStageClosing => '正在结束现金操作…';

  @override
  String get paymentCashStageCompleted => '现金机操作完成';

  @override
  String get paymentCashStageNearFull => '现金机即将满，请清空现金箱';

  @override
  String get paymentCashStageFull => '现金机已满，请清空现金箱';

  @override
  String get paymentCashStageError => '现金机异常';

  @override
  String get paymentCashStageChange => '正在找零…';

  @override
  String get paymentCashStageChangeFailed => '找零失败';

  @override
  String paymentCashAmountCurrent(Object amount) {
    return '当前识别现金金额：¥$amount';
  }

  @override
  String paymentCashAmountFinal(Object amount) {
    return '已确认现金金额：¥$amount';
  }

  @override
  String get paymentSessionMissing => '支付会话不存在';

  @override
  String get paymentFlowEnded => '支付流程已结束';

  @override
  String get paymentFallbackCardConnecting => '正在连接终端…';

  @override
  String get paymentFallbackCardFollowPos => '请按照POS终端提示操作';

  @override
  String get paymentFallbackCardProcessing => '信用卡支付处理中';

  @override
  String get paymentFallbackCashPrepare => '请准备现金';

  @override
  String get paymentFallbackCashWaiting => '等待顾客投入现金';

  @override
  String get paymentFallbackCashProcessing => '现金支付处理中';

  @override
  String get paymentFallbackQrAlign => '请将二维码对准扫描区';

  @override
  String get paymentFallbackQrProcessing => '二维码支付处理中';

  @override
  String get paymentFallbackProcessing => '支付处理中';

  @override
  String get paymentInstructionCard => '请按照终端提示插卡、刷卡或挥卡，完成支付后不要立即拔卡。';

  @override
  String get paymentInstructionCash => '现金投入完成后，请等待机器找零并领取收据。';

  @override
  String get paymentInstructionQr => '请使用顾客手机的二维码对准扫描器，等待确认提示。';

  @override
  String get paymentInstructionDefault => '请按照屏幕或终端提示完成支付。';

  @override
  String get paymentErrorHintDevice => '设备异常：请检查POS终端或现金机连接。';

  @override
  String get paymentErrorHintConfig => '配置缺失：请检查终端IP/端口或支付参数设置。';

  @override
  String get paymentErrorHintNetwork => '网络异常：请检查网络连接后重试。';

  @override
  String get paymentErrorHintBackend => '后台异常：请稍后重试或切换支付方式。';

  @override
  String get paymentErrorHintCancelled => '已取消本次支付操作。';

  @override
  String get paymentRetryDevice => '重连设备';

  @override
  String get paymentRetryNetwork => '重试联网';

  @override
  String get paymentRetryDefault => '重试';

  @override
  String get paymentRetryRestart => '重新发起';

  @override
  String get paymentActionReturnPos => '返回POS';

  @override
  String get paymentActionDoneReturn => '完成并返回';

  @override
  String get paymentActionConfirm => '确认支付';

  @override
  String paymentActionConfirmAmount(Object amount) {
    return '确认支付 ¥$amount';
  }

  @override
  String get paymentActionConfirming => '正在确认…';

  @override
  String get paymentActionCancel => '取消支付';

  @override
  String get paymentActionCancelling => '正在取消…';

  @override
  String paymentErrorUnknown(Object detail) {
    return '发生未知错误：$detail';
  }
}
