# Understanding: VPN Client Engine (Flutter)

> Entry point for recursive understanding of the vpnclient_engine_flutter module.

## Project Overview

**vpnclient_engine** is a cross-platform Flutter plugin providing a unified interface for VPN functionality across Android, iOS, Windows, Linux, and macOS. The architecture follows a layered design separating protocol handling (Cores) from traffic tunneling (Drivers).

**Key Characteristics:**
- Flutter plugin with native C++/Dart FFI integration
- Multi-core support: SingBox, LibXray, V2Ray, WireGuard
- Multi-driver support: HevSocks5, Tun2Socks
- Subscription-based server management with V2Ray URL parsing
- Cross-platform TUN interface abstraction

## Identified Domains

> Logical domains discovered. Each becomes a child directory for deeper exploration.

| Domain | Hypothesis | Priority | Status |
|--------|------------|----------|--------|
| flutter-api-layer | Public Dart API (VpnClientEngine, streams, callbacks) - singleton pattern with method channels | HIGH | PENDING |
| configuration-system | VpnEngineConfig, CoreConfig, DriverConfig - hierarchical configuration with serialization | HIGH | PENDING |
| core-abstraction | ICore interface with SingBox, LibXray, V2Ray, WireGuard implementations | HIGH | PENDING |
| driver-abstraction | IDriver interface with HevSocks5, Tun2Socks implementations | HIGH | PENDING |
| native-bridge | FFI bindings, C API, platform channel communication | MEDIUM | PENDING |
| subscription-management | Subscription fetching, V2Ray URL parsing, server ping | MEDIUM | PENDING |
| platform-integration | Android VPNService, iOS NetworkExtension, platform-specific TUN handling | MEDIUM | PENDING |
| data-models | ConnectionStatus, ConnectionStats, CoreType, DriverType enums | LOW | PENDING |

## Source Mapping

> Which source paths map to which logical domains

| Source Path | -> Domain |
|-------------|----------|
| lib/vpnclient_engine.dart | flutter-api-layer |
| lib/src/vpnclient_engine.dart | flutter-api-layer |
| lib/src/vpnclient_engine_v2.dart | flutter-api-layer |
| lib/src/models/*.dart | data-models, configuration-system |
| lib/src/core/*.dart | configuration-system |
| lib/src/platform/*.dart | native-bridge, platform-integration |
| lib/src/subscription_manager.dart | subscription-management |
| lib/src/v2ray_url_parser.dart | subscription-management |
| include/vpnclient_engine.h | core-abstraction, driver-abstraction |
| include/cores/*.h | core-abstraction |
| include/drivers/*.h | driver-abstraction |
| src/core/*.cpp | native-bridge, core-abstraction |
| src/cores/*.cpp | core-abstraction |
| src/drivers/*.cpp | driver-abstraction |
| android/app/src/main/java/**/*.kt | platform-integration |
| ios/*.swift | platform-integration |

## Cross-Cutting Concerns

> Things that span multiple domains (may become ADRs)

- **ADR-001**: Choice of HevSocks5 as default driver for cores requiring SOCKS proxy
- **ADR-002**: SingBox and WireGuard have built-in TUN (no driver required), LibXray/V2Ray require external driver
- **ADR-003**: Singleton pattern for VpnClientEngine in Dart layer
- **ADR-004**: FFI-based native communication vs method channels (hybrid approach)
- **ADR-005**: V2Ray URL parsing supports multiple protocols (vmess, vless, trojan, ss, socks)

## Architecture Summary

```
+---------------------------------------------------------------+
|                    Flutter Application                         |
+---------------------------+-----------------------------------+
                            |
+---------------------------v-----------------------------------+
|              VpnClientEngine (Dart Singleton)                  |
|  - initialize() / connect() / disconnect()                     |
|  - statusStream / statsStream / logStream                      |
|  - SubscriptionManager integration                             |
+---------------------------+-----------------------------------+
                            | FFI / MethodChannel
+---------------------------v-----------------------------------+
|              VpnEnginePlatform (Dart FFI Layer)                |
|  - VpnEngineBindings (dlopen, function lookups)                |
|  - NativeEngineConfig / NativeEngineStats structs              |
+---------------------------+-----------------------------------+
                            | C ABI
+---------------------------v-----------------------------------+
|           VPNClientEngine (C++ Implementation)                 |
|  - CoreFactory::create() / DriverFactory::create()             |
|  - connect() -> driver.start() -> core.start()                 |
+-------------+---------------------------------+---------------+
              |                                 |
+-------------v-----------+   +-----------------v-------------+
|      ICore Interface     |   |    IDriver Interface         |
+--------------------------+   +------------------------------+
| - SingBoxCore            |   | - HevSocks5Driver            |
| - LibXrayCore            |   | - Tun2SocksDriver            |
| - V2RayCore              |   |                              |
| - (WireGuard planned)    |   |                              |
+--------------------------+   +------------------------------+
              |                             |
              +-------------+---------------+
                            |
+---------------------------v-----------------------------------+
|                  Platform-Specific TUN Layer                   |
+---------------------------------------------------------------+
| Android: VPNService + Builder.establish()                      |
| iOS: NEPacketTunnelProvider + HevSocks5Tunnel                  |
| Linux/Windows/macOS: Native TUN device management              |
+---------------------------------------------------------------+
```

## Children Spawned

```
flutter-api-layer/
configuration-system/
core-abstraction/
driver-abstraction/
native-bridge/
subscription-management/
platform-integration/
data-models/
```

## Synthesis

> Updated after all children complete

[pending children completion]

---

*Created by /legacy ENTERING phase*
*Source: engines/vpnclient_engine_flutter*
*Phase: EXPLORING | Depth: 0 | Parent: none*
