#include "engine/unified_engine.h"
#include "engines/singbox_engine.h"
#include "engines/libxray_engine.h"
#include "engines/v2ray_engine.h"

// Forward declarations для реализации в соответствующих .cpp файлах
namespace vpnclient_engine {
namespace engine {
    std::unique_ptr<IUnifiedEngine> createSingBoxEngine();
    std::unique_ptr<IUnifiedEngine> createLibXrayEngine();
    std::unique_ptr<IUnifiedEngine> createV2RayEngine();
}
}

namespace vpnclient_engine {
namespace engine {

std::unique_ptr<IUnifiedEngine> UnifiedEngineFactory::create(EngineConfig::CoreType type) {
    switch (type) {
        case EngineConfig::CoreType::SINGBOX:
            return createSingBoxEngine();
        case EngineConfig::CoreType::LIBXRAY:
            return createLibXrayEngine();
        case EngineConfig::CoreType::V2RAY:
            return createV2RayEngine();
        default:
            return nullptr;
    }
}

bool UnifiedEngineFactory::requiresDriver(EngineConfig::CoreType type) {
    switch (type) {
        case EngineConfig::CoreType::SINGBOX:
            return false; // SingBox имеет встроенный TUN
        case EngineConfig::CoreType::LIBXRAY:
        case EngineConfig::CoreType::V2RAY:
            return true; // Требуют SOCKS драйвер
        default:
            return true;
    }
}

EngineConfig::DriverType UnifiedEngineFactory::getRecommendedDriver(EngineConfig::CoreType type) {
    if (requiresDriver(type)) {
        return EngineConfig::DriverType::HEV_SOCKS5; // Рекомендуем hev-socks5
    }
    return EngineConfig::DriverType::NONE;
}

} // namespace engine
} // namespace vpnclient_engine

