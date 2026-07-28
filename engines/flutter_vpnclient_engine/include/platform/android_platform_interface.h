#pragma once

#include "platform/i_platform_interface.h"
#include <memory>

#ifdef __ANDROID__

namespace vpnclient_engine {
namespace platform {

/// Android реализация Platform Interface
std::unique_ptr<IPlatformInterface> createAndroidPlatformInterface();

} // namespace platform
} // namespace vpnclient_engine

#endif // __ANDROID__

