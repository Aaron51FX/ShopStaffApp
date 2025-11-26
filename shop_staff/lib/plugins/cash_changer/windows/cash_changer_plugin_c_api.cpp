#include "include/cash_changer/cash_changer_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "cash_changer_plugin.h"

void CashChangerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  cash_changer::CashChangerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
