// OPOS "State" Property Constants
const int OposSClosed = 1;
const int OposSIdle = 2;
const int OposSBusy = 3;
const int OposSError = 4;

// OPOS "ResultCode" Property Constants
const int OPOSERREXT = 200;
const int OposSuccess = 0;
const int OposEClosed = 101;
const int OposEClaimed = 102;
const int OposENotclaimed = 103;
const int OposENoservice = 104;
const int OposEDisabled = 105;
const int OposEIllegal = 106;
const int OposENohardware = 107;
const int OposEOffline = 108;
const int OposENoexist = 109;
const int OposEExists = 110;
const int OposEFailure = 111;
const int OposETimeout = 112;
const int OposEBusy = 113;
const int OposEExtended = 114;

// OPOS "OpenResult" Property Constants
const int Oposopenerr = 300;
const int OposOrAlreadyopen = 301;
const int OposOrRegbadname = 302;
const int OposOrRegprogid = 303;
const int OposOrCreate = 304;
const int OposOrBadif = 305;
const int OposOrFailedopen = 306;
const int OposOrBadversion = 307;

const int Oposopenerrso = 400;
const int OposOrsNoport = 401;
const int OposOrsNotsupported = 402;
const int OposOrsConfig = 403;
const int OposOrsSpecific = 450;

// OPOS "BinaryConversion" Property Constants
const int OposBcNone = 0;
const int OposBcNibble = 1;
const int OposBcDecimal = 2;

// "CheckHealth" Method: "Level" Parameter Constants
const int OposChInternal = 1;
const int OposChExternal = 2;
const int OposChInteractive = 3;

// OPOS "CapPowerReporting", "PowerState", "PowerNotify" Property Constants
const int OposPrNone = 0;
const int OposPrStandard = 1;
const int OposPrAdvanced = 2;
const int OposPnDisabled = 0;
const int OposPnEnabled = 1;
const int OposPsUnknown = 2000;
const int OposPsOnline = 2001;
const int OposPsOff = 2002;
const int OposPsOffline = 2003;
const int OposPsOffOffline = 2004;

// "ErrorEvent" Event: "ErrorLocus" Parameter Constants
const int OposElOutput = 1;
const int OposElInput = 2;
const int OposElInputData = 3;

// "ErrorEvent" Event: "ErrorResponse" Constants
const int OposErRetry = 11;
const int OposErClear = 12;
const int OposErContinueinput = 13;

// "StatusUpdateEvent" Event: Common "Status" Constants
const int OposSuePowerOnline = 2001;
const int OposSuePowerOff = 2002;
const int OposSuePowerOffline = 2003;
const int OposSuePowerOffOffline = 2004;

// General Constants
const int OposForever = -1;

// Cash Changer specific constants
const int ChanStatusOk = 0; // DeviceStatus, FullStatus
const int ChanStatusEmpty = 11; // DeviceStatus, StatusUpdateEvent

// "DeviceStatus" and "FullStatus" Property Constants
// "StatusUpdateEvent" Event Constants
const int ChanStatusNearempty = 12; // DeviceStatus, StatusUpdateEvent
const int ChanStatusEmptyok = 13; // StatusUpdateEvent

const int ChanStatusFull = 21; // FullStatus, StatusUpdateEvent
const int ChanStatusNearfull = 22; // FullStatus, StatusUpdateEvent
const int ChanStatusFullok = 23; // StatusUpdateEvent

const int ChanStatusJam = 31; // DeviceStatus, StatusUpdateEvent
const int ChanStatusJamok = 32; // StatusUpdateEvent

const int ChanStatusAsync = 91; // StatusUpdateEvent

// "DepositStatus" Property Constants
const int ChanStatusDepositStart = 1;
const int ChanStatusDepositEnd = 2;
const int ChanStatusDepositNone = 3;
const int ChanStatusDepositCount = 4;
const int ChanStatusDepositJam = 5;

// "EndDeposit" Property Constants
const int ChanDepositChange = 1;
const int ChanDepositNochange = 2;
const int ChanDepositrepay = 3;

// "PauseDeposit" Property Constants
const int ChanDepositPause = 11;
const int ChanDepositRestart = 12;

// "ResultCodeExtended" Property Constants for Cash Changer
const int OposEchanOverdispense = 201;




// "ResultCodeExtended" Property Constants for Cash Changer
const int OPOS_ECHAN_OVERDISPENSE = 1 + OPOSERREXT;
const int OPOS_ECHAN_TOTALOVER = 2 + OPOSERREXT;
const int OPOS_ECHAN_CHANGEERROR = 3 + OPOSERREXT;
const int OPOS_ECHAN_OVER = 4 + OPOSERREXT;
const int OPOS_ECHAN_IFERROR = 5 + OPOSERREXT;
const int OPOS_ECHAN_SETERROR = 6 + OPOSERREXT;
const int OPOS_ECHAN_ERROR = 7 + OPOSERREXT;
const int OPOS_ECHAN_CHARGING = 8 + OPOSERREXT;
const int OPOS_ECHAN_NEAREMPTY = 9 + OPOSERREXT;
const int OPOS_ECHAN_EMPTY = 10 + OPOSERREXT;
const int OPOS_ECHAN_NEARFULL = 11 + OPOSERREXT;
const int OPOS_ECHAN_FULL = 12 + OPOSERREXT;
const int OPOS_ECHAN_OVERFLOW = 13 + OPOSERREXT;
const int OPOS_ECHAN_REJECT = 14 + OPOSERREXT;
const int OPOS_ECHAN_BUSY = 15 + OPOSERREXT;
const int OPOS_ECHAN_ASYNCBUSY = 16 + OPOSERREXT;
const int OPOS_ECHAN_CASSETTEWAIT = 17 + OPOSERREXT;
const int OPOS_ECHAN_COLLECTWAIT = 18 + OPOSERREXT;
const int OPOS_ECHAN_COUNTERROR = 19 + OPOSERREXT;
const int OPOS_ECHAN_AMOUNTERROR = 20 + OPOSERREXT;
const int OPOS_ECHAN_IMPOSSIBLE = 21 + OPOSERREXT;
const int OPOS_ECHAN_CANNOTPAY = 22 + OPOSERREXT;
const int OPOS_ECHAN_NOTSTORE = 23 + OPOSERREXT;
const int OPOS_ECHAN_NEAUTRAL = 24 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT = 25 + OPOSERREXT;
const int OPOS_ECHAN_PAUSEDEPOSIT = 26 + OPOSERREXT;
const int OPOS_ECHAN_UNMATCH = 27 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_ELSE_BILL = 28 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_ELSE_COIN = 29 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_MOVE_BILL = 30 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_MOVE_COIN = 31 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_ERR_BILL = 32 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_ERR_COIN = 33 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_RJ_BILL = 34 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_RJ_COIN = 35 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_CAS_BILL = 36 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_OVF_COIN = 37 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_SET_BILL = 38 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_SET_COIN = 39 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_RESET_BILL = 40 + OPOSERREXT;
const int OPOS_ECHAN_DEPOSIT_RESET_COIN = 41 + OPOSERREXT;

// DirectIO Method Constants
const int CHAN_DI_RESET = 1;
const int CHAN_DI_MEMREAD = 2;
const int CHAN_DI_MEMCLEAR = 3;
const int CHAN_DI_CHGMODE = 4;
const int CHAN_DI_SSWSET = 5;
const int CHAN_DI_TIMESET = 6;
const int CHAN_DI_ENQ = 7;
const int CHAN_DI_STRING = 8;
const int CHAN_DI_COLLECT = 9;
const int CHAN_DI_STATUSREAD = 10;
const int CHAN_DI_SUPPLYCOUNTS = 11;
const int CHAN_DI_SEISA = 12;
const int CHAN_DI_DEPOSITDATAREAD = 13;
const int CHAN_DI_BEGINDEPOSIT = 14;
const int CHAN_DI_ENDDEPOSIT = 15;
const int CHAN_DI_PAUSEDEPOSIT = 16;
const int CHAN_DI_RESTARTDEPOSIT = 17;
const int CHAN_DI_DEPOSITMODE = 18;
const int CHAN_DI_COUNTCLR = 19;
const int CHAN_DI_GETLOG = 20;
const int CHAN_DI_OPENDRAWER = 21;
const int CHAN_DI_CHILDLOCK = 22;
const int CHAN_DI_SUPPLY = 26;
const int CHAN_DI_BEGINDEPOSITOUTSIDE = 27;
const int CHAN_DI_DISPENSECHANGEOUTSIDE = 28;
const int CHAN_DI_DISPENSECASHOUTSIDE = 29;
const int CHAN_DI_BEGINCASHRETURN = 30;
const int CHAN_DI_ERRGUIDANCE = 101;

// DirectIO Event Constants
const int CHAN_DIEVT_CASSETTEWAIT = 1;
const int CHAN_DIEVT_CHARGING = 2;
const int CHAN_DIEVT_DEPOSITERROR = 3;
const int CHAN_DIEVT_DEPOSITRJ = 4;
const int CHAN_DIEVT_DEPOSITCASSETTEFULL = 5;
const int CHAN_DIEVT_DEPOSITSETERROR = 6;
const int CHAN_DIEVT_PULLOUT = 7;
const int CHAN_DIEVT_DEPOSITREADY = 8;

// OpenResult Constants
const int OPOS_ORS_SPECIFIC = 450;
const int OPOS_ORS_EVENTCLASS = OPOS_ORS_SPECIFIC + 1;
const int OPOS_ORS_COCREATE = OPOS_ORS_SPECIFIC + 2;
const int OPOS_ORS_PORTCONTROL = OPOS_ORS_SPECIFIC + 3;
const int OPOS_ORS_EVENTTHREAD = OPOS_ORS_SPECIFIC + 4;
const int OPOS_ORS_SENSETHREAD = OPOS_ORS_SPECIFIC + 5;




