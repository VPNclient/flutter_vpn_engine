#include "vpnclient_engine.h"
#include "engines/singbox_engine.h"
#include "engines/wireguard_engine.h"
#include "engines/xray_engine.h"
#include "proxies/approxy.h"
#include "proxies/hev_socks5.h"
#include "proxies/tun2socks.h"

namespace vpnclient_engine {

std::unique_ptr<VPNClientEngine> VPNClientEngine::create(const Config &config) {
	std::unique_ptr<VPNClientEngine> client;

	// Create the selected engine
	switch (config.engine) {
	case EngineType::VPNCLIENTXRAY:
		client = std::make_unique<VPNclientXRAYEngine>(config.engine_config);
		break;
	case EngineType::SINGBOX:
		client = std::make_unique<SingBoxEngine>(config.engine_config);
		break;
	case EngineType::LIBXRAY:
		client = std::make_unique<libXrayEngine>(config.engine_config);
		break;
	case EngineType::WIREGUARD:
		client = std::make_unique<WireGuardEngine>(config.engine_config);
		break;
	case EngineType::OPENVPN:
		client = std::make_unique<OpenVPNEngine>(config.engine_config);
		break;
	}

	// Set up a proxy (if necessary)
	switch (config.proxy) {
	case ProxyMode::VPNCLIENTDRIVER:
		client->set_proxy(
			std::make_unique<VPNclientDriverProxy>(config.proxy_config));
		break;
	case ProxyMode::TUN2SOCKS:
		client->set_proxy(
			std::make_unique<Tun2SocksProxy>(config.proxy_config));
		break;
	case ProxyMode::HEV_SOCKS5:
		client->set_proxy(
			std::make_unique<HevSocks5Proxy>(config.proxy_config));
		break;
	case ProxyMode::APPROXY:
		client->set_proxy(std::make_unique<AppProxy>(config.proxy_config));
		break;
	default:
		break;
	}

	return client;
}

} // namespace vpnclient_engine
