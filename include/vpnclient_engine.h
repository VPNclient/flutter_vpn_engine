#pragma once

#include <memory>
#include <string>
#include <functional>

namespace vpnclient_engine {

enum class EngineType {
    VPNCLIENTXRAY, //VPNclient-xray-wrapper
    LIBXRAY     // libxray
    SINGBOX,    // sing-box
    WIREGUARD,  // libwg
    OPENVPN,

};

enum class ProxyMode {
    NONE,       // Прямое подключение
    VPNCLIENTDRIVER,  // VPNclient-driver
    TUN2SOCKS,  // tun2socks
    HEV_SOCKS5, // hev-socks5
    APPROXY     // approxy
};

struct Config {
    EngineType engine = EngineType::VPNCLIENTXRAY;
    ProxyMode proxy = ProxyMode::VPNCLIENTDRIVER;
    
    // Пути к конфигурационным файлам
    std::string engine_config;
    std::string proxy_config;
    
    bool enable_logging = true;
};

class VPNClientEngine {
public:
    using LogCallback = std::function<void(const std::string&)>;
    
    static std::unique_ptr<VPNClientEngine> create(const Config& config);
    
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual ~VPNClientEngine() = default;
    
    void set_log_callback(LogCallback callback);
};

} // namespace vpnclient_engine