#include "platform/i_platform_interface.h"
#include <stdexcept>

// TODO: Добавить реальные реализации для каждой платформы
// Пока используем заглушку для всех платформ
// Реальные реализации должны быть интегрированы через Dart layer

namespace vpnclient_engine {
namespace platform {

// Заглушка для платформ, где реализация еще не готова
class StubPlatformInterface : public IPlatformInterface {
public:
    TunHandle openTun(const TunOptions& options) override {
        throw std::runtime_error("Platform interface not implemented for this platform");
    }
    
    void closeTun(const TunHandle& handle) override {}
    
    bool setupRoutes(const TunOptions& options) override {
        return false;
    }
    
    bool checkPrivileges() override {
        return false;
    }
    
    bool setupPerAppProxy(
        const std::vector<std::string>& packages,
        const std::string& mode
    ) override {
        return false;
    }
    
    void clearDNSCache() override {}
    
    std::vector<NetworkInterfaceInfo> getNetworkInterfaces() override {
        return {};
    }
    
    std::string getPlatformName() const override {
        return "stub";
    }
};

} // namespace platform
} // namespace vpnclient_engine

namespace vpnclient_engine {
namespace platform {

std::unique_ptr<IPlatformInterface> PlatformInterfaceFactory::create() {
    // TODO: Реализовать реальные платформо-специфичные интерфейсы
    // Пока используем заглушку - реальная работа с TUN должна происходить через Dart layer
    // (MethodChannel для Android/iOS, FFI для Linux/macOS/Windows)
    return std::make_unique<StubPlatformInterface>();
}

std::unique_ptr<IPlatformInterface> PlatformInterfaceFactory::createForPlatform(
    const std::string& platform
) {
    // TODO: Реализовать реальные платформо-специфичные интерфейсы
    return std::make_unique<StubPlatformInterface>();
}

} // namespace platform
} // namespace vpnclient_engine

