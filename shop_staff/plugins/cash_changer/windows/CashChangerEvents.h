

#include <string>
#include "64OPOSCashChanger.tlh"
#include "ICashChangerEventsDelegate.h"

using namespace OposCashChanger_CCO;
using namespace std;

class CashChangerEvents : public _IOPOSCashChangerEvents {

private:
        
    long m_refCount;
    ICashChangerEventsDelegate *delegate;

public:
    CashChangerEvents() :  m_refCount(1) {}

    void setDelegate(ICashChangerEventsDelegate *newDelegate) {
        this->delegate = newDelegate;
    }

    // IUnknown 方法
    HRESULT __stdcall QueryInterface(REFIID riid, void **ppv) override {
        if (!ppv) {
        return E_POINTER;
        }
        *ppv = nullptr;

        if (riid == IID_IUnknown || riid == IID_IDispatch || riid == __uuidof(_IOPOSCashChangerEvents)) {
            *ppv = static_cast<IDispatch*>(this);
            AddRef();
            return S_OK;
        }

        return E_NOINTERFACE;
    }

    ULONG __stdcall AddRef() override {
        //cerr << "-----AddRef-----" << endl;
        return InterlockedIncrement(&m_refCount);
    }

    ULONG __stdcall Release() override {
        //cerr << "-----Release-----" << endl;
        long val = InterlockedDecrement(&m_refCount);
        if (val == 0) {
            delete this;
        }
        return val;
    }

    // IDispatch 方法
    HRESULT __stdcall GetTypeInfoCount(UINT *pctinfo) override {
        //cerr << "-----GetTypeInfoCount-----" << endl;
        return E_NOTIMPL;
    }

    HRESULT __stdcall GetTypeInfo(UINT iTInfo, LCID lcid, ITypeInfo **ppTInfo) override {
        //cerr << "-----GetTypeInfo-----" << endl;
        return E_NOTIMPL;
    }

    HRESULT __stdcall GetIDsOfNames(REFIID riid, LPOLESTR *rgszNames, UINT cNames,
                                    LCID lcid, DISPID *rgDispId) override {
        //cerr << "-----GetIDsOfNames-----" << endl;
        return E_NOTIMPL;
    }

    HRESULT __stdcall Invoke(DISPID dispIdMember, REFIID riid, LCID lcid, WORD wFlags,
                             DISPPARAMS *pDispParams, VARIANT *pVarResult,
                             EXCEPINFO *pExcepInfo, UINT *puArgErr) override {
        
        switch (dispIdMember) {
            case 0x1: 
                delegate->DataEvent(pDispParams->rgvarg[0].lVal);
                break;
            case 0x2:  
                delegate->DirectIOEvent(pDispParams->rgvarg[2].lVal, pDispParams->rgvarg[1].plVal, pDispParams->rgvarg[0].pbstrVal);
                break;
            case 0x5:  
                delegate->StatusUpdateEvent(pDispParams->rgvarg[0].lVal);
                break;
            default:
                cerr << "-----Invoke default----- DISPID: " << dispIdMember << endl;
                break;
        }
        return S_OK;
    }


};

