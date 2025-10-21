# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "vpnclient_engine")
project(${PROJECT_NAME} LANGUAGES CXX C)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "vpnclient_engine_plugin")

# Include the parent directory for the main engine code
set(ENGINE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "vpnclient_engine_plugin.cc"
  "${ENGINE_ROOT}/src/core/vpnclient_engine.cpp"
  "${ENGINE_ROOT}/src/cores/core_base.cpp"
  "${ENGINE_ROOT}/src/cores/singbox_core.cpp"
  "${ENGINE_ROOT}/src/cores/libxray_core.cpp"
  "${ENGINE_ROOT}/src/cores/v2ray_core.cpp"
  "${ENGINE_ROOT}/src/drivers/driver_base.cpp"
  "${ENGINE_ROOT}/src/drivers/hev_socks5_driver.cpp"
  "${ENGINE_ROOT}/src/drivers/tun2socks_driver.cpp"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
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

# Look for the GTK and Flutter libraries
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  PkgConfig::GTK
  PkgConfig::GLIB
  PkgConfig::GIO
)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(vpnclient_engine_bundled_libraries
  ""
  PARENT_SCOPE
)

