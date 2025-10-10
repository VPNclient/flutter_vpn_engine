#pragma once

#include "../vpnclient_engine.h"
#include <string>
#include <memory>

namespace vpnclient_engine {
namespace drivers {

// Базовый класс для всех драйверов
class BaseDriver : public IDriver {
public:
    BaseDriver() = default;
    virtual ~BaseDriver() = default;
    
    // Общая реализация
    bool is_running() const override { return running_; }
    std::string get_name() const override { return name_; }
    
protected:
    bool running_ = false;
    std::string name_ = "BaseDriver";
    DriverConfig config_;
    
    // Логирование
    void log(const std::string& level, const std::string& message);
};

} // namespace drivers
} // namespace vpnclient_engine


