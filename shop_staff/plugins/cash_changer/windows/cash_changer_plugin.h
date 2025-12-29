#ifndef FLUTTER_PLUGIN_CASH_CHANGER_PLUGIN_H_
#define FLUTTER_PLUGIN_CASH_CHANGER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include "64OPOSCashChanger.tlh"
//#include "ICashChangerEventsDelegate.h"
#include "CashChangerEvents.h"
#include <cassert>

using namespace OposCashChanger_CCO;
using namespace std;

namespace cash_changer {

class CashChangerPlugin : public flutter::Plugin, public ICashChangerEventsDelegate {
 public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    CashChangerPlugin();

    virtual ~CashChangerPlugin();

    // Disallow copy and assign.
    CashChangerPlugin(const CashChangerPlugin&) = delete;
    CashChangerPlugin& operator=(const CashChangerPlugin&) = delete;

    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    void InitCashChangerEvents();

    // ICashChangerEventsDelegate
    void DataEvent(long Status) override;
    void DirectIOEvent(long EventNumber, long *pData, BSTR *pString) override;
    void StatusUpdateEvent(long Data) override;

    void ReturnMapValue(unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result, flutter::EncodableValue code, flutter::EncodableValue value, flutter::EncodableValue message);
    void DirectIOMethod(unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result, long Command, long pData, BSTR pString);

    
      
  private:
   
    IOPOSCashChangerPtr pCashChanger;

    IConnectionPointContainer* pCPC = nullptr;
    IConnectionPoint* pCP = nullptr;
    IConnectionPointContainer* pEvents = nullptr;
    CashChangerEvents* pHandler = NULL;
    bool isDepositAmount = false;
    
    // 存储入金金额
    //long amount;
    

};

}  // namespace cash_changer

#endif  // FLUTTER_PLUGIN_CASH_CHANGER_PLUGIN_H_


