#include "vpnclient_engine_c_api.h"
#include "vpnclient_engine.h"
#include <string>

extern "C" {

VPNClientEngineInstance vpnclient_engine_create(const VPNClientEngineConfig* c_config) {
    if (!c_config) return nullptr;
    
    // Convert C config to C++ config
    vpnclient_engine::Config config;
    
    // Map core type
    switch (c_config->core_type) {
        case 0: config.core.type = vpnclient_engine::CoreType::SINGBOX; break;
        case 1: config.core.type = vpnclient_engine::CoreType::LIBXRAY; break;
        case 2: config.core.type = vpnclient_engine::CoreType::V2RAY; break;
        case 3: config.core.type = vpnclient_engine::CoreType::WIREGUARD; break;
        default: config.core.type = vpnclient_engine::CoreType::SINGBOX;
    }
    
    // Map driver type
    switch (c_config->driver_type) {
        case 0: config.driver.type = vpnclient_engine::DriverType::NONE; break;
        case 1: config.driver.type = vpnclient_engine::DriverType::HEV_SOCKS5; break;
        case 2: config.driver.type = vpnclient_engine::DriverType::TUN2SOCKS; break;
        default: config.driver.type = vpnclient_engine::DriverType::HEV_SOCKS5;
    }
    
    // Set config JSON
    if (c_config->config_json) {
        config.core.config_json = c_config->config_json;
    }
    
    try {
        auto engine = vpnclient_engine::VPNClientEngine::create(config);
        return engine.release();
    } catch (...) {
        return nullptr;
    }
}

bool vpnclient_engine_connect(VPNClientEngineInstance instance) {
    if (!instance) return false;
    
    auto engine = static_cast<vpnclient_engine::VPNClientEngine*>(instance);
    return engine->connect();
}

void vpnclient_engine_disconnect(VPNClientEngineInstance instance) {
    if (!instance) return;
    
    auto engine = static_cast<vpnclient_engine::VPNClientEngine*>(instance);
    engine->disconnect();
}

int32_t vpnclient_engine_get_status(VPNClientEngineInstance instance) {
    if (!instance) return 0; // DISCONNECTED
    
    auto engine = static_cast<vpnclient_engine::VPNClientEngine*>(instance);
    auto status = engine->get_status();
    
    // Map C++ status to int
    switch (status) {
        case vpnclient_engine::ConnectionStatus::DISCONNECTED: return 0;
        case vpnclient_engine::ConnectionStatus::CONNECTING: return 1;
        case vpnclient_engine::ConnectionStatus::CONNECTED: return 2;
        case vpnclient_engine::ConnectionStatus::DISCONNECTING: return 3;
        case vpnclient_engine::ConnectionStatus::ERROR: return 4;
        default: return 0;
    }
}

bool vpnclient_engine_get_stats(VPNClientEngineInstance instance, VPNClientEngineStats* stats) {
    if (!instance || !stats) return false;
    
    auto engine = static_cast<vpnclient_engine::VPNClientEngine*>(instance);
    auto cpp_stats = engine->get_stats();
    
    stats->bytes_sent = cpp_stats.bytes_sent;
    stats->bytes_received = cpp_stats.bytes_received;
    stats->packets_sent = cpp_stats.packets_sent;
    stats->packets_received = cpp_stats.packets_received;
    stats->latency_ms = cpp_stats.latency_ms;
    
    return true;
}

void vpnclient_engine_destroy(VPNClientEngineInstance instance) {
    if (!instance) return;
    
    auto engine = static_cast<vpnclient_engine::VPNClientEngine*>(instance);
    delete engine;
}

} // extern "C"


