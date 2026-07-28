#pragma once

#include "engine/unified_engine.h"
#include <memory>

namespace vpnclient_engine {
namespace engine {

/// Создать экземпляр SingBox движка
std::unique_ptr<IUnifiedEngine> createSingBoxEngine();

} // namespace engine
} // namespace vpnclient_engine

