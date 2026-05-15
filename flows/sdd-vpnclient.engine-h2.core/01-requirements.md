# Requirements: h2.core Integration for vpnclient_engine_flutter

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-05-14

## Problem Statement

The vpnclient_engine_flutter currently supports SingBox, LibXray, V2Ray, and WireGuard cores. We need to add support for **h2.core** (HTTPS VPN) - a lightweight, certification-ready VPN that uses HTTP/2 CONNECT over TLS, making it indistinguishable from regular browser HTTPS proxy traffic.

h2.core is valuable because:
- **DPI evasion**: Traffic looks identical to browser HTTPS proxy (HTTP/2 CONNECT)
- **Small codebase**: ~600 LOC core (vs ~100K for xray-core) - easier to audit/certify
- **Pluggable crypto**: Supports national cryptography standards (US, CN, UA, TH, FR, UK)
- **xray-compatible**: Same config format, drop-in replacement for xray-core

## User Stories

### Primary

**As a** VPN client application developer
**I want** to use h2.core as a VPN core in vpnclient_engine_flutter
**So that** users can connect via HTTPS VPN that is indistinguishable from browser traffic

### Secondary

**As a** user in a restricted network environment
**I want** to connect using h2.core
**So that** my VPN traffic cannot be detected by deep packet inspection (DPI)

**As a** developer
**I want** h2.core to follow the same interface as other cores
**So that** I can switch between cores without changing my application code

## Acceptance Criteria

### Must Have

1. **Given** h2.core binaries in `vendors/h2.core/dist/`
   **When** building vpnclient_engine_flutter for a supported platform
   **Then** the h2.core binary should be correctly linked/bundled

2. **Given** a valid h2.core config JSON
   **When** calling `VpnClientEngine.connect()` with `CoreType.h2`
   **Then** h2.core should start and expose SOCKS5 proxy at configured address

3. **Given** an active h2.core connection
   **When** calling `VpnClientEngine.disconnect()`
   **Then** h2.core should stop cleanly

4. **Given** h2.core is integrated
   **When** checking `EngineManager.requiresDriver(CoreType.h2)`
   **Then** it should return `true` (h2.core provides SOCKS5, needs TUN driver)

### Should Have

5. **Given** h2.core is running
   **When** querying stats
   **Then** traffic statistics should be available (if h2.core exposes stats API)

6. **Given** h2.core config with crypto provider specified
   **When** connecting
   **Then** the specified cryptography (us, cn, ua, th, fr, uk) should be used

### Won't Have (This Iteration)

- Building h2.core from source as part of Flutter build
- Windows support (no Windows binary in dist currently)
- iOS/Android support (current binaries are desktop only)
- Runtime selection of crypto providers (compile-time only in h2.core)

## Constraints

- **Technical**: h2.core is a Go binary, not a C/C++ library - need process management approach
- **Platform**: Currently supporting Linux (amd64, arm64) and macOS (arm64/silicon) only
- **Dependencies**: h2.core exposes SOCKS5 interface - requires HevSocks5 or Tun2Socks driver for TUN
- **Binary location**: Binaries must be sourced from `vendors/h2.core/dist/`

## Integration Approach Options

### Option A: Process-based Integration
- Spawn h2.core as a child process
- Communicate via command-line args and stdio
- Similar to how some VPN clients manage external binaries
- **Pros**: Simpler, no CGO needed, crash isolation
- **Cons**: Process management overhead, IPC complexity

### Option B: CGO Library Integration
- Build h2.core as a C-compatible shared library (.so/.dylib)
- Link directly into native code via FFI
- **Pros**: Direct function calls, better integration
- **Cons**: Requires building h2.core as library (not currently done)

**Recommendation**: Start with Option A (process-based) since binaries already exist

## Open Questions

- [ ] Does h2.core support a C API / shared library build mode?
- [ ] What is the stats/metrics API for h2.core (if any)?
- [ ] Should we support Android/iOS in a future iteration?
- [ ] What config format does h2.core use - pure xray JSON or custom?

## References

- h2.core source: `vendors/h2.core/`
- h2.core README: `vendors/h2.core/README.md`
- vpnclient_engine_flutter core interface: `include/cores/core_base.h`
- Existing core implementations: `src/cores/singbox_core.cpp`

---

## Approval

- [ ] Reviewed by: User
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
