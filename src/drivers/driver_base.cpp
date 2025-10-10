#include "drivers/driver_base.h"
#include <iostream>

namespace vpnclient_engine {
namespace drivers {

void BaseDriver::log(const std::string& level, const std::string& message) {
    // Базовое логирование в stdout/stderr
    if (level == "ERROR") {
        std::cerr << "[" << name_ << "][" << level << "] " << message << std::endl;
    } else {
        std::cout << "[" << name_ << "][" << level << "] " << message << std::endl;
    }
}

} // namespace drivers
} // namespace vpnclient_engine

