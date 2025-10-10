#pragma once

#include "core_base.h"

namespace vpnclient_engine {
namespace cores {

// Адаптер для flutter_vpn_singbox
class SingBoxCore : public BaseCore {
public:
    SingBoxCore();
    ~SingBoxCore() override;
    
    bool initialize(const CoreConfig& config) override;
    bool start() override;
    void stop() override;
    std::string get_name() const override { return "SingBox"; }
    std::string get_version() const override;
    
private:
    void* singbox_instance_ = nullptr;  // Указатель на экземпляр sing-box
    
    bool init_singbox();
    void cleanup_singbox();
    std::string parse_config_to_singbox_format(const std::string& config_json);
};

} // namespace cores
} // namespace vpnclient_engine

