#include "vpnclient_engine_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "../include/vpnclient_engine.h"

namespace vpnclient_engine {

// VPN Engine instance
static std::unique_ptr<VPNClientEngine> g_engine = nullptr;
static flutter::MethodChannel<flutter::EncodableValue>* g_channel = nullptr;

// Convert Dart map to CoreConfig
CoreConfig MapToCoreConfig(const flutter::EncodableMap& map) {
    CoreConfig config;
    
    auto type_it = map.find(flutter::EncodableValue("type"));
    if (type_it != map.end() && std::holds_alternative<std::string>(type_it->second)) {
        const auto& type_str = std::get<std::string>(type_it->second);
        if (type_str == "singbox") config.type = CoreType::SINGBOX;
        else if (type_str == "libxray") config.type = CoreType::LIBXRAY;
        else if (type_str == "v2ray") config.type = CoreType::V2RAY;
        else if (type_str == "wireguard") config.type = CoreType::WIREGUARD;
    }
    
    auto config_json_it = map.find(flutter::EncodableValue("configJson"));
    if (config_json_it != map.end() && std::holds_alternative<std::string>(config_json_it->second)) {
        config.config_json = std::get<std::string>(config_json_it->second);
    }
    
    return config;
}

// Convert Dart map to DriverConfig
DriverConfig MapToDriverConfig(const flutter::EncodableMap& map) {
    DriverConfig config;
    
    auto type_it = map.find(flutter::EncodableValue("type"));
    if (type_it != map.end() && std::holds_alternative<std::string>(type_it->second)) {
        const auto& type_str = std::get<std::string>(type_it->second);
        if (type_str == "none") config.type = DriverType::NONE;
        else if (type_str == "hevSocks5") config.type = DriverType::HEV_SOCKS5;
        else if (type_str == "tun2socks") config.type = DriverType::TUN2SOCKS;
    }
    
    auto mtu_it = map.find(flutter::EncodableValue("mtu"));
    if (mtu_it != map.end() && std::holds_alternative<int>(mtu_it->second)) {
        config.mtu = static_cast<uint16_t>(std::get<int>(mtu_it->second));
    }
    
    return config;
}

// Static callbacks
void OnStatusChanged(ConnectionStatus status) {
    if (g_channel == nullptr) return;
    
    std::string status_str;
    switch (status) {
        case ConnectionStatus::DISCONNECTED: status_str = "disconnected"; break;
        case ConnectionStatus::CONNECTING: status_str = "connecting"; break;
        case ConnectionStatus::CONNECTED: status_str = "connected"; break;
        case ConnectionStatus::DISCONNECTING: status_str = "disconnecting"; break;
        case ConnectionStatus::ERROR: status_str = "error"; break;
    }
    
    g_channel->InvokeMethod("onStatusChanged", 
        std::make_unique<flutter::EncodableValue>(status_str));
}

void OnStatsUpdated(const ConnectionStats& stats) {
    if (g_channel == nullptr) return;
    
    flutter::EncodableMap stats_map;
    stats_map[flutter::EncodableValue("bytesSent")] = 
        flutter::EncodableValue(static_cast<int64_t>(stats.bytes_sent));
    stats_map[flutter::EncodableValue("bytesReceived")] = 
        flutter::EncodableValue(static_cast<int64_t>(stats.bytes_received));
    stats_map[flutter::EncodableValue("packetsSent")] = 
        flutter::EncodableValue(static_cast<int64_t>(stats.packets_sent));
    stats_map[flutter::EncodableValue("packetsReceived")] = 
        flutter::EncodableValue(static_cast<int64_t>(stats.packets_received));
    stats_map[flutter::EncodableValue("latencyMs")] = 
        flutter::EncodableValue(static_cast<int>(stats.latency_ms));
    
    g_channel->InvokeMethod("onStatsUpdated", 
        std::make_unique<flutter::EncodableValue>(stats_map));
}

void OnLog(const std::string& level, const std::string& message) {
    if (g_channel == nullptr) return;
    
    flutter::EncodableMap log_map;
    log_map[flutter::EncodableValue("level")] = flutter::EncodableValue(level);
    log_map[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
    
    g_channel->InvokeMethod("onLog", 
        std::make_unique<flutter::EncodableValue>(log_map));
}

// Plugin implementation
void VpnclientEnginePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "vpnclient_engine",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<VpnclientEnginePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  // Store channel for callbacks
  g_channel = channel.get();

  registrar->AddPlugin(std::move(plugin));
}

VpnclientEnginePlugin::VpnclientEnginePlugin() {}

VpnclientEnginePlugin::~VpnclientEnginePlugin() {}

void VpnclientEnginePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto& method_name = method_call.method_name();
  
  if (method_name == "initialize") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }
    
    Config config;
    
    auto core_it = arguments->find(flutter::EncodableValue("core"));
    if (core_it != arguments->end() && std::holds_alternative<flutter::EncodableMap>(core_it->second)) {
      config.core = MapToCoreConfig(std::get<flutter::EncodableMap>(core_it->second));
    }
    
    auto driver_it = arguments->find(flutter::EncodableValue("driver"));
    if (driver_it != arguments->end() && std::holds_alternative<flutter::EncodableMap>(driver_it->second)) {
      config.driver = MapToDriverConfig(std::get<flutter::EncodableMap>(driver_it->second));
    }
    
    g_engine = VPNClientEngine::create(config);
    if (g_engine) {
      g_engine->set_status_callback(OnStatusChanged);
      g_engine->set_stats_callback(OnStatsUpdated);
      g_engine->set_log_callback(OnLog);
      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error("INIT_FAILED", "Failed to initialize VPN engine");
    }
  }
  else if (method_name == "connect") {
    if (!g_engine) {
      result->Error("NOT_INITIALIZED", "Engine not initialized");
      return;
    }
    
    bool success = g_engine->connect();
    result->Success(flutter::EncodableValue(success));
  }
  else if (method_name == "disconnect") {
    if (!g_engine) {
      result->Error("NOT_INITIALIZED", "Engine not initialized");
      return;
    }
    
    g_engine->disconnect();
    result->Success();
  }
  else if (method_name == "getCoreName") {
    if (!g_engine) {
      result->Error("NOT_INITIALIZED", "Engine not initialized");
      return;
    }
    
    result->Success(flutter::EncodableValue(g_engine->get_core_name()));
  }
  else if (method_name == "getCoreVersion") {
    if (!g_engine) {
      result->Error("NOT_INITIALIZED", "Engine not initialized");
      return;
    }
    
    result->Success(flutter::EncodableValue(g_engine->get_core_version()));
  }
  else if (method_name == "getDriverName") {
    if (!g_engine) {
      result->Error("NOT_INITIALIZED", "Engine not initialized");
      return;
    }
    
    result->Success(flutter::EncodableValue(g_engine->get_driver_name()));
  }
  else if (method_name == "testConnection") {
    if (!g_engine) {
      result->Error("NOT_INITIALIZED", "Engine not initialized");
      return;
    }
    
    bool success = g_engine->test_connection();
    result->Success(flutter::EncodableValue(success));
  }
  else {
    result->NotImplemented();
  }
}

}  // namespace vpnclient_engine

