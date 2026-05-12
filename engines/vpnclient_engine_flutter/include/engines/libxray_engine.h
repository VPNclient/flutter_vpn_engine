#pragma once

#include "engine/unified_engine.h"
#include <memory>

namespace vpnclient_engine {
namespace engine {

/// Создать экземпляр LibXray движка
std::unique_ptr<IUnifiedEngine> createLibXrayEngine();

} // namespace engine
} // namespace vpnclient_engine

