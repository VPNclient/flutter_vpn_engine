#include "engines/wireguard.h"
#include <wg.h>

namespace vpnclient_engine {

class WireGuard : public VPNClientEngine {
    wg_handle h;
    LogCallback log_cb;
    
public:
    WireGuard(const std::string& config) {
        h = wg_create(config.c_str());
    }
    
    bool start() override {
        if(wg_start(h) {
            log("WireGuard started successfully");
            return true;
        }
        return false;
    }
    
    void stop() override {
        wg_stop(h);
        log("WireGuard stopped");
    }
    
    ~WireGuard() {
        wg_destroy(h);
    }
    
private:
    void log(const std::string& msg) {
        if(log_cb) log_cb("[WireGuard] " + msg);
    }
};

} // namespace
