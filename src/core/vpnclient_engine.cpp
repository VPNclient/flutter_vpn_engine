#include "vpnclient_engine.h"
#include "cores/singbox_core.h"
#include "cores/libxray_core.h"
#include "cores/v2ray_core.h"
#include "drivers/hev_socks5_driver.h"
#include "drivers/tun2socks_driver.h"
#include <memory>
#include <mutex>

namespace vpnclient_engine {

// ====== ФАБРИКА ДРАЙВЕРОВ ======

std::unique_ptr<IDriver> DriverFactory::create(DriverType type) {
    switch (type) {
        case DriverType::HEV_SOCKS5:
            return std::make_unique<drivers::HevSocks5Driver>();
        case DriverType::TUN2SOCKS:
            return std::make_unique<drivers::Tun2SocksDriver>();
        case DriverType::NONE:
        default:
            return nullptr;
    }
}

std::string DriverFactory::get_driver_name(DriverType type) {
    switch (type) {
        case DriverType::HEV_SOCKS5:
            return "HevSocks5Driver";
        case DriverType::TUN2SOCKS:
            return "Tun2SocksDriver";
        case DriverType::NONE:
        default:
            return "None";
    }
}

// ====== ФАБРИКА ЯДЕР ======

std::unique_ptr<ICore> CoreFactory::create(CoreType type) {
    switch (type) {
        case CoreType::SINGBOX:
            return std::make_unique<cores::SingBoxCore>();
        case CoreType::LIBXRAY:
            return std::make_unique<cores::LibXrayCore>();
        case CoreType::V2RAY:
            return std::make_unique<cores::V2RayCore>();
        default:
            return nullptr;
    }
}

std::string CoreFactory::get_core_name(CoreType type) {
    switch (type) {
        case CoreType::SINGBOX:
            return "SingBox";
        case CoreType::LIBXRAY:
            return "LibXray";
        case CoreType::V2RAY:
            return "V2Ray";
        case CoreType::WIREGUARD:
            return "WireGuard";
        default:
            return "Unknown";
    }
}

std::string CoreFactory::get_core_version(CoreType type) {
    auto core = create(type);
    if (core) {
        return core->get_version();
    }
    return "unknown";
}

// ====== РЕАЛИЗАЦИЯ VPN ENGINE ======

class VPNClientEngineImpl : public VPNClientEngine {
public:
    explicit VPNClientEngineImpl(const Config& config)
        : config_(config)
        , status_(ConnectionStatus::DISCONNECTED)
    {
        // Создаем ядро
        core_ = CoreFactory::create(config.core.type);
        if (!core_) {
            throw std::runtime_error("Failed to create core");
        }
        
        // Создаем драйвер (если нужен)
        if (config.driver.type != DriverType::NONE) {
            driver_ = DriverFactory::create(config.driver.type);
            if (!driver_) {
                throw std::runtime_error("Failed to create driver");
            }
        }
    }
    
    ~VPNClientEngineImpl() override {
        disconnect();
    }
    
    bool connect() override {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (status_ == ConnectionStatus::CONNECTED || 
            status_ == ConnectionStatus::CONNECTING) {
            return false;
        }
        
        set_status(ConnectionStatus::CONNECTING);
        
        try {
            // Инициализируем ядро
            if (!core_->initialize(config_.core)) {
                log("ERROR", "Failed to initialize core");
                set_status(ConnectionStatus::ERROR);
                return false;
            }
            
            // Инициализируем драйвер (если есть)
            if (driver_ && !driver_->initialize(config_.driver)) {
                log("ERROR", "Failed to initialize driver");
                set_status(ConnectionStatus::ERROR);
                return false;
            }
            
            // Запускаем драйвер (если есть)
            if (driver_ && !driver_->start()) {
                log("ERROR", "Failed to start driver");
                set_status(ConnectionStatus::ERROR);
                return false;
            }
            
            // Запускаем ядро
            if (!core_->start()) {
                log("ERROR", "Failed to start core");
                if (driver_) {
                    driver_->stop();
                }
                set_status(ConnectionStatus::ERROR);
                return false;
            }
            
            set_status(ConnectionStatus::CONNECTED);
            log("INFO", "VPN connection established");
            return true;
            
        } catch (const std::exception& e) {
            log("ERROR", std::string("Exception during connect: ") + e.what());
            set_status(ConnectionStatus::ERROR);
            return false;
        }
    }
    
    void disconnect() override {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (status_ == ConnectionStatus::DISCONNECTED || 
            status_ == ConnectionStatus::DISCONNECTING) {
            return;
        }
        
        set_status(ConnectionStatus::DISCONNECTING);
        
        try {
            // Останавливаем ядро
            if (core_) {
                core_->stop();
            }
            
            // Останавливаем драйвер
            if (driver_) {
                driver_->stop();
            }
            
            set_status(ConnectionStatus::DISCONNECTED);
            log("INFO", "VPN disconnected");
            
        } catch (const std::exception& e) {
            log("ERROR", std::string("Exception during disconnect: ") + e.what());
            set_status(ConnectionStatus::DISCONNECTED);
        }
    }
    
    ConnectionStatus get_status() const override {
        return status_;
    }
    
    ConnectionStats get_stats() const override {
        if (!core_ || !core_->is_running()) {
            return stats_;
        }
        
        // Get stats from core if available
        // For now return accumulated stats
        return stats_;
    }
    
    void set_log_callback(LogCallback callback) override {
        log_callback_ = callback;
    }
    
    void set_status_callback(StatusCallback callback) override {
        status_callback_ = callback;
    }
    
    void set_stats_callback(StatsCallback callback) override {
        stats_callback_ = callback;
    }
    
    std::string get_core_name() const override {
        return core_ ? core_->get_name() : "None";
    }
    
    std::string get_core_version() const override {
        return core_ ? core_->get_version() : "unknown";
    }
    
    std::string get_driver_name() const override {
        return driver_ ? driver_->get_name() : "None";
    }
    
    bool test_connection() override {
        return status_ == ConnectionStatus::CONNECTED && 
               core_ && core_->is_running();
    }
    
private:
    Config config_;
    std::unique_ptr<ICore> core_;
    std::unique_ptr<IDriver> driver_;
    
    ConnectionStatus status_;
    ConnectionStats stats_;
    
    LogCallback log_callback_;
    StatusCallback status_callback_;
    StatsCallback stats_callback_;
    
    mutable std::mutex mutex_;
    
    void log(const std::string& level, const std::string& message) {
        if (log_callback_) {
            log_callback_(level, message);
        }
    }
    
    void set_status(ConnectionStatus status) {
        status_ = status;
        if (status_callback_) {
            status_callback_(status);
        }
    }
};

// Создание экземпляра
std::unique_ptr<VPNClientEngine> VPNClientEngine::create(const Config& config) {
    return std::make_unique<VPNClientEngineImpl>(config);
}

} // namespace vpnclient_engine
