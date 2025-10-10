#pragma once

#include "core_base.h"

namespace vpnclient_engine {
namespace cores {

// Адаптер для flutter_v2ray
class V2RayCore : public BaseCore {
public:
    V2RayCore();
    ~V2RayCore() override;
    
    bool initialize(const CoreConfig& config) override;
    bool start() override;
    void stop() override;
    std::string get_name() const override { return "V2Ray"; }
    std::string get_version() const override;
    
private:
    void* v2ray_instance_ = nullptr;  // Указатель на экземпляр v2ray
    
    bool init_v2ray();
    void cleanup_v2ray();
    std::string parse_config_to_v2ray_format(const std::string& config_json);
};

} // namespace cores
} // namespace vpnclient_engine


