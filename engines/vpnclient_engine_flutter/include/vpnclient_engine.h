#pragma once

#include <memory>
#include <string>
#include <functional>

namespace vpnclient_engine {

// ====== ДРАЙВЕРЫ (Drivers) ======
// Драйверы отвечают за туннелирование трафика
enum class DriverType {
    NONE,           // Без драйвера (прямое подключение)
    HEV_SOCKS5,    // hev-socks5-tunnel
    TUN2SOCKS      // tun2socks
};

// ====== ЯДРА (Cores) ======
// Ядра отвечают за протоколы VPN
enum class CoreType {
    SINGBOX,       // sing-box
    LIBXRAY,       // libxray
    V2RAY,         // v2ray
    WIREGUARD      // wireguard (опционально)
};

// Статус соединения
enum class ConnectionStatus {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR
};

// Базовая конфигурация
struct BaseConfig {
    std::string config_json;    // JSON конфигурация
    bool enable_logging = true;
    std::string log_level = "info";
};

// Конфигурация драйвера
struct DriverConfig : public BaseConfig {
    DriverType type = DriverType::NONE;
    uint16_t mtu = 1500;
    std::string tun_name = "tun0";
    std::string tun_address = "10.0.0.2";
    std::string tun_gateway = "10.0.0.1";
    std::string tun_netmask = "255.255.255.0";
    std::string dns_server = "8.8.8.8";
};

// Конфигурация ядра
struct CoreConfig : public BaseConfig {
    CoreType type = CoreType::SINGBOX;
    std::string server_address;
    uint16_t server_port = 0;
    std::string protocol;  // vless, vmess, shadowsocks, etc.
};

// Общая конфигурация VPN Engine
struct Config {
    CoreConfig core;          // Конфигурация ядра
    DriverConfig driver;      // Конфигурация драйвера
    
    bool auto_connect = false;
    int connection_timeout = 30; // секунды
};

// Статистика соединения
struct ConnectionStats {
    uint64_t bytes_sent = 0;
    uint64_t bytes_received = 0;
    uint64_t packets_sent = 0;
    uint64_t packets_received = 0;
    uint32_t latency_ms = 0;
};

// ====== ИНТЕРФЕЙСЫ АДАПТЕРОВ ======

// Базовый интерфейс драйвера
class IDriver {
public:
    virtual ~IDriver() = default;
    virtual bool initialize(const DriverConfig& config) = 0;
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual bool is_running() const = 0;
    virtual std::string get_name() const = 0;
};

// Базовый интерфейс ядра
class ICore {
public:
    virtual ~ICore() = default;
    virtual bool initialize(const CoreConfig& config) = 0;
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual bool is_running() const = 0;
    virtual std::string get_name() const = 0;
    virtual std::string get_version() const = 0;
};

// ====== ОСНОВНОЙ КЛАСС VPN ENGINE ======

class VPNClientEngine {
public:
    using LogCallback = std::function<void(const std::string& level, const std::string& message)>;
    using StatusCallback = std::function<void(ConnectionStatus status)>;
    using StatsCallback = std::function<void(const ConnectionStats& stats)>;
    
    // Создание экземпляра
    static std::unique_ptr<VPNClientEngine> create(const Config& config);
    
    // Управление соединением
    virtual bool connect() = 0;
    virtual void disconnect() = 0;
    virtual ConnectionStatus get_status() const = 0;
    virtual ConnectionStats get_stats() const = 0;
    
    // Callbacks
    virtual void set_log_callback(LogCallback callback) = 0;
    virtual void set_status_callback(StatusCallback callback) = 0;
    virtual void set_stats_callback(StatsCallback callback) = 0;
    
    // Информация
    virtual std::string get_core_name() const = 0;
    virtual std::string get_core_version() const = 0;
    virtual std::string get_driver_name() const = 0;
    
    // Тестирование
    virtual bool test_connection() = 0;
    
    virtual ~VPNClientEngine() = default;
    
protected:
    VPNClientEngine() = default;
};

// ====== ФАБРИКА АДАПТЕРОВ ======

// Фабрика для создания драйверов
class DriverFactory {
public:
    static std::unique_ptr<IDriver> create(DriverType type);
    static std::string get_driver_name(DriverType type);
};

// Фабрика для создания ядер
class CoreFactory {
public:
    static std::unique_ptr<ICore> create(CoreType type);
    static std::string get_core_name(CoreType type);
    static std::string get_core_version(CoreType type);
};

} // namespace vpnclient_engine
