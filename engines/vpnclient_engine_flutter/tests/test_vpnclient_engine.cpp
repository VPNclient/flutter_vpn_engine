#include "vpnclient_engine.h"

int main() {
    using namespace vpnclient_engine;
    
    Config config;
    config.engine = EngineType::VPNCLIENTXRAY;
    config.engine_config = "xray.conf";
    config.proxy = ProxyMode::VPNCLIENTDRIVER;
    config.proxy_config = "driver.json";
    
    auto client = VPNClient::create(config);
    
    client->set_log_callback([](const std::string& msg) {
        std::cout << msg << std::endl;
    });
    
    if(client->start()) {
        std::cout << "VPN is running. Press Enter to stop..." << std::endl;
        std::cin.get();
        client->stop();
    }
    
    return 0;
}1
