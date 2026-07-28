#pragma once

#include <memory>
#include <string>
#include <functional>
#include "../platform/i_platform_interface.h"

namespace vpnclient_engine {
namespace engine {

// Forward declarations
struct EngineConfig;
struct ConnectionStats;

enum class ConnectionStatus {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR
};

/// Статистика соединения
struct ConnectionStats {
    uint64_t bytes_sent = 0;
    uint64_t bytes_received = 0;
    uint64_t packets_sent = 0;
    uint64_t packets_received = 0;
    uint32_t latency_ms = 0;
};

/// Конфигурация движка
struct EngineConfig {
    enum class CoreType {
        SINGBOX,
        LIBXRAY,
        V2RAY,
        WIREGUARD
    };
    
    enum class DriverType {
        NONE,
        HEV_SOCKS5,
        TUN2SOCKS
    };
    
    CoreType core_type;
    std::string config_json;
    
    // TUN опции
    platform::TunOptions tun_options;
    bool use_native_tun = false;  // true для SingBox (встроенный TUN)
    
    // Драйвер (если нужен)
    DriverType driver_type = DriverType::NONE;
    
    // Callbacks
    std::function<void(const std::string&, const std::string&)> log_callback;
    std::function<void(ConnectionStatus)> status_callback;
    std::function<void(const ConnectionStats&)> stats_callback;
};

/// Единый интерфейс для всех движков VPN
/// Абстрагирует различия между разными ядрами (SingBox, LibXray, V2Ray)
class IUnifiedEngine {
public:
    virtual ~IUnifiedEngine() = default;
    
    /// Инициализация движка с конфигурацией и платформенным интерфейсом
    /// platform - платформенный интерфейс для работы с TUN
    virtual bool initialize(
        const EngineConfig& config,
        std::shared_ptr<platform::IPlatformInterface> platform
    ) = 0;
    
    /// Запуск движка
    virtual bool start() = 0;
    
    /// Остановка движка
    virtual void stop() = 0;
    
    /// Проверка, запущен ли движок
    virtual bool isRunning() const = 0;
    
    /// Получить статус соединения
    virtual ConnectionStatus getStatus() const = 0;
    
    /// Получить статистику соединения
    virtual ConnectionStats getStats() const = 0;
    
    /// Получить название движка
    virtual std::string getName() const = 0;
    
    /// Получить версию движка
    virtual std::string getVersion() const = 0;
    
    /// Тестирование соединения
    virtual bool testConnection() = 0;
};

/// Фабрика для создания движков
class UnifiedEngineFactory {
public:
    /// Создать движок для указанного типа ядра
    static std::unique_ptr<IUnifiedEngine> create(EngineConfig::CoreType type);
    
    /// Определить, требуется ли драйвер для ядра
    static bool requiresDriver(EngineConfig::CoreType type);
    
    /// Получить рекомендуемый драйвер для ядра
    static EngineConfig::DriverType getRecommendedDriver(EngineConfig::CoreType type);
};

} // namespace engine
} // namespace vpnclient_engine

