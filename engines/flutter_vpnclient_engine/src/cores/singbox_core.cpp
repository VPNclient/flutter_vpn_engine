#include "cores/singbox_core.h"
#include <sstream>

// Подключаем заголовочные файлы flutter_vpn_singbox
extern "C" {
    #include "singbox_c_api.h"
}

namespace vpnclient_engine {
namespace cores {

SingBoxCore::SingBoxCore() {
    name_ = "SingBox";
    version_ = "1.8.0"; // TODO: Получать версию из библиотеки
}

SingBoxCore::~SingBoxCore() {
    if (running_) {
        stop();
    }
    cleanup_singbox();
}

bool SingBoxCore::initialize(const CoreConfig& config) {
    config_ = config;
    
    log("INFO", "Initializing SingBox core");
    
    if (!init_singbox()) {
        log("ERROR", "Failed to initialize SingBox");
        return false;
    }
    
    log("INFO", "SingBox core initialized successfully");
    return true;
}

bool SingBoxCore::start() {
    if (running_) {
        log("WARN", "Core already running");
        return true;
    }
    
    log("INFO", "Starting SingBox core");
    
    SingBoxInstance instance = static_cast<SingBoxInstance>(singbox_instance_);
    if (!instance || !singbox_start(instance)) {
        log("ERROR", "Failed to start SingBox");
        return false;
    }
    
    running_ = true;
    log("INFO", "SingBox core started");
    return true;
}

void SingBoxCore::stop() {
    if (!running_) {
        return;
    }
    
    log("INFO", "Stopping SingBox core");
    
    SingBoxInstance instance = static_cast<SingBoxInstance>(singbox_instance_);
    if (instance) {
        singbox_stop(instance);
    }
    
    running_ = false;
    log("INFO", "SingBox core stopped");
}

std::string SingBoxCore::get_version() const {
    return singbox_get_version();
}

bool SingBoxCore::init_singbox() {
    singbox_instance_ = singbox_create();
    if (!singbox_instance_) {
        return false;
    }
    
    SingBoxConfig singbox_config;
    singbox_config.config_json = parse_config_to_singbox_format(config_.config_json).c_str();
    singbox_config.working_dir = nullptr;
    singbox_config.disable_color = true;
    singbox_config.log_level = config_.enable_logging ? 4 : 0;
    
    return singbox_init(static_cast<SingBoxInstance>(singbox_instance_), &singbox_config);
}

void SingBoxCore::cleanup_singbox() {
    if (singbox_instance_) {
        singbox_destroy(static_cast<SingBoxInstance>(singbox_instance_));
        singbox_instance_ = nullptr;
    }
}

std::string SingBoxCore::parse_config_to_singbox_format(const std::string& config_json) {
    // Конфигурация уже в формате JSON для sing-box
    return config_json;
}

} // namespace cores
} // namespace vpnclient_engine

