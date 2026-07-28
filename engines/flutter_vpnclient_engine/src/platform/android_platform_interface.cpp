#include "platform/i_platform_interface.h"
#include <stdexcept>
#include <unistd.h>

#ifdef __ANDROID__

namespace vpnclient_engine {
namespace platform {

class AndroidPlatformInterface : public IPlatformInterface {
public:
    TunHandle openTun(const TunOptions& options) override {
        // TODO: Реализовать через Android VPN API (VpnService)
        // Это должно вызываться из Dart через MethodChannel
        // Здесь возвращаем заглушку
        throw std::runtime_error("Android platform interface should be called from Dart layer");
    }
    
    void closeTun(const TunHandle& handle) override {
        if (handle.isValid()) {
            close(handle.fd);
        }
    }
    
    bool setupRoutes(const TunOptions& options) override {
        // TODO: Реализовать через Android VPN API
        return true;
    }
    
    bool checkPrivileges() override {
        // TODO: Проверить через Android VPN API
        return true;
    }
    
    bool setupPerAppProxy(
        const std::vector<std::string>& packages,
        const std::string& mode
    ) override {
        // TODO: Реализовать через Android VPN API
        return true;
    }
    
    void clearDNSCache() override {
        // DNS кеш очищается автоматически через VPN API
    }
    
    std::vector<NetworkInterfaceInfo> getNetworkInterfaces() override {
        // TODO: Реализовать получение интерфейсов
        return {};
    }
    
    std::string getPlatformName() const override {
        return "android";
    }
};

} // namespace platform
} // namespace vpnclient_engine

#endif // __ANDROID__

