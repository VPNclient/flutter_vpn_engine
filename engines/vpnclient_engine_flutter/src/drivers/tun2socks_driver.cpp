#include "drivers/tun2socks_driver.h"

// Подключаем заголовочные файлы flutter_vpn_tun2socks
extern "C" {
    #include "tun2socks_c_api.h"
}

namespace vpnclient_engine {
namespace drivers {

Tun2SocksDriver::Tun2SocksDriver() {
    name_ = "Tun2SocksDriver";
}

Tun2SocksDriver::~Tun2SocksDriver() {
    if (running_) {
        stop();
    }
    cleanup_tun2socks();
}

bool Tun2SocksDriver::initialize(const DriverConfig& config) {
    config_ = config;
    
    log("INFO", "Initializing Tun2Socks driver");
    
    if (!init_tun2socks()) {
        log("ERROR", "Failed to initialize Tun2Socks");
        return false;
    }
    
    log("INFO", "Tun2Socks driver initialized successfully");
    return true;
}

bool Tun2SocksDriver::start() {
    if (running_) {
        log("WARN", "Driver already running");
        return true;
    }
    
    log("INFO", "Starting Tun2Socks driver");
    
    Tun2SocksInstance instance = static_cast<Tun2SocksInstance>(tun2socks_instance_);
    if (!instance || !tun2socks_start(instance)) {
        log("ERROR", "Failed to start tun2socks");
        return false;
    }
    
    running_ = true;
    log("INFO", "Tun2Socks driver started");
    return true;
}

void Tun2SocksDriver::stop() {
    if (!running_) {
        return;
    }
    
    log("INFO", "Stopping Tun2Socks driver");
    
    Tun2SocksInstance instance = static_cast<Tun2SocksInstance>(tun2socks_instance_);
    if (instance) {
        tun2socks_stop(instance);
    }
    
    running_ = false;
    log("INFO", "Tun2Socks driver stopped");
}

bool Tun2SocksDriver::init_tun2socks() {
    tun2socks_instance_ = tun2socks_create();
    if (!tun2socks_instance_) {
        return false;
    }
    
    Tun2SocksConfig tun2_config;
    tun2_config.socks_server = config_.config_json.c_str();
    tun2_config.tun_address = config_.tun_address.c_str();
    tun2_config.tun_gateway = config_.tun_gateway.c_str();
    tun2_config.tun_mask = config_.tun_netmask.c_str();
    tun2_config.dns_server = config_.dns_server.c_str();
    tun2_config.tun_mtu = config_.mtu;
    tun2_config.tun_fd = -1;
    tun2_config.enable_ipv6 = false;
    tun2_config.log_level = config_.enable_logging ? 2 : 0;
    
    return tun2socks_init(static_cast<Tun2SocksInstance>(tun2socks_instance_), &tun2_config);
}

void Tun2SocksDriver::cleanup_tun2socks() {
    if (tun2socks_instance_) {
        tun2socks_destroy(static_cast<Tun2SocksInstance>(tun2socks_instance_));
        tun2socks_instance_ = nullptr;
    }
}

} // namespace drivers
} // namespace vpnclient_engine

