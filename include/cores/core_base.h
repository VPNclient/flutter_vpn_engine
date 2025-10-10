#pragma once

#include "../vpnclient_engine.h"
#include <string>
#include <memory>

namespace vpnclient_engine {
namespace cores {

// Базовый класс для всех ядер
class BaseCore : public ICore {
public:
    BaseCore() = default;
    virtual ~BaseCore() = default;
    
    // Общая реализация
    bool is_running() const override { return running_; }
    std::string get_name() const override { return name_; }
    std::string get_version() const override { return version_; }
    
protected:
    bool running_ = false;
    std::string name_ = "BaseCore";
    std::string version_ = "unknown";
    CoreConfig config_;
    
    // Логирование
    void log(const std::string& level, const std::string& message);
};

} // namespace cores
} // namespace vpnclient_engine

