# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "vpnclient_engine")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "vpnclient_engine_plugin")

# Include the parent directory for the main engine code
set(ENGINE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")

# Add source files
add_library(${PLUGIN_NAME} SHARED
  "vpnclient_engine_plugin.cpp"
  "${ENGINE_ROOT}/src/core/vpnclient_engine.cpp"
  "${ENGINE_ROOT}/src/cores/core_base.cpp"
  "${ENGINE_ROOT}/src/cores/singbox_core.cpp"
  "${ENGINE_ROOT}/src/cores/libxray_core.cpp"
  "${ENGINE_ROOT}/src/cores/v2ray_core.cpp"
  "${ENGINE_ROOT}/src/drivers/driver_base.cpp"
  "${ENGINE_ROOT}/src/drivers/hev_socks5_driver.cpp"
  "${ENGINE_ROOT}/src/drivers/tun2socks_driver.cpp"
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly marked as visible.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Include directories
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${ENGINE_ROOT}/include")

# Link with the Flutter library.
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(vpnclient_engine_bundled_libraries
  ""
  PARENT_SCOPE
)

