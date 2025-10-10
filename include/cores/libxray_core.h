#pragma once

#include "core_base.h"

namespace vpnclient_engine {
namespace cores {

// Адаптер для fork_vpn_libxray
class LibXrayCore : public BaseCore {
public:
    LibXrayCore();
    ~LibXrayCore() override;
    
    bool initialize(const CoreConfig& config) override;
    bool start() override;
    void stop() override;
    std::string get_name() const override { return "LibXray"; }
    std::string get_version() const override;
    
private:
    void* libxray_instance_ = nullptr;  // Указатель на экземпляр libxray
    
    bool init_libxray();
    void cleanup_libxray();
    std::string parse_config_to_xray_format(const std::string& config_json);
};

} // namespace cores
} // namespace vpnclient_engine


