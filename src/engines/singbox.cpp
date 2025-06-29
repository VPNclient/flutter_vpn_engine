#include "engines/singbox_engine.h"
#include <singbox.h>

namespace vpnclient_engine {

class SingBox : public VPNClientEngine {
	singbox_instance *sb;
	LogCallback log_cb;

  public:
	SingBox(const std::string &config) { sb = singbox_new(config.c_str()); }

	bool start() override {
		if(singbox_start(sb) {
			log("sing-box started successfully");
			return true;
        }
        return false;
	}

	void stop() override {
		singbox_stop(sb);
		log("sing-box stopped");
	}

	~SingBox() { singbox_free(sb); }

  private:
	void log(const std::string &msg) {
		if (log_cb)
			log_cb("[sing-box] " + msg);
	}
};

} // namespace vpnclient_engine