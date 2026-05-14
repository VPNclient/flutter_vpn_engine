# Legacy Analysis Log

## Session History

### 2026-05-14 - Depth 0 (Root)

**Mode**: BFS
**Target**: engines/vpnclient_engine_flutter

**Analyzed**:
- README.md: Project overview, architecture diagram, API examples
- pubspec.yaml: Flutter plugin configuration, FFI dependencies
- lib/vpnclient_engine.dart: Library exports
- lib/src/vpnclient_engine.dart: Main VpnClientEngine class (373 lines)
- lib/src/models/*.dart: Configuration and data models
- lib/src/v2ray_url_parser.dart: V2Ray URL parsing (400 lines)
- lib/src/subscription_manager.dart: Subscription management (270 lines)
- lib/src/platform/vpn_engine_platform.dart: FFI bindings (277 lines)
- include/vpnclient_engine.h: C++ header with interfaces (157 lines)
- src/core/vpnclient_engine.cpp: Main C++ implementation (263 lines)
- android/app/src/main/java/**/VPNService.kt: Android VPN service
- ios/PacketTunnelProvider.swift: iOS packet tunnel provider

**Identified Domains**:
1. flutter-api-layer (HIGH) - Dart singleton API
2. configuration-system (HIGH) - Config hierarchy
3. core-abstraction (HIGH) - ICore + implementations
4. driver-abstraction (HIGH) - IDriver + implementations
5. native-bridge (MEDIUM) - FFI/MethodChannel
6. subscription-management (MEDIUM) - Subscriptions + URL parsing
7. platform-integration (MEDIUM) - Android/iOS native
8. data-models (LOW) - Enums/data classes

**Key Findings**:
- Plugin follows layered architecture: Flutter -> FFI -> C++ -> Platform
- Cores (SingBox, LibXray, V2Ray) handle VPN protocols
- Drivers (HevSocks5, Tun2Socks) handle traffic tunneling
- SingBox/WireGuard have built-in TUN, others require driver
- HevSocks5 is default recommended driver
- Singleton pattern used in Dart layer
- Hybrid communication: FFI for native, MethodChannel for platform

**ADR Candidates**:
- ADR-001: HevSocks5 as default driver
- ADR-002: Core/Driver requirement matrix
- ADR-003: Singleton pattern for VpnClientEngine
- ADR-004: Hybrid FFI/MethodChannel approach
- ADR-005: V2Ray URL protocol support

**Next depth**:
- RECURSE into each of 8 identified domains
- Create _node.md for each domain
- Generate SDD flows for major components

---

*Append new entries at the top.*
