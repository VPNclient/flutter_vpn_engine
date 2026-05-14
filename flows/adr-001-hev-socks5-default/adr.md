# ADR-001: HevSocks5 as Default Tunneling Driver

## Meta

- **Number**: ADR-001
- **Type**: constraining
- **Status**: APPROVED
- **Created**: 2026-05-14
- **Decided**: Implicit (discovered via /legacy analysis)
- **Author**: /legacy reverse engineering
- **Reviewers**: -

## Context

The VPN Client Engine supports multiple VPN cores (SingBox, LibXray, V2Ray, WireGuard). Some cores like LibXray and V2Ray only provide SOCKS5 proxy output and require an external driver to tunnel device traffic through the proxy. The engine needs a default driver recommendation for when users don't explicitly specify one.

Two tunneling drivers are supported:
1. **HevSocks5** (hev-socks5-tunnel) - Lightweight C implementation
2. **Tun2Socks** (xjasonlyu/tun2socks) - Go-based with more features

## Decision Drivers

- **Performance**: Driver should have minimal CPU/memory overhead
- **Reliability**: Driver should be stable across all supported platforms
- **Simplicity**: Fewer dependencies and smaller binary size preferred
- **Compatibility**: Must work reliably with all supported cores

## Considered Options

### Option 1: HevSocks5 (hev-socks5-tunnel)

**Description**: Use hev-socks5-tunnel as the default driver for cores requiring SOCKS5 tunneling.

**Pros**:
- Lightweight C implementation with minimal overhead
- Small binary size (~100KB)
- Proven stability in production
- Active maintenance by heiher

**Cons**:
- Fewer advanced features than tun2socks
- Limited configurability

**Estimated Effort**: Low (already implemented)

### Option 2: Tun2Socks

**Description**: Use xjasonlyu/tun2socks as the default driver.

**Pros**:
- More advanced features (DNS hijacking, per-app rules)
- Active community
- Go-based (memory safe)

**Cons**:
- Larger binary size (~5MB)
- Higher memory footprint (Go runtime)
- Slightly higher latency

**Estimated Effort**: Low (already implemented)

### Option 3: No Default (Require Explicit)

**Description**: Always require users to explicitly specify a driver.

**Pros**:
- No implicit behavior
- Forces users to understand their choice

**Cons**:
- Poor developer experience
- More configuration boilerplate
- Easy to misconfigure

**Estimated Effort**: Low

## Decision

We will use **HevSocks5** as the default driver because:

- Minimal overhead aligns with VPN performance expectations
- Smaller binary size benefits mobile deployments
- Proven reliability across all 5 supported platforms
- Simplicity matches the "unified interface" design goal

## Consequences

### Positive

- Users get a working driver without explicit configuration
- Optimal performance out of the box
- Smaller app bundle size

### Negative

- Users wanting advanced features must explicitly select Tun2Socks
- Some edge cases may require Tun2Socks for better DNS handling

### Neutral

- Tun2Socks remains available as an explicit option

## Implementation Notes

```dart
// EngineManager.dart
static DriverType? getRecommendedDriver(CoreType core) {
    if (requiresDriver(core)) {
        return DriverType.hevSocks5; // Default recommendation
    }
    return null;
}
```

- `EngineManager.createOptimalConfig()` automatically selects HevSocks5 when needed
- Users can override with `explicitDriver` parameter

## Related Decisions

- ADR-002: Core/Driver Requirement Matrix (defines when drivers are needed)

## Related Specs

- `flows/sdd-vpnclient-engine-flutter/`: Main engine specification

## References

- [hev-socks5-tunnel GitHub](https://github.com/heiher/hev-socks5-tunnel)
- [tun2socks GitHub](https://github.com/xjasonlyu/tun2socks)

## Tags

architecture performance networking drivers

---

## Approval

### Review History

| Date | Reviewer | Status | Comments |
|------|----------|--------|----------|
| 2026-05-14 | /legacy | approved | Discovered from existing implementation |

### Final Decision

- [x] Approved by: Implicit (existing codebase)
- [x] Decided on: Prior to analysis
- [ ] Implementation assigned to: Already implemented
