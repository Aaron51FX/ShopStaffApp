#include "cash_changer_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/standard_message_codec.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <sstream>
#include "opos_all.h"
#include <locale>
//#include <thread>


namespace cash_changer {
static unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel = nullptr;
// static
void CashChangerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  channel =
      make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "cash_changer",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = make_unique<CashChangerPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, move(result));
      });

  registrar->AddPlugin(move(plugin));
}

// (已移除旧的 BStrToUtf8 辅助，避免未使用警告；如需可再添加 WinAPI 版本)

CashChangerPlugin::CashChangerPlugin() {

    cerr << "CashChangerPlugin construct" << endl;
    // 创建 COM 对象实例
    HRESULT hr = pCashChanger.CreateInstance(__uuidof(OPOSCashChanger));
    if (FAILED(hr)) {
        cerr << "创建 COM 实例失败" << endl;
        return;
    }
    // 初始化事件
    InitCashChangerEvents();
}

void CashChangerPlugin::InitCashChangerEvents () {
    cerr << "InitCashChangerEvents" << endl;
    
    HRESULT hr = pCashChanger->QueryInterface(IID_IConnectionPointContainer, (void**)&pCPC);

    if (SUCCEEDED(hr)) {
        
        hr = pCPC->FindConnectionPoint(DIID__IOPOSCashChangerEvents, &pCP);
        cerr << "FindConnectionPoint" << hr << endl;

        if (SUCCEEDED(hr)) {
            pHandler = new CashChangerEvents(); // 事件处理对象
            pHandler->setDelegate(this);
            
            assert(pHandler != nullptr);
            
            hr = pHandler->QueryInterface(DIID__IOPOSCashChangerEvents, (void**)&pEvents);
            if (SUCCEEDED(hr)) {
                // pHandler 实现了 _IOPOSCashChangerEvents 接口
                cerr << "pHandler 实现了 _IOPOSCashChangerEvents 接口" << hr << endl;
            } else {
                // pHandler 没有实现 _IOPOSCashChangerEvents 接口
                cerr << "pHandler 没有实现 _IOPOSCashChangerEvents 接口 failed" << hr << endl;
            }
            DWORD dwAdvise = 0;
            hr = pCP->Advise(pHandler, &dwAdvise);
            if (SUCCEEDED(hr)) {
                cerr << "Advise success: " << hr <<endl;
            } else {
                cerr << "Advise failed: " << hr << endl;
            }
        }
    }
}

CashChangerPlugin::~CashChangerPlugin() {
    cerr << "CashChangerPlugin destruct" << endl;

    // 释放 COM 对象
    if (pCashChanger) {
        pCashChanger->Release();
        pCashChanger = NULL;
    }

    // 释放事件连接点
    if (pCP) {
        pCP->Release();
        pCP = NULL;
    }

    // 释放连接点容器
    if (pCPC) {
        pCPC->Release();
        pCPC = NULL;
    }

    // 释放事件源
    if (pEvents) {
        pEvents->Release();
        pEvents = NULL;
    }


}

// Implements ICashChangerEventsDelegate
void CashChangerPlugin::DataEvent(long Status) {
    // if (isDepositAmount) {
    //     isDepositAmount = false;
    //     return;
    // }
    cerr << "------ CashChangerPlugin::DataEvent ------" << endl;
    cerr << "------ Status: " << Status << endl;
    long depositAmount = pCashChanger->DepositAmount;
    channel->InvokeMethod("DataEvent", std::make_unique<flutter::EncodableValue>(depositAmount));
}

void CashChangerPlugin::DirectIOEvent(long EventNumber, long *pData, BSTR *pString) {
    cerr << "------ CashChangerPlugin::DirectIOEvent ------" << endl;
    cerr << "------ EventNumber: " << EventNumber << endl;
    cerr << "------ pData: " << pData << endl;
    cerr << "------ pString: " << pString << endl;
    // _bstr_t bstrCashCounts(pString, false);
    // string str = (const char*)bstrCashCounts;
    // cerr << "str : " << str << endl;
    channel->InvokeMethod("DirectIOEvent", std::make_unique<flutter::EncodableValue>(pData[0]));
}

void CashChangerPlugin::StatusUpdateEvent(long Data) {
    cerr << "------ CashChangerPlugin::StatusUpdateEvent ------" << endl;
    cerr << "------ Data: " << Data << endl;
    channel->InvokeMethod("StatusUpdateEvent", std::make_unique<flutter::EncodableValue>(Data));
}

void CashChangerPlugin::ReturnMapValue(
    unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result, 
    flutter::EncodableValue code, 
    flutter::EncodableValue value,
    flutter::EncodableValue message
    ) {
    flutter::EncodableMap map;
    map[flutter::EncodableValue("code")] = code;
    map[flutter::EncodableValue("value")] = value;
    map[flutter::EncodableValue("message")] = message;
    result->Success(flutter::EncodableValue(map));
}

void CashChangerPlugin::DirectIOMethod(unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result, long Command, long pData, BSTR pString) {

    cerr << "DirectIOMethod" << Command << "start 。。" << endl;
    long lngRet = pCashChanger->DirectIO(Command, &pData, &pString);
    cerr << "DirectIOMethod" << Command << " end 。。 " << lngRet << endl;
    long responseCode = lngRet;
    string message = (lngRet == OposSuccess) ? "success" : "failured";
    if (lngRet == OposEExtended) {
        responseCode = pCashChanger->ResultCodeExtended;
        switch (pCashChanger->ResultCodeExtended) {
            case OPOS_ECHAN_OVERDISPENSE:
                cerr << "OPOS_ECHAN_OVERDISPENSE" << endl;
                break;
            case OPOS_ECHAN_OVER:
                cerr << "OPOS_ECHAN_OVER" << endl;
                break;
            case OPOS_ECHAN_SETERROR:
            case OPOS_ECHAN_ERROR:
            case OPOS_ECHAN_BUSY:
                cerr << "OPOS_ECHAN_SETERROR" << endl;
                break;
            default:
                break;
        }
    }
    ReturnMapValue(move(result), flutter::EncodableValue(responseCode),
                   flutter::EncodableValue(pData),
                   flutter::EncodableValue(message));
    //SysFreeString(pString);
}

void CashChangerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    cerr << "CashChangerPlugin::HandleMethodCall" << endl;
    cerr << "method_call.method_name() = " << method_call.method_name() << endl;
 // 打开设备
 if (method_call.method_name().compare("openCashChanger") == 0) {
    cerr << "openCashChange called 。。" << endl;
        // 打开现金机
        long lngRet = pCashChanger->Open("CashChanger");
        cerr << "Open result 。。 " << lngRet << endl;
        // 检查是否已经打开
        if (lngRet == OposEIllegal) {
            lngRet = OposSuccess;
        }
        if (lngRet == OposSuccess) {
            if (pCashChanger->Claimed == VARIANT_FALSE) {
            // 获取排他访问权限
                //thread([&lngRet, &result, pCashChanger = this->pCashChanger]() {
                    lngRet = pCashChanger->ClaimDevice(6000);
                    cerr << "ClaimDevice result lngRet = " << lngRet << endl;
                    if (lngRet == 0) {
                        cerr << "ClaimDevice 成功" << endl;
                        // 设置设备属性
                        pCashChanger->DeviceEnabled = VARIANT_TRUE;
                        pCashChanger->DataEventEnabled = VARIANT_TRUE;
                        pCashChanger->FreezeEvents = VARIANT_FALSE;

                        // 执行 DirectIO x
                        long data = 0;
                        BSTR bstr = SysAllocString(L"");
                        lngRet = pCashChanger->DirectIO(CHAN_DI_DEPOSITMODE, &data, &bstr);
                        if (lngRet == 114) {
                            lngRet = pCashChanger->ResultCodeExtended;
                        }
                        cerr << "DirectIO result 。。lngRet " << lngRet << endl;
                        SysFreeString(bstr);
                        ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(0), flutter::EncodableValue("success"));
                        //result->Success(flutter::EncodableValue(lngRet));
                    } else {
                        cerr << "開局処理に失敗しました。接続状態を確認して下さい。" << endl;
                        cerr << "ClaimDevice 失败，错误码：" << lngRet << endl;
                        //result->Success(flutter::EncodableValue(lngRet));
                        ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(0), flutter::EncodableValue("ClaimDevice 失败"));
                        //channel->InvokeMethod("ClaimDeviceResult", std::make_unique<flutter::EncodableValue>(lngRet));
                    }
                //}).detach();
                
            } else {
                // 设备已被声明，设置属性
                cerr << "设备已被声明，设置属性" << endl;
                pCashChanger->DeviceEnabled = VARIANT_TRUE;
                pCashChanger->DataEventEnabled = VARIANT_TRUE;
                pCashChanger->FreezeEvents = VARIANT_FALSE;
                //result->Success(flutter::EncodableValue(lngRet));
                ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(0), flutter::EncodableValue("设备已被声明，设置属性"));
            }
        } else {
            cerr << "開局処理に失敗しました。接続状態を確認して下さい。" << endl;
//            if (lngRet == OposENoservice) {
                //result->Success(flutter::EncodableValue(pCashChanger->OpenResult));
                ReturnMapValue(move(result), flutter::EncodableValue(pCashChanger->OpenResult), flutter::EncodableValue(0), 
                flutter::EncodableValue("開局処理に失敗しました。接続状態を確認して下さい。"));
                cerr << "Open 失败, 错误码：" << pCashChanger->OpenResult << endl;
            // } else {
            //     result->Success(flutter::EncodableValue(lngRet));
            //     cerr << "Open 失败，错误码：" << lngRet << endl;
            // }
        }
    return;
  }

  if (method_call.method_name().compare("claimDevice") == 0) {
    cerr << "claimDevice called 。。" << endl;

    if (pCashChanger == nullptr) {
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("Cash Changer not initialized"));
                return;
    }

    long lngRet = pCashChanger->ClaimDevice(10000);
    cerr << "ClaimDevice result 。。 " << lngRet << endl;

        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                                     flutter::EncodableValue(0),
                                     flutter::EncodableValue(lngRet == OposSuccess ? "success"
                                                                                                                             : "failured"));
    
    return;
  }
  // 关闭设备
  if (method_call.method_name().compare("closeCashChanger") == 0) {
    cerr << "closeCashChanger called 。。" << endl;

        if (pCashChanger == NULL) {
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("Cash Changer not initialized"));
                return;
    }

    // 禁用设备
    pCashChanger->DeviceEnabled = VARIANT_FALSE;

    // 释放设备
    long lngRet = pCashChanger->ReleaseDevice();
    // 可以记录或处理 lngRet 来了解 ReleaseDevice 的执行情况

    // 关闭设备，释放资源
    lngRet = pCashChanger->Close();

    if (lngRet == OposSuccess) {
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("success"));
    } else {
        cerr << "关闭设备失败，错误码：" << lngRet << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("关闭设备失败"));
    }

    return;
  }
  // 获取现金信息
  if (method_call.method_name().compare("getCashBalance") == 0) {
    cerr << "getCashBalance called 。。" << endl;
    if (pCashChanger == nullptr) {
      //result->Error("Cash Changer not initialized");
      //result->Success(flutter::EncodableValue("Cash Changer not initialized"));
      ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("Cash Changer not initialized"));
      return;
    }

    // 定义变量
    BSTR st_CashCounts;
    VARIANT_BOOL b_Discrepancy;
    long lngRet;


    cerr << "ReadCashCounts execute 。。" << endl;
    // 调用 ReadCashCounts 方法
    lngRet = pCashChanger->ReadCashCounts(&st_CashCounts, &b_Discrepancy);
    cerr << "ReadCashCounts end 。。 " << lngRet << endl;
    // 检查是否成功
    if (lngRet != OposSuccess) {
        
        if (lngRet == OposEExtended) {
            //result->Success(flutter::EncodableValue(0));
            cerr << "ReadCashCounts failed with code: " << pCashChanger->ResultCodeExtended << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(pCashChanger->ResultCodeExtended), flutter::EncodableValue(0), flutter::EncodableValue("failured"));
            return;
        }

        ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(0), flutter::EncodableValue("ReadCashCounts failed with code: " + to_string(lngRet)));
        //result->Success(flutter::EncodableValue("ReadCashCounts failed with code: " + to_string(lngRet)));
        return;
    }

    // 将 BSTR 转换为 string
    _bstr_t bstrCashCounts(st_CashCounts, false);
    string cashCounts = (const char*)bstrCashCounts;
    cerr << "将 BSTR 转换为 string 。。" << endl;
    // 分割硬币和纸币信息
    size_t i_FindIdx = cashCounts.find(';');
    string st_CoinCashList, st_BillCashList;
    if (i_FindIdx != string::npos) {
        st_CoinCashList = cashCounts.substr(0, i_FindIdx);
        st_BillCashList = cashCounts.substr(i_FindIdx + 1);
    } else {
        st_CoinCashList = cashCounts;
        st_BillCashList = "";
    }
    cerr << "分割硬币和纸币信息 。。" << endl;
    // 根据需要处理硬币和纸币信息
    // ...

    // 返回处理后的信息
    //result->Success(flutter::EncodableValue(st_CoinCashList +','+ st_BillCashList));
    ReturnMapValue(move(result), flutter::EncodableValue(0), flutter::EncodableValue(st_CoinCashList +','+ st_BillCashList), flutter::EncodableValue("success"));

    return;
  }

  // 开始入金
  if(method_call.method_name().compare("startDeposit") == 0) {
    cerr << "startDeposit called 。。" << endl;

    if (pCashChanger == nullptr) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer not initialized"));
        return;
    }
    pCashChanger->DataEventEnabled = VARIANT_TRUE;
    long lngRet = pCashChanger->BeginDeposit();
    cerr << "startDeposit result 。。 " << lngRet << endl;
    if (lngRet == OposSuccess) {
        // 成功开始存款计数
        //result->Success(flutter::EncodableValue(OposSuccess));
        ReturnMapValue(move(result), flutter::EncodableValue(OposSuccess), flutter::EncodableValue(0), flutter::EncodableValue("success"));
    } else if (lngRet == OposEExtended) {
        // 特定错误处理
        // switch (pCashChanger->ResultCodeExtended) {
        //     case OPOS_ECHAN_DEPOSIT:
        //         // 已在计数中
        //         cerr << "OPOS_ECHAN_DEPOSIT" << endl;
        //        result->Success(flutter::EncodableValue(0));
        //        break;
        //     case OPOS_ECHAN_PAUSEDEPOSIT:
        //         // 已在计数中
        //         cerr << "OPOS_ECHAN_PAUSEDEPOSIT" << endl;
        //         result->Success(flutter::EncodableValue(OPOS_ECHAN_PAUSEDEPOSIT));
        //         break;
        //     default:
        //         // 其他错误
        //         cerr << "其他错误:" << pCashChanger->ResultCodeExtended << endl;
        //         result->Success(flutter::EncodableValue(pCashChanger->ResultCodeExtended));
                
        // }
        ReturnMapValue(move(result), flutter::EncodableValue(pCashChanger->ResultCodeExtended), flutter::EncodableValue(0), flutter::EncodableValue("failured"));
    } else {
        // 通用错误处理
        //result->Success(flutter::EncodableValue(lngRet));
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(0), flutter::EncodableValue("failured"));
    }

    return;
  }

 
  // 获取入金金额
  if(method_call.method_name().compare("depositAmount") == 0) {
    isDepositAmount = true;
    cerr << "DepositAmount called 。。" << endl;

    if (pCashChanger == nullptr) {
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("Cash Changer not initialized"));
                return;
    }

    long logAmount;
    long lngRet;
    //int lngChange;
    //short intSuc;

    lngRet = pCashChanger->FixDeposit();
    cout << "FixDeposit result: " << lngRet << endl;
    if (lngRet == OposSuccess) {           
        // 获取入金金额
        logAmount = pCashChanger->DepositAmount;
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(logAmount),
                       flutter::EncodableValue("success"));
    } else {
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("FixDeposit failed"));
    }

    return;
  }

  if(method_call.method_name().compare("fixDeposit") == 0) {
    isDepositAmount = true;
    cerr << "fixDeposit called 。。" << endl;

    if (pCashChanger == nullptr) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer not initialized"));
        return;
    }

    long lngRet = pCashChanger->FixDeposit();
    cout << "fixDeposit result: " << lngRet << endl;
    ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                   flutter::EncodableValue(0),
                   flutter::EncodableValue(lngRet == OposSuccess ? "success"
                                                               : "failured"));

    return;
  }
   
    // 设置结束入金
    if(method_call.method_name().compare("endDeposit") == 0) {

        cerr << "endDeposit called 。。" << endl;

        if (pCashChanger == nullptr) {
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("Cash Changer not initialized"));
                return;
        }
        auto arguments = method_call.arguments();
        if (!arguments) {
                cerr << "endDeposit param error 。。1" << endl;
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("endDeposit param error 1"));
                return;
        }
    
        int intSuc = 0;
        const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
        auto it = mapValue->find(flutter::EncodableValue("end_deposit"));
        if (it == mapValue->end()) {
                cerr << "endDeposit param error 。。2" << endl;
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("endDeposit param error 2"));
                return;
        }

        intSuc = get<int>(it->second);
        cerr << "endDeposit param 。。" << intSuc << endl;
        long lngRet = pCashChanger->EndDeposit(intSuc);
        cerr << "EndDeposit result 。。 " << lngRet << endl;
        if (lngRet == OposSuccess) {

            ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                                         flutter::EncodableValue(intSuc),
                                         flutter::EncodableValue("success"));

        } else {
                cerr << "EndDeposit error .. ResultCodeExtended " << pCashChanger->ResultCodeExtended << endl;
            long errorCode = (pCashChanger->ResultCodeExtended == OPOS_ECHAN_DEPOSIT)
                                                     ? OPOS_ECHAN_DEPOSIT
                                                     : pCashChanger->ResultCodeExtended;
            ReturnMapValue(move(result), flutter::EncodableValue(errorCode),
                                         flutter::EncodableValue(intSuc),
                                         flutter::EncodableValue("failured"));
        }
        return;
    }
    
  // 出钞找钱
  if (method_call.method_name().compare("dispenseChange") == 0) {
    cerr << "dispenseChange called 。。" << endl;

    if (pCashChanger == nullptr) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer not initialized"));
        return;
    }

    auto arguments = method_call.arguments();
    if (!arguments) {
        cerr << "dispenseChange param error 。。1" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("dispenseChange param error 1"));
        return;
    }
    const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
    if (!mapValue) {
        cerr << "dispenseChange param error 。。2" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("dispenseChange param error 2"));
        return;
    }

    auto it = mapValue->find(flutter::EncodableValue("dispense"));
    if (it == mapValue->end()) {
        cerr << "dispenseChange param error 。。3" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("dispenseChange param error 3"));
        return;
    }

    long lngChange = get<int>(it->second);
    pCashChanger->CurrentExit = 1;
    long lngRet = pCashChanger->DispenseChange(lngChange);
    cerr << "DispenseChange result 。。 " << lngRet << endl;
    if (lngRet == OposSuccess) {
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(lngChange),
                       flutter::EncodableValue("success"));
    } else if (lngRet == OposEExtended) {
        ReturnMapValue(move(result),
                       flutter::EncodableValue(pCashChanger->ResultCodeExtended),
                       flutter::EncodableValue(lngChange),
                       flutter::EncodableValue("failured"));
    } else {
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(lngChange),
                       flutter::EncodableValue("failured"));
    }
    
    return;
  }
  
  // 退还所有入金
  if (method_call.method_name().compare("depositRepay") == 0) {
    cerr << "depositRepay called .." << endl;

    if (pCashChanger == nullptr) {
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("Cash Changer not initialized"));
                return;
    }

    long lngRet = pCashChanger->EndDeposit(ChanDepositrepay);
    cerr << "depositRepay result 。。 " << lngRet << endl;
    if (lngRet == OposSuccess) {
            ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                                         flutter::EncodableValue(0),
                                         flutter::EncodableValue("success"));
    } else {
      cerr << "depositRepay error .." << pCashChanger->ResultCodeExtended << endl;
            long resultCode = (pCashChanger->ResultCodeExtended == OPOS_ECHAN_DEPOSIT)
                                                        ? OPOS_ECHAN_DEPOSIT
                                                        : pCashChanger->ResultCodeExtended;
            ReturnMapValue(move(result), flutter::EncodableValue(resultCode),
                                         flutter::EncodableValue(0),
                                         flutter::EncodableValue("failured"));
    }
    return;
  }
  
  //エラー解除ガイダンスを起動する

  if (method_call.method_name().compare("errorRestore") == 0) {
    cerr << "errorRestore called 。。" << endl;

    if (pCashChanger == nullptr) {
                ReturnMapValue(move(result), flutter::EncodableValue(-1),
                                             flutter::EncodableValue(0),
                                             flutter::EncodableValue("Cash Changer not initialized"));
                return;
    }

    long lngRet = pCashChanger->ClearInput();

        if (lngRet == OposSuccess) {
            ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                                         flutter::EncodableValue(0),
                                         flutter::EncodableValue("success"));
        } else {
            long code = (pCashChanger->ResultCodeExtended == OPOS_ECHAN_DEPOSIT)
                                            ? OPOS_ECHAN_DEPOSIT
                                            : pCashChanger->ResultCodeExtended;
            ReturnMapValue(move(result), flutter::EncodableValue(code),
                                         flutter::EncodableValue(0),
                                         flutter::EncodableValue("failured"));
        }
    return;
  }
    
  // collect all
  if (method_call.method_name().compare("collectAll") == 0) {
    cerr << "collectAll called 。。" << endl;

    if (pCashChanger == nullptr) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer not initialized"));
        return;
    }

    long lngData = 0;
    bool blnBill = false;
    bool blnCoin = false;

    auto arguments = method_call.arguments();
    if (!arguments) {
        cerr << "collectAll param error 。。1" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("collectAll param error 1"));
        return;
    }
    const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
    if (!mapValue) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("collectAll param error 2"));
        return;
    }

    auto billIt = mapValue->find(flutter::EncodableValue("Bill"));
    if (billIt != mapValue->end()) {
        if (const auto *intValue = get_if<int>(&billIt->second)) {
            blnBill = *intValue == 1;
        } else {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("collectAll param error 3"));
            return;
        }
    } else {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("collectAll param error 2"));
        return;
    }

    auto coinIt = mapValue->find(flutter::EncodableValue("Coin"));
    if (coinIt != mapValue->end()) {
        if (const auto *intValue = get_if<int>(&coinIt->second)) {
            blnCoin = *intValue == 1;
        } else {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("collectAll param error 4"));
            return;
        }
    } else {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("collectAll param error 3"));
        return;
    }

    if (blnBill) {
        lngData |= 0x3;
    }
    if (blnCoin) {
        lngData |= 0x70000;
    }

    BSTR bstr = SysAllocString(L"");
    long lngRet = pCashChanger->DirectIO(CHAN_DI_COLLECT, &lngData, &bstr);
    cerr << "DirectIO CHAN_DI_COLLECT end 。。 " << lngRet << endl;
    SysFreeString(bstr);

    long responseCode = pCashChanger->ResultCode;
    string message = "success";
    if (responseCode == OposSuccess) {
        message = "success";
    } else if (responseCode == OposEExtended) {
        responseCode = pCashChanger->ResultCodeExtended;
        message = "failured";
    } else {
        message = "failured";
    }

    ReturnMapValue(move(result), flutter::EncodableValue(responseCode),
                   flutter::EncodableValue(lngData),
                   flutter::EncodableValue(message));
    return;
  }

  if (method_call.method_name().compare("checkChangerStatus") == 0) {
    cerr << "checkChangerStatus called 。。" << endl;

    if (pCashChanger == nullptr) {
        cerr << "Cash Changer not initialized" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer not initialized"));
        return;
    }

    long lngRet = pCashChanger->CheckHealth(OposChInternal);
    cerr << "CheckHealth end 。。 " << lngRet << endl;
    ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                   flutter::EncodableValue(0),
                   flutter::EncodableValue(lngRet == OposSuccess ? "success"
                                                               : "failured"));

    return;
  }


  // check error code

  if (method_call.method_name().compare("changer_di_status") == 0) {
    cerr << "changer_di_status called 。。" << endl;

    if (pCashChanger == nullptr) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer not initialized"));
        return;
    }

    long lngData = 1;

    auto arguments = method_call.arguments();
    if (!arguments) {
        cerr << "changer_di_status param error 。。1" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("changer_di_status param error 1"));
        return;
    }
    const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
    if (!mapValue) {
        cerr << "changer_di_status param error 。。2" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("changer_di_status param error 2"));
        return;
    }
    // Accessing a value in the map
    auto it = mapValue->find(flutter::EncodableValue("pData"));
    if (it != mapValue->end()) {
        lngData = get<int>(it->second);
    } else {
        cerr << "changer_di_status param error 。。2" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("changer_di_status param error 3"));
        return;
    }

    BSTR strTemp = SysAllocString(L"");
    if (!strTemp) {
        cerr << "Failed to allocate BSTR" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Memory allocation failed"));
        return;
    }
    long lngRet = pCashChanger->DirectIO(CHAN_DI_STATUSREAD, &lngData, &strTemp);
    cerr << "-- DirectIO CHAN_DI_STATUSREAD end --" << lngRet << endl;
    cerr << "strTemp " << lngData << " : " << strTemp << endl;
    
    //000001F3AA222A18
    if (lngRet == OposSuccess) {
        _bstr_t bstrCashCounts(strTemp, false);
        string str = (const char*)bstrCashCounts;
        cerr << "str : " << str << endl;

        ReturnMapValue(move(result), flutter::EncodableValue(OposSuccess),
                       flutter::EncodableValue(str),
                       flutter::EncodableValue("success"));
    } else {
        cerr << "DirectIO CHAN_DI_STATUSREAD error .." << lngRet << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet),
                       flutter::EncodableValue(0),
                       flutter::EncodableValue("Cash Changer Status no response"));
    }
    //SysFreeString(strTemp);
    
    return;
  }

  //補充開始 CHAN_DI_SUPPLY
    if (method_call.method_name().compare("startSupply") == 0) {
        cerr << "startSupply called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        cerr << "DirectIO CHAN_DI_SUPPLY start 。。 " << endl;
        long dummyData = 0;
        BSTR dummyString = SysAllocString(L"");

        DirectIOMethod(move(result), CHAN_DI_SUPPLY, dummyData, dummyString);
        //SysFreeString(dummyString);
        return;
    }
    
    //補充枚数取得 CHAN_DI_SUPPLYCOUNTS
    if (method_call.method_name().compare("supplyCounts") == 0) {
        cerr << "getSupplyCounts called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        long lngData;

        lngData = 1;
        auto arguments = method_call.arguments();
        if (!arguments) {
            cerr << "getSupplyCounts param error 。。1" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("getSupplyCounts param error 1"));
            return;
        }
        const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
        if (!mapValue) {
            cerr << "getSupplyCounts param error 。。2" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("getSupplyCounts param error 2"));
            return;
        }
        // Accessing a value in the map
        auto it = mapValue->find(flutter::EncodableValue("pData"));
        if (it != mapValue->end()) {
            lngData = get<int>(it->second);
        } else {
            cerr << "getSupplyCounts param error 。。2" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("getSupplyCounts param error 3"));
            return;
        }

        long lngRet;
        BSTR strTemp = SysAllocString(L"");
        if (!strTemp) {
            cerr << "Failed to allocate BSTR" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("Memory allocation failed"));
            //result->Error("Memory allocation failed");
            return;
        }
        lngRet = pCashChanger->DirectIO(CHAN_DI_SUPPLYCOUNTS, &lngData, &strTemp);
        cerr << "DirectIO CHAN_DI_SUPPLYCOUNTS end 。。 " << lngRet << endl;
        if (lngRet == OposSuccess) {
            _bstr_t bstrCashCounts(strTemp, false);
            string str = (const char*)bstrCashCounts;
            cerr << "CHAN_DI_SUPPLYCOUNTS str : " << str << endl;

            //result->Success(flutter::EncodableValue(str));
            ReturnMapValue(move(result), flutter::EncodableValue(OposSuccess), flutter::EncodableValue(str), flutter::EncodableValue("success"));

        } else {
            cerr << "DirectIO CHAN_DI_SUPPLYCOUNTS error .." << lngRet << endl;
            //result->Error("Cash Changer SupplyCounts no response");
            ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(0), flutter::EncodableValue("failured"));
        }
        //SysFreeString(strTemp);
        
        return;
    }

    //累計カウンタクリア
    if (method_call.method_name().compare("countClear") == 0) {
        cerr << "countClear called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        long lngData = 0;
        BSTR strTemp = SysAllocString(L"");
        if (!strTemp) {
            cerr << "Failed to allocate BSTR" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Memory allocation failed"));
            return;
        }
        DirectIOMethod(move(result), CHAN_DI_COUNTCLR, lngData, strTemp);
        //SysFreeString(strTemp);
        
        return;
    }

    //リセット CHAN_DI_RESET
    if (method_call.method_name().compare("reset") == 0) {
        cerr << "reset called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        long lngData = 0;
        BSTR strTemp = SysAllocString(L"");
        if (!strTemp) {
            cerr << "Failed to allocate BSTR" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Memory allocation failed"));
            return;
        }
        DirectIOMethod(move(result), CHAN_DI_RESET, lngData, strTemp);
        //SysFreeString(strTemp);
        
        return;
    }

    //取引外入金開始 CHAN_DI_BEGINDEPOSITOUTSIDE
    if (method_call.method_name().compare("beginDepositOutside") == 0) {
        cerr << "beginDepositOutside called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        long lngData = 0;
        BSTR strTemp = SysAllocString(L"");
        DirectIOMethod(move(result), CHAN_DI_BEGINDEPOSITOUTSIDE, lngData, strTemp);
        
        return;
    }


  
    //枚数指定出金 CHAN_DI_DISPENSECASHOUTSIDE
    if (method_call.method_name().compare("dispenseCashOutside") == 0) {
        cerr << "dispenseCashOutside called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        BSTR cashInfo = SysAllocString(L"");
        long lngData = 0;
        auto arguments = method_call.arguments();
        if (!arguments) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("dispenseCashOutside param error 1"));
            return;
        }
        const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
        auto it = mapValue->find(flutter::EncodableValue("cashInfo"));
        if (it != mapValue->end()) {
            string str = get<string>(it->second);
            cerr << "cashInfo : " << str << endl;
            _bstr_t bstr(str.c_str());
            cashInfo = bstr;
        } else {
            cerr << "dispenseCashOutside param error 。。2" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("dispenseCashOutside param error 2"));
            return;
        }
        
        
        pCashChanger->CurrentExit = 1;
        DirectIOMethod(move(result), CHAN_DI_DISPENSECASHOUTSIDE, lngData, cashInfo);
        
        return;
    }

    if (method_call.method_name().compare("dispenseChangeOutside") == 0) {
        cerr << "dispenseChangeOutside called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        BSTR cashInfo = SysAllocString(L"");
        long lngData = 0;
        auto arguments = method_call.arguments();
        if (!arguments) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("dispenseChangeOutside param error 1"));
            return;
        }
        const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
        auto it = mapValue->find(flutter::EncodableValue("count"));
        if (it != mapValue->end()) {
            lngData = get<int>(it->second);
            cerr << "count : " << lngData << endl;
        } else {
            cerr << "dispenseChangeOutside param error 。。2" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("dispenseChangeOutside param error 2"));
            return;
        }
        

        pCashChanger->CurrentExit = 1;
        DirectIOMethod(move(result), CHAN_DI_DISPENSECHANGEOUTSIDE, lngData, cashInfo);
        
        return;
    }

    //CHAN_DI_BEGINCASHRETURN
    if (method_call.method_name().compare("beginCashReturn") == 0) {
        cerr << "beginCashReturn called 。。" << endl;
    
        if (pCashChanger == nullptr) {
            ReturnMapValue(move(result), flutter::EncodableValue(-1),
                           flutter::EncodableValue(0),
                           flutter::EncodableValue("Cash Changer not initialized"));
            return;
        }
        BSTR strTemp = SysAllocString(L"");
        long lngData = 0;

        DirectIOMethod(move(result), CHAN_DI_BEGINCASHRETURN, lngData, strTemp);
        
        return;
    }


  
  if (method_call.method_name().compare("dispenseCash") == 0) {
    cerr << "dispenseCash called 。。" << endl;

    if (pCashChanger == nullptr) {
        ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("Cash Changer not initialized"));
    }

    // 提取参数并转换为 BSTR（仅调用 COM 时使用），避免直接把 BSTR 指针放进 EncodableValue
    std::string cashCountsStr;
    auto arguments = method_call.arguments();
    if (!arguments) {
        cerr << "dispenseCash param error 。。1" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("param error"));
        return;
    }
    const auto *mapValue = get_if<flutter::EncodableMap>(arguments);
    if (!mapValue) {
        cerr << "dispenseCash param error 。。map not found" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("param error"));
        return;
    }
    auto it = mapValue->find(flutter::EncodableValue("cashCounts"));
    if (it != mapValue->end()) {
        cashCountsStr = get<string>(it->second);
        cerr << "cashCounts : " << cashCountsStr << endl;
    } else {
        cerr << "dispenseCash param error 。。2" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("param error"));
        return;
    }

    // UTF-8 -> UTF-16 (WinAPI, 避免使用已弃用的 <codecvt>)
    std::wstring wCashCounts;
    if (!cashCountsStr.empty()) {
        int needed = MultiByteToWideChar(CP_UTF8, 0, cashCountsStr.c_str(), (int)cashCountsStr.size(), nullptr, 0);
        if (needed <= 0) {
            cerr << "MultiByteToWideChar size query failed" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("encoding error"));
            return;
        }
        wCashCounts.resize(needed);
        int written = MultiByteToWideChar(CP_UTF8, 0, cashCountsStr.c_str(), (int)cashCountsStr.size(), &wCashCounts[0], needed);
        if (written != needed) {
            cerr << "MultiByteToWideChar convert failed" << endl;
            ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("encoding error"));
            return;
        }
    }
    BSTR bstrCashCounts = SysAllocStringLen(wCashCounts.c_str(), static_cast<UINT>(wCashCounts.size()));
    if (!bstrCashCounts && !wCashCounts.empty()) {
        cerr << "SysAllocStringLen failed" << endl;
        ReturnMapValue(move(result), flutter::EncodableValue(-1), flutter::EncodableValue(0), flutter::EncodableValue("alloc error"));
        return;
    }

    long lngRet = pCashChanger->DispenseCash(bstrCashCounts);
    cerr << "DispenseCash end 。。 " << lngRet << endl;
    // 返回原始字符串，不传 BSTR 指针
    if (lngRet == OposSuccess) {
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(cashCountsStr), flutter::EncodableValue("Success"));
    } else if (lngRet == OposEExtended) {
        ReturnMapValue(move(result), flutter::EncodableValue(pCashChanger->ResultCodeExtended), flutter::EncodableValue(cashCountsStr), flutter::EncodableValue("failured"));
    } else {
        ReturnMapValue(move(result), flutter::EncodableValue(lngRet), flutter::EncodableValue(cashCountsStr), flutter::EncodableValue("failured"));
    }
    SysFreeString(bstrCashCounts);

    return;
  }


  if (method_call.method_name().compare("getPlatformVersion") == 0) {
        ostringstream version_stream;
        version_stream << "Windows ";
        if (IsWindows10OrGreater()) {
          version_stream << "10+";
        } else if (IsWindows8OrGreater()) {
          version_stream << "8";
        } else if (IsWindows7OrGreater()) {
          version_stream << "7";
        }
        result->Success(flutter::EncodableValue(version_stream.str()));
      } else {
        result->NotImplemented();
      }
  }
  


}  // namespace cash_changer
