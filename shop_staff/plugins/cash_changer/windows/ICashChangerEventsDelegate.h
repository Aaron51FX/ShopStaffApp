
#ifndef ICASHCHANGEREVENTSDELEGATE_H
#define ICASHCHANGEREVENTSDELEGATE_H
class ICashChangerEventsDelegate {
public:
    virtual void DataEvent(long Status) = 0;
    virtual void DirectIOEvent(long EventNumber, long *pData, BSTR *pString) = 0;
    virtual void StatusUpdateEvent(long Data) = 0;
};
#endif 