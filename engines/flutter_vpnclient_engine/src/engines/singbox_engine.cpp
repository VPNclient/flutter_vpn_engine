#include "engine/unified_engine.h"
#include "platform/i_platform_interface.h"
#include "cores/singbox_core.h"
#include <memory>
#include <stdexcept>
#include "engines/singbox_engine.h"

namespace vpnclient_engine {
namespace engine {

class SingBoxEngine : public IUnifiedEngine {
private:
    std::shared_ptr<platform::IPlatformInterface> platform_;
    std::unique_ptr<cores::SingBoxCore> core_;
    platform::TunHandle tun_handle_;
    ConnectionStatus status_ = ConnectionStatus::DISCONNECTED;
    EngineConfig config_;

public:
    SingBoxEngine() = default;
    ~SingBoxEngine() override {
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

        // Создаем SingBox core
        cores::CoreConfig core_config;
        core_config.config_json = config.config_json;
        core_config.enable_logging = true;
        
        core_ = std::make_unique<cores::SingBoxCore>();
        if (!core_->initialize(core_config)) {
            platform_->closeTun(tun_handle_);
            return false;
        }

        // Настраиваем SingBox для работы с TUN handle
        // TODO: Реализовать передачу file descriptor в SingBox
        // Пока SingBox core использует стандартную инициализацию

        // Настраиваем маршруты если нужно
        if (config.tun_options.auto_route) {
            platform_->setupRoutes(config.tun_options);
        }

        status_ = ConnectionStatus::DISCONNECTED;
        return true;
    }

    bool start() override {
        if (!core_ || !tun_handle_.isValid()) {
            return false;
        }

        status_ = ConnectionStatus::CONNECTING;
        if (config_.status_callback) {
            config_.status_callback(status_);
        }

        if (!core_->start()) {
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
        if (core_ && isRunning()) {
            status_ = ConnectionStatus::DISCONNECTING;
            if (config_.status_callback) {
                config_.status_callback(status_);
            }

            core_->stop();
            core_.reset();

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
        return core_ && core_->is_running() && tun_handle_.isValid();
    }

    ConnectionStatus getStatus() const override {
        return status_;
    }

    ConnectionStats getStats() const override {
        ConnectionStats stats;
        if (core_) {
            // Получаем статистику из SingBox core
            // TODO: Реализовать получение статистики
        }
        return stats;
    }

    std::string getName() const override {
        return "SingBox";
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
std::unique_ptr<IUnifiedEngine> createSingBoxEngine() {
    return std::make_unique<SingBoxEngine>();
}

} // namespace engine
} // namespace vpnclient_engine

