# Implementation Plan: VPN Client Engine - Gap Fixes

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-05-14
> Specifications: [02-specifications.md](./02-specifications.md)

## Summary

This plan addresses implementation gaps discovered during legacy code analysis. The codebase has a solid architecture but several components are stubbed or incomplete. Priority is given to making LibXray and V2Ray cores functional, then statistics/testing features.

## Gap Inventory

| Priority | Gap | Location | Impact |
|----------|-----|----------|--------|
| P0 | LibXray core is stubbed | `src/cores/libxray_core.cpp` | Core unusable |
| P0 | V2Ray core is stubbed | `src/cores/v2ray_core.cpp` | Core unusable |
| P1 | Stats retrieval not implemented | All engines | No traffic metrics |
| P1 | testConnection() not implemented | All engines | Can't verify connectivity |
| P1 | V2 API native calls incomplete | `vpnclient_engine_v2.dart` | V2 API broken |
| P2 | Platform interfaces return stubs | `platform_interface_factory.cpp` | Desktop platforms |
| P2 | Proxy-through ping missing | `subscription_manager.dart` | Inaccurate latency |
| P2 | SingBox FD passing not done | `singbox_engine.cpp` | Android TUN integration |
| P3 | Versions hardcoded | Various cores | Minor accuracy issue |

## Task Breakdown

### Phase 1: Core Implementations (P0)

#### Task 1.1: Implement LibXray Core Integration

- **Description**: Complete the LibXray core integration with actual library calls
- **Files**:
  - `src/cores/libxray_core.cpp` - Modify: implement start/stop/version
  - `include/cores/libxray_core.h` - Modify: add necessary members if needed
- **Dependencies**: libxray library must be linked
- **Verification**:
  - Unit test with LibXray core type connects successfully
  - Logs show "LibXray core started" without TODO comments
- **Complexity**: High

#### Task 1.2: Implement V2Ray Core Integration

- **Description**: Complete the V2Ray core integration with actual library calls
- **Files**:
  - `src/cores/v2ray_core.cpp` - Modify: implement start/stop/version
  - `include/cores/v2ray_core.h` - Modify: add necessary members if needed
- **Dependencies**: v2ray-core library must be linked
- **Verification**:
  - Unit test with V2Ray core type connects successfully
  - Logs show "V2Ray core started" without TODO comments
- **Complexity**: High

### Phase 2: Statistics & Testing (P1)

#### Task 2.1: Implement Statistics Retrieval - SingBox

- **Description**: Get actual traffic stats from SingBox core
- **Files**:
  - `src/engines/singbox_engine.cpp:133` - Modify: implement getStats()
  - `include/singbox_c_api.h` - Check: stats API exists
- **Dependencies**: Task 1.1 or existing SingBox working
- **Verification**: `statsStream` emits non-zero values during active connection
- **Complexity**: Medium

#### Task 2.2: Implement Statistics Retrieval - V2Ray/LibXray

- **Description**: Get traffic stats from V2Ray and LibXray cores
- **Files**:
  - `src/engines/v2ray_engine.cpp:174` - Modify: implement getStats()
  - `src/engines/libxray_engine.cpp:194` - Modify: implement getStats()
- **Dependencies**: Tasks 1.1, 1.2
- **Verification**: Stats work for all core types
- **Complexity**: Medium

#### Task 2.3: Implement Connection Testing

- **Description**: Implement `testConnection()` for all engines
- **Files**:
  - `src/engines/singbox_engine.cpp:150` - Modify
  - `src/engines/v2ray_engine.cpp:191` - Modify
  - `src/engines/libxray_engine.cpp:211` - Modify
- **Dependencies**: Cores must be working (Phase 1)
- **Verification**: `testConnection()` returns true when connected, false otherwise
- **Complexity**: Medium

#### Task 2.4: Complete V2 API Native Calls

- **Description**: Wire up remaining native calls in V2 Dart API
- **Files**:
  - `lib/src/vpnclient_engine_v2.dart:168` - Modify: implement connect native call
  - `lib/src/vpnclient_engine_v2.dart:200` - Modify: implement stop native call
  - `lib/src/vpnclient_engine_v2.dart:259` - Modify: get stats from native
  - `lib/src/vpnclient_engine_v2.dart:343` - Modify: determine core type
- **Dependencies**: Native implementations complete
- **Verification**: V2 API tests pass
- **Complexity**: Medium

### Phase 3: Platform & Integration (P2)

#### Task 3.1: Implement Desktop Platform Interfaces

- **Description**: Replace StubPlatformInterface with real implementations
- **Files**:
  - `src/platform/platform_interface_factory.cpp` - Modify
  - `src/platform/linux_platform_interface.cpp` - Create or complete
  - `src/platform/windows_platform_interface.cpp` - Create or complete
  - `src/platform/macos_platform_interface.cpp` - Create or complete
- **Dependencies**: None
- **Verification**: Desktop builds work without "stub" warnings
- **Complexity**: High

#### Task 3.2: Implement Proxy-Through Ping

- **Description**: Ping servers through the VPN connection, not direct TCP
- **Files**:
  - `lib/src/subscription_manager.dart:216` - Modify: route ping through proxy
- **Dependencies**: Working connection
- **Verification**: Ping latency reflects actual VPN path
- **Complexity**: Medium

#### Task 3.3: SingBox File Descriptor Passing

- **Description**: Pass TUN FD to SingBox on Android
- **Files**:
  - `src/engines/singbox_engine.cpp:61` - Modify
- **Dependencies**: Android platform working
- **Verification**: Android VPN works with SingBox core
- **Complexity**: Medium

### Phase 4: Testing

#### Task 4.1: Unit Tests for V2Ray URL Parser

- **Description**: Add comprehensive tests for all V2Ray URL formats
- **Files**:
  - `test/v2ray_url_parser_test.dart` - Create
- **Dependencies**: None
- **Verification**: All 5 protocols tested (vmess, vless, trojan, ss, socks)
- **Complexity**: Medium

#### Task 4.2: Unit Tests for Core/Driver Selection

- **Description**: Test EngineManager driver requirement logic
- **Files**:
  - `test/engine_manager_test.dart` - Create
- **Dependencies**: None
- **Verification**: Core/driver matrix validated
- **Complexity**: Low

#### Task 4.3: Integration Tests for Connection Lifecycle

- **Description**: Test full connect/disconnect cycle for each core type
- **Files**:
  - `test/integration/connection_lifecycle_test.dart` - Create
- **Dependencies**: Phase 1 complete (cores working)
- **Verification**: Each core type can connect and disconnect
- **Complexity**: High

#### Task 4.4: Integration Tests for Statistics

- **Description**: Verify stats stream emits correct values
- **Files**:
  - `test/integration/statistics_test.dart` - Create
- **Dependencies**: Phase 2 complete (stats working)
- **Verification**: Stats update during active connection
- **Complexity**: Medium

#### Task 4.5: Unit Tests for Subscription Manager

- **Description**: Test subscription fetching and server selection
- **Files**:
  - `test/subscription_manager_test.dart` - Create
- **Dependencies**: None
- **Verification**: Subscription parsing and server selection work
- **Complexity**: Medium

### Phase 5: Polish (P3)

#### Task 5.1: Dynamic Version Retrieval

- **Description**: Get versions from libraries instead of hardcoding
- **Files**:
  - `src/cores/singbox_core.cpp:14` - Modify
  - `src/cores/libxray_core.cpp:22` - Modify
  - `src/cores/v2ray_core.cpp:22` - Modify
- **Dependencies**: Phase 1 complete
- **Verification**: `getCoreVersion()` returns actual library versions
- **Complexity**: Low

## Dependency Graph

```
Phase 1 (Cores)
├── Task 1.1 (LibXray) ──┬──→ Task 2.2 (Stats V2Ray/LibXray)
│                        │
└── Task 1.2 (V2Ray) ────┘
                         │
Phase 2 (Stats/Testing)  │
├── Task 2.1 (Stats SingBox) ──┬──→ Task 2.4 (V2 API)
│                              │
├── Task 2.2 ──────────────────┤
│                              │
└── Task 2.3 (testConnection) ─┘
                               │
Phase 3 (Platform)             │
├── Task 3.1 (Desktop) ────────┼──→ [Can run in parallel]
├── Task 3.2 (Proxy Ping) ─────┤
└── Task 3.3 (SingBox FD) ─────┘
                               │
Phase 4 (Testing)              │
├── Task 4.1 (URL Parser) ─────┼──→ [Can run early - no deps]
├── Task 4.2 (Engine Manager) ─┤
├── Task 4.3 (Lifecycle) ──────┼──→ [After Phase 1]
├── Task 4.4 (Statistics) ─────┼──→ [After Phase 2]
└── Task 4.5 (Subscriptions) ──┘
                               │
Phase 5 (Polish)               │
└── Task 5.1 (Versions) ───────┘
```

## File Change Summary

| File | Action | Reason |
|------|--------|--------|
| `src/cores/libxray_core.cpp` | Modify | Implement core functionality |
| `src/cores/v2ray_core.cpp` | Modify | Implement core functionality |
| `src/engines/singbox_engine.cpp` | Modify | Stats + FD passing |
| `src/engines/v2ray_engine.cpp` | Modify | Stats + testConnection |
| `src/engines/libxray_engine.cpp` | Modify | Stats + testConnection |
| `lib/src/vpnclient_engine_v2.dart` | Modify | Complete native calls |
| `lib/src/subscription_manager.dart` | Modify | Proxy-through ping |
| `src/platform/platform_interface_factory.cpp` | Modify | Real implementations |
| `test/v2ray_url_parser_test.dart` | Create | URL parser tests |
| `test/engine_manager_test.dart` | Create | Core/driver selection tests |
| `test/integration/connection_lifecycle_test.dart` | Create | Connection lifecycle tests |
| `test/integration/statistics_test.dart` | Create | Statistics tests |
| `test/subscription_manager_test.dart` | Create | Subscription tests |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| libxray/v2ray API changes | Medium | High | Pin library versions, add version checks |
| Platform-specific bugs | High | Medium | Test on each platform, use CI |
| Stats accuracy issues | Medium | Low | Compare with Wireshark/tcpdump |
| Breaking existing SingBox | Low | High | Run existing tests before each change |

## Rollback Strategy

If implementation fails or needs to be reverted:

1. Each task should be a separate commit
2. Revert specific commits if issues found
3. SingBox core is already working - don't break it

## Checkpoints

After each phase, verify:

- [ ] All existing tests still pass
- [ ] No new compiler warnings
- [ ] `flutter test` passes
- [ ] Manual test on at least one platform

## Open Implementation Questions

- [ ] Which libxray version to target? (1.8.7 hardcoded currently)
- [ ] Which v2ray-core version to target? (5.10.0 hardcoded currently)
- [ ] Should we support WireGuard core? (mentioned in specs but no implementation)
- [ ] Desktop TUN handling - use WinTUN on Windows?

---

## Approval

- [x] Reviewed by: User
- [x] Approved on: 2026-05-14
- [x] Notes: Added testing phase (Tasks 4.1-4.5) before approval
