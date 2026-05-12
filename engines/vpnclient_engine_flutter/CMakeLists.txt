cmake_minimum_required(VERSION 3.15)
project(vpnclient_engine VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Опции сборки
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(ENABLE_HEV_SOCKS5 "Enable HevSocks5 driver" ON)
option(ENABLE_TUN2SOCKS "Enable Tun2Socks driver" ON)
option(ENABLE_SINGBOX "Enable SingBox core" ON)
option(ENABLE_LIBXRAY "Enable LibXray core" ON)
option(ENABLE_V2RAY "Enable V2Ray core" ON)

# Исходные файлы
set(CORE_SOURCES
    src/core/vpnclient_engine.cpp
    src/core/vpnclient_engine_c_api.cpp
)

set(DRIVER_SOURCES
    src/drivers/driver_base.cpp
)

set(CORE_IMPL_SOURCES
    src/cores/core_base.cpp
)

# Драйверы
if(ENABLE_HEV_SOCKS5)
    list(APPEND DRIVER_SOURCES src/drivers/hev_socks5_driver.cpp)
    add_compile_definitions(ENABLE_HEV_SOCKS5)
endif()

if(ENABLE_TUN2SOCKS)
    list(APPEND DRIVER_SOURCES src/drivers/tun2socks_driver.cpp)
    add_compile_definitions(ENABLE_TUN2SOCKS)
endif()

# Ядра
if(ENABLE_SINGBOX)
    list(APPEND CORE_IMPL_SOURCES src/cores/singbox_core.cpp)
    add_compile_definitions(ENABLE_SINGBOX)
endif()

if(ENABLE_LIBXRAY)
    list(APPEND CORE_IMPL_SOURCES src/cores/libxray_core.cpp)
    add_compile_definitions(ENABLE_LIBXRAY)
endif()

if(ENABLE_V2RAY)
    list(APPEND CORE_IMPL_SOURCES src/cores/v2ray_core.cpp)
    add_compile_definitions(ENABLE_V2RAY)
endif()

# Создание библиотеки
add_library(${PROJECT_NAME}
    ${CORE_SOURCES}
    ${DRIVER_SOURCES}
    ${CORE_IMPL_SOURCES}
)

# Заголовочные файлы
target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Внешние зависимости
set(HEV_SOCKS5_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../flutter_vpn_hev5socks)
set(TUN2SOCKS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../flutter_vpn_tun2socks)
set(SINGBOX_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../flutter_vpn_singbox)
set(LIBXRAY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../fork_vpn_libxray)
set(V2RAY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../flutter_v2ray)

if(ENABLE_HEV_SOCKS5)
    # Подключение flutter_vpn_hev5socks
    target_include_directories(${PROJECT_NAME} PRIVATE ${HEV_SOCKS5_DIR}/include)
    if(EXISTS ${HEV_SOCKS5_DIR}/build/libhev_socks5.a)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${HEV_SOCKS5_DIR}/build/libhev_socks5.a)
    elseif(EXISTS ${HEV_SOCKS5_DIR}/build/libhev_socks5.so)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${HEV_SOCKS5_DIR}/build/libhev_socks5.so)
    endif()
endif()

if(ENABLE_TUN2SOCKS)
    # Подключение flutter_vpn_tun2socks
    target_include_directories(${PROJECT_NAME} PRIVATE ${TUN2SOCKS_DIR}/include)
    if(EXISTS ${TUN2SOCKS_DIR}/build/libtun2socks.a)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${TUN2SOCKS_DIR}/build/libtun2socks.a)
    elseif(EXISTS ${TUN2SOCKS_DIR}/build/libtun2socks.so)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${TUN2SOCKS_DIR}/build/libtun2socks.so)
    endif()
endif()

if(ENABLE_SINGBOX)
    # Подключение flutter_vpn_singbox
    target_include_directories(${PROJECT_NAME} PRIVATE ${SINGBOX_DIR}/include)
    if(EXISTS ${SINGBOX_DIR}/build/libsingbox.a)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${SINGBOX_DIR}/build/libsingbox.a)
    elseif(EXISTS ${SINGBOX_DIR}/build/libsingbox.so)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${SINGBOX_DIR}/build/libsingbox.so)
    endif()
endif()

if(ENABLE_LIBXRAY)
    # Подключение fork_vpn_libxray
    target_include_directories(${PROJECT_NAME} PRIVATE ${LIBXRAY_DIR}/include)
    if(EXISTS ${LIBXRAY_DIR}/build/libxray.a)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${LIBXRAY_DIR}/build/libxray.a)
    elseif(EXISTS ${LIBXRAY_DIR}/build/libxray.so)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${LIBXRAY_DIR}/build/libxray.so)
    endif()
endif()

if(ENABLE_V2RAY)
    # Подключение flutter_v2ray
    target_include_directories(${PROJECT_NAME} PRIVATE ${V2RAY_DIR}/include)
    if(EXISTS ${V2RAY_DIR}/build/libv2ray.a)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${V2RAY_DIR}/build/libv2ray.a)
    elseif(EXISTS ${V2RAY_DIR}/build/libv2ray.so)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${V2RAY_DIR}/build/libv2ray.so)
    endif()
endif()

# Установка
install(TARGETS ${PROJECT_NAME}
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)

# Тесты (опционально)
option(BUILD_TESTS "Build tests" OFF)
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
