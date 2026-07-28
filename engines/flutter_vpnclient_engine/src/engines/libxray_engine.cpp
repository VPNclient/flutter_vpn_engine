#include "engine/unified_engine.h"
#include "platform/i_platform_interface.h"
#include "cores/libxray_core.h"
#include "../vpnclient_engine.h"
#include "engines/libxray_engine.h"
#include <memory>
#include <stdexcept>

namespace vpnclient_engine {
namespace engine {

class LibXrayEngine : public IUnifiedEngine {
private:
    std::shared_ptr<platform::IPlatformInterface> platform_;
    std::unique_ptr<cores::LibXrayCore> core_;
    std::unique_ptr<drivers::IDriver> driver_;
    platform::TunHandle tun_handle_;
    ConnectionStatus status_ = ConnectionStatus::DISCONNECTED;
    EngineConfig config_;

public:
    LibXrayEngine() = default;
    ~LibXrayEngine() override {
        if (isRunning()) {
            stop();
        }
    }

    bool initialize(
        const EngineConfig& config,
        std::shared_ptr<platform::IPlatformInterface> platform
    ) override {
        if (!platform) {
            return false;
        }

        config_ = config;
        platform_ = platform;

        // Проверяем привилегии
        if (!platform_->checkPrivileges()) {
            return false;
        }

        // Открываем TUN интерфейс через PlatformInterface
        tun_handle_ = platform_->openTun(config.tun_options);
        if (!tun_handle_.isValid()) {
            return false;
        }

        // Создаем драйвер (hev-socks5 или tun2socks)
        vpnclient_engine::DriverConfig driver_config;
        driver_config.type = (config.driver_type == EngineConfig::DriverType::HEV_SOCKS5)
            ? vpnclient_engine::DriverType::HEV_SOCKS5
            : vpnclient_engine::DriverType::TUN2SOCKS;
        driver_config.config_json = config.config_json;
        driver_config.mtu = config.tun_options.mtu;
        driver_config.tun_name = config.tun_options.tun_name;
        driver_config.tun_address = config.tun_options.ipv4_address;
        driver_config.tun_gateway = config.tun_options.ipv4_gateway;
        driver_config.tun_netmask = config.tun_options.ipv4_netmask;
        driver_config.dns_server = config.tun_options.dns_server;

        // Определяем тип драйвера
        drivers::DriverType driver_type;
        switch (config.driver_type) {
            case EngineConfig::DriverType::HEV_SOCKS5:
                driver_type = drivers::DriverType::HEV_SOCKS5;
                break;
            case EngineConfig::DriverType::TUN2SOCKS:
                driver_type = drivers::DriverType::TUN2SOCKS;
                break;
            default:
                driver_type = drivers::DriverType::HEV_SOCKS5; // По умолчанию
                break;
        }

        driver_ = vpnclient_engine::DriverFactory::create(driver_type);
        if (!driver_) {
            platform_->closeTun(tun_handle_);
            return false;
        }

        if (!driver_->initialize(driver_config)) {
            platform_->closeTun(tun_handle_);
            return false;
        }

        // Создаем LibXray core с SOCKS прокси
        cores::CoreConfig core_config;
        core_config.config_json = config.config_json;
        core_config.enable_logging = true;
        
        core_ = std::make_unique<cores::LibXrayCore>();
        if (!core_->initialize(core_config)) {
            driver_.reset();
            platform_->closeTun(tun_handle_);
            return false;
        }

        // Настраиваем LibXray для работы через SOCKS прокси (обычно 127.0.0.1:1080)
        // TODO: Реализовать настройку SOCKS прокси в LibXray core
        // SOCKS прокси будет доступен через драйвер на порту 1080

        // Настраиваем маршруты если нужно
        if (config.tun_options.auto_route) {
            platform_->setupRoutes(config.tun_options);
        }

        status_ = ConnectionStatus::DISCONNECTED;
        return true;
    }

    bool start() override {
        if (!core_ || !driver_ || !tun_handle_.isValid()) {
            return false;
        }

        status_ = ConnectionStatus::CONNECTING;
        if (config_.status_callback) {
            config_.status_callback(status_);
        }

        // Запускаем драйвер сначала
        if (!driver_->start()) {
            status_ = ConnectionStatus::ERROR;
            if (config_.status_callback) {
                config_.status_callback(status_);
            }
            return false;
        }

        // Затем запускаем ядро
        if (!core_->start()) {
            driver_->stop();
            status_ = ConnectionStatus::ERROR;
            if (config_.status_callback) {
                config_.status_callback(status_);
            }
            return false;
        }

        status_ = ConnectionStatus::CONNECTED;
        if (config_.status_callback) {
            config_.status_callback(status_);
        }

        return true;
    }

    void stop() override {
        if (isRunning()) {
            status_ = ConnectionStatus::DISCONNECTING;
            if (config_.status_callback) {
                config_.status_callback(status_);
            }

            if (core_) {
                core_->stop();
                core_.reset();
            }

            if (driver_) {
                driver_->stop();
                driver_.reset();
            }

            if (platform_ && tun_handle_.isValid()) {
                platform_->closeTun(tun_handle_);
                tun_handle_.fd = -1;
            }

            status_ = ConnectionStatus::DISCONNECTED;
            if (config_.status_callback) {
                config_.status_callback(status_);
            }
        }
    }

    bool isRunning() const override {
        return core_ && core_->is_running() 
            && driver_ && driver_->is_running() 
            && tun_handle_.isValid();
    }

    ConnectionStatus getStatus() const override {
        return status_;
    }

    ConnectionStats getStats() const override {
        ConnectionStats stats;
        if (core_) {
            // Получаем статистику из LibXray core
            // TODO: Реализовать получение статистики
        }
        return stats;
    }

    std::string getName() const override {
        return "LibXray";
    }

    std::string getVersion() const override {
        if (core_) {
            return core_->get_version();
        }
        return "Unknown";
    }

    bool testConnection() override {
        // TODO: Реализовать тестирование соединения
        return false;
    }
};

// Экспорт через фабрику
std::unique_ptr<IUnifiedEngine> createLibXrayEngine() {
    return std::make_unique<LibXrayEngine>();
}

} // namespace engine
} // namespace vpnclient_engine

