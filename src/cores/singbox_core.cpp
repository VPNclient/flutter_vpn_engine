#include "cores/singbox_core.h"
#include <sstream>

// Подключаем заголовочные файлы flutter_vpn_singbox
extern "C" {
    // TODO: Подключить реальные заголовочные файлы из flutter_vpn_singbox
    // #include "singbox.h"
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
    
    // TODO: Реализовать запуск sing-box
    // Пример:
    // std::string config_json = parse_config_to_singbox_format(config_.config_json);
    // singbox_instance_ = singbox_create(config_json.c_str());
    // if (!singbox_instance_) {
    //     log("ERROR", "Failed to create SingBox instance");
    //     return false;
    // }
    // if (!singbox_start(singbox_instance_)) {
    //     log("ERROR", "Failed to start SingBox");
    //     return false;
    // }
    
    running_ = true;
    log("INFO", "SingBox core started");
    return true;
}

void SingBoxCore::stop() {
    if (!running_) {
        return;
    }
    
    log("INFO", "Stopping SingBox core");
    
    // TODO: Реализовать остановку sing-box
    // if (singbox_instance_) {
    //     singbox_stop(singbox_instance_);
    // }
    
    running_ = false;
    log("INFO", "SingBox core stopped");
}

std::string SingBoxCore::get_version() const {
    // TODO: Получать версию из библиотеки
    // return singbox_version();
    return version_;
}

bool SingBoxCore::init_singbox() {
    // TODO: Инициализация библиотеки sing-box
    return true;
}

void SingBoxCore::cleanup_singbox() {
    // TODO: Очистка ресурсов sing-box
    if (singbox_instance_) {
        // singbox_destroy(singbox_instance_);
        singbox_instance_ = nullptr;
    }
}

std::string SingBoxCore::parse_config_to_singbox_format(const std::string& config_json) {
    // TODO: Преобразовать конфигурацию в формат sing-box
    // В зависимости от входного формата, может потребоваться конвертация
    return config_json;
}

} // namespace cores
} // namespace vpnclient_engine

