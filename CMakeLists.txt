cmake_minimum_required(VERSION 3.15)
project(vpnclient_engine)

set(CMAKE_CXX_STANDARD 17)

# Connecting dependencies
find_package(OpenSSL REQUIRED)
find_package(XRay REQUIRED)
find_package(SingBox REQUIRED)
find_package(WireGuard REQUIRED)

# Main library
add_library(vpnclient_engine STATIC
    src/core/vpnclient_engine.cpp
    src/engines/wireguard_engine.cpp
    src/engines/singbox_engine.cpp
    src/engines/xray_engine.cpp
    src/proxies/tun2socks.cpp
    src/proxies/hev_socks5.cpp
    src/proxies/approxy.cpp
)

target_include_directories(vpnclient_engine PUBLIC include)
target_link_libraries(vpnclient_engine
    OpenSSL::SSL
    VPNclientXRAY::VPNclientXRAY
    XRay::XRay
    SingBox::SingBox
    WireGuard::WireGuard
)


# Example
add_executable(test_vpnclient_engine tests/test_vpnclient_engine.cpp)
target_link_libraries(test_vpnclient_engine vpnclient_engine)
