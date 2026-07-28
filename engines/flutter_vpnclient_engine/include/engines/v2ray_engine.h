#pragma once

#include "engine/unified_engine.h"
#include <memory>

namespace vpnclient_engine {
namespace engine {

/// Создать экземпляр V2Ray движка
std::unique_ptr<IUnifiedEngine> createV2RayEngine();

} // namespace engine
} // namespace vpnclient_engine

