#include "proxies/tun2socks.h"
#include <tun2socks.h>

namespace vpnclient_engine {

class Tun2SocksProxy {
    t2s_handle h;
    LogCallback log_cb;
    
public:
    Tun2SocksProxy(const std::string& config) {
        h = t2s_create(config.c_str());
    }
    
    bool start() {
        if(t2s_start(h)) {
            log("tun2socks started");
            return true;
        }
        return false;
    }
    
    void stop() {
        t2s_stop(h);
        log("tun2socks stopped");
    }
    
private:
    void log(const std::string& msg) {
        if(log_cb) log_cb("[tun2socks] " + msg);
    }
};

} // namespace