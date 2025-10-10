#pragma once

#include "driver_base.h"

namespace vpnclient_engine {
namespace drivers {

// Адаптер для flutter_vpn_hev5socks
class HevSocks5Driver : public BaseDriver {
public:
    HevSocks5Driver();
    ~HevSocks5Driver() override;
    
    bool initialize(const DriverConfig& config) override;
    bool start() override;
    void stop() override;
    std::string get_name() const override { return "HevSocks5Driver"; }
    
private:
    void* hev_instance_ = nullptr;  // Указатель на экземпляр hev-socks5
    
    bool init_hev_socks5();
    void cleanup_hev_socks5();
};

} // namespace drivers
} // namespace vpnclient_engine


