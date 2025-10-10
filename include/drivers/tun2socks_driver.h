#pragma once

#include "driver_base.h"

namespace vpnclient_engine {
namespace drivers {

// Адаптер для flutter_vpn_tun2socks
class Tun2SocksDriver : public BaseDriver {
public:
    Tun2SocksDriver();
    ~Tun2SocksDriver() override;
    
    bool initialize(const DriverConfig& config) override;
    bool start() override;
    void stop() override;
    std::string get_name() const override { return "Tun2SocksDriver"; }
    
private:
    void* tun2socks_instance_ = nullptr;  // Указатель на экземпляр tun2socks
    
    bool init_tun2socks();
    void cleanup_tun2socks();
};

} // namespace drivers
} // namespace vpnclient_engine

