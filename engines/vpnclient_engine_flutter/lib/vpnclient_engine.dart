/// VPN Client Engine — unified interface for VPN cores and drivers.
///
/// Full replacement of the package's public API (flows/sdd-flutter-vpnclient-engine/):
/// shaped like `flutter_vpnclient_engine_mock`'s API for the real, portable subset.
/// The old `VpnClientEngine`/`VpnClientEngineV2`/`legacy_api.dart` surface is archived,
/// not deleted — see `lib/src/legacy_v2/` — but no longer exported here.
library vpnclient_engine;

// Cores / drivers.
export 'src/cores/core_type.dart';
export 'src/drivers/driver_type.dart';

// Connection engine.
export 'src/engine/connection_state.dart';
export 'src/engine/connection_stats.dart';
export 'src/engine/vpn_engine.dart';

// Protocol / server configuration.
export 'src/config/protocol_config.dart';
export 'src/config/transport_config.dart';
export 'src/config/tls_config.dart';

// Subscriptions & servers.
export 'src/subscriptions/server.dart';
export 'src/subscriptions/server_definition.dart';
export 'src/subscriptions/subscription.dart';
export 'src/subscriptions/subscription_manager.dart';
export 'src/subscriptions/subscription_parser.dart';
export 'src/subscriptions/subscription_parse_exception.dart';
export 'src/subscriptions/ping_result.dart';
export 'src/subscriptions/parsers/share_link_list_parser.dart';
export 'src/subscriptions/storage/subscription_store.dart';
export 'src/subscriptions/storage/in_memory_subscription_store.dart';
export 'src/subscriptions/storage/shared_prefs_subscription_store.dart';
