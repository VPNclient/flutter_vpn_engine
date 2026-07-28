#pragma once

#include <memory>
#include <string>
#include <vector>

namespace vpnclient_engine {
namespace platform {

// Forward declarations
struct TunOptions;
struct TunHandle;

/// Опции для настройки TUN интерфейса
struct TunOptions {
    int mtu = 1500;
    std::string tun_name = "tun0";
    
    // IPv4 настройки
    std::string ipv4_address;
    std::string ipv4_netmask;
    std::string ipv4_gateway;
    
    // IPv6 настройки
    std::string ipv6_address;
    int ipv6_prefix = 64;
    
    // DNS настройки
    std::string dns_server;
    std::vector<std::string> dns_servers;
    
    // Маршрутизация
    bool auto_route = true;
    bool strict_route = false;
    bool enable_ipv6 = false;
    
    // Per-app proxy (Android)
    bool enable_per_app_proxy = false;
    std::vector<std::string> include_packages;
    std::vector<std::string> exclude_packages;
};

/// Handle для TUN интерфейса
struct TunHandle {
    int fd = -1;  // File descriptor (или handle на Windows)
    std::string platform;
    
    TunHandle() = default;
    TunHandle(int file_descriptor, const std::string& plat)
        : fd(file_descriptor), platform(plat) {}
    
    bool isValid() const { return fd >= 0; }
};

/// Информация о сетевом интерфейсе
struct NetworkInterfaceInfo {
    std::string name;
    std::string address;
    int index = 0;
    int mtu = 1500;
    bool is_up = false;
};

/// Интерфейс для платформо-специфичных операций с TUN
/// Абстрагирует детали работы с TUN на разных платформах
class IPlatformInterface {
public:
    virtual ~IPlatformInterface() = default;
    
    /// Открыть TUN интерфейс с заданными опциями
    /// Возвращает handle для работы с TUN
    virtual TunHandle openTun(const TunOptions& options) = 0;
    
    /// Закрыть TUN интерфейс
    virtual void closeTun(const TunHandle& handle) = 0;
    
    /// Настроить маршруты для TUN интерфейса
    virtual bool setupRoutes(const TunOptions& options) = 0;
    
    /// Проверить наличие необходимых привилегий
    virtual bool checkPrivileges() = 0;
    
    /// Настроить per-app proxy (поддерживается только на Android)
    /// packages - список package names приложений
    /// mode - "include" или "exclude"
    virtual bool setupPerAppProxy(
        const std::vector<std::string>& packages,
        const std::string& mode
    ) = 0;
    
    /// Очистить DNS кеш (если поддерживается платформой)
    virtual void clearDNSCache() = 0;
    
    /// Получить список сетевых интерфейсов
    virtual std::vector<NetworkInterfaceInfo> getNetworkInterfaces() = 0;
    
    /// Получить название платформы
    virtual std::string getPlatformName() const = 0;
};

/// Фабрика для создания платформо-специфичных реализаций
class PlatformInterfaceFactory {
public:
    /// Создать экземпляр IPlatformInterface для текущей платформы
    static std::unique_ptr<IPlatformInterface> create();
    
    /// Создать экземпляр для указанной платформы (для тестирования)
    static std::unique_ptr<IPlatformInterface> createForPlatform(
        const std::string& platform
    );
};

} // namespace platform
} // namespace vpnclient_engine

