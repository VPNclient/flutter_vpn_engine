#include "drivers/hev_socks5_driver.h"

// Подключаем заголовочные файлы flutter_vpn_hev5socks
extern "C" {
    #include "hev_socks5_c_api.h"
}

namespace vpnclient_engine {
namespace drivers {

HevSocks5Driver::HevSocks5Driver() {
    name_ = "HevSocks5Driver";
}

HevSocks5Driver::~HevSocks5Driver() {
    if (running_) {
        stop();
    }
    cleanup_hev_socks5();
}

bool HevSocks5Driver::initialize(const DriverConfig& config) {
    config_ = config;
    
    log("INFO", "Initializing HevSocks5 driver");
    
    if (!init_hev_socks5()) {
        log("ERROR", "Failed to initialize HevSocks5");
        return false;
    }
    
    log("INFO", "HevSocks5 driver initialized successfully");
    return true;
}

bool HevSocks5Driver::start() {
    if (running_) {
        log("WARN", "Driver already running");
        return true;
    }
    
    log("INFO", "Starting HevSocks5 driver");
    
    HevSocks5Instance instance = static_cast<HevSocks5Instance>(hev_instance_);
    if (!instance || !hev_socks5_start(instance)) {
        log("ERROR", "Failed to start hev-socks5-tunnel");
        return false;
    }
    
    running_ = true;
    log("INFO", "HevSocks5 driver started");
    return true;
}

void HevSocks5Driver::stop() {
    if (!running_) {
        return;
    }
    
    log("INFO", "Stopping HevSocks5 driver");
    
    HevSocks5Instance instance = static_cast<HevSocks5Instance>(hev_instance_);
    if (instance) {
        hev_socks5_stop(instance);
    }
    
    running_ = false;
    log("INFO", "HevSocks5 driver stopped");
}

bool HevSocks5Driver::init_hev_socks5() {
    hev_instance_ = hev_socks5_create();
    if (!hev_instance_) {
        return false;
    }
    
    HevSocks5Config hev_config;
    hev_config.socks5_server = config_.config_json.c_str();
    hev_config.tun_name = config_.tun_name.c_str();
    hev_config.tun_address = config_.tun_address.c_str();
    hev_config.tun_gateway = config_.tun_gateway.c_str();
    hev_config.tun_netmask = config_.tun_netmask.c_str();
    hev_config.dns_server = config_.dns_server.c_str();
    hev_config.tun_mtu = config_.mtu;
    hev_config.tun_fd = -1;
    hev_config.enable_ipv6 = config_.enable_logging;
    hev_config.username = nullptr;
    hev_config.password = nullptr;
    
    return hev_socks5_init(static_cast<HevSocks5Instance>(hev_instance_), &hev_config);
}

void HevSocks5Driver::cleanup_hev_socks5() {
    if (hev_instance_) {
        hev_socks5_destroy(static_cast<HevSocks5Instance>(hev_instance_));
        hev_instance_ = nullptr;
    }
}

} // namespace drivers
} // namespace vpnclient_engine

