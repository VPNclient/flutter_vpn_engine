# ADR-002: Core/Driver Requirement Matrix

## Meta

- **Number**: ADR-002
- **Type**: constraining
- **Status**: APPROVED
- **Created**: 2026-05-14
- **Decided**: Implicit (discovered via /legacy analysis)
- **Author**: /legacy reverse engineering
- **Reviewers**: -

## Context

The VPN Client Engine supports multiple VPN cores with different capabilities:
- **SingBox**: Full-featured proxy with built-in TUN support
- **LibXray**: V2Ray library outputting SOCKS5 proxy
- **V2Ray**: V2Ray core outputting SOCKS5 proxy
- **WireGuard**: WireGuard implementation with built-in TUN via wireguard-go

Some cores can directly manage the TUN interface, while others only provide a SOCKS5 proxy endpoint. For the latter, an external driver (HevSocks5 or Tun2Socks) is required to route device traffic through the proxy.

The engine needs a clear matrix defining which cores require drivers.

## Decision Drivers

- **User Experience**: Auto-configuration should "just work" without manual driver selection
- **Correctness**: Prevent invalid configurations (e.g., LibXray without driver)
- **Flexibility**: Allow driver override for advanced users
- **Simplicity**: Clear, predictable behavior

## Considered Options

### Option 1: Core-Based Requirement Matrix

**Description**: Define a static matrix mapping cores to driver requirements.

| Core | Built-in TUN | Requires Driver |
|------|-------------|-----------------|
| SingBox | Yes | No |
| LibXray | No | Yes |
| V2Ray | No | Yes |
| WireGuard | Yes | No |

**Pros**:
- Simple, predictable logic
- Easy to validate at initialization
- Clear documentation

**Cons**:
- Static - can't adapt to future core changes
- May not reflect all configuration possibilities

**Estimated Effort**: Low (already implemented)

### Option 2: Runtime Capability Detection

**Description**: Query each core at runtime for its TUN capability.

**Pros**:
- Adapts to core updates automatically
- More accurate per-configuration

**Cons**:
- Requires core-specific capability API
- More complex initialization
- May have race conditions

**Estimated Effort**: Medium

### Option 3: Always Require Driver Specification

**Description**: No auto-detection - always require explicit driver config.

**Pros**:
- No implicit behavior
- Full user control

**Cons**:
- Poor developer experience
- Easy to misconfigure
- More boilerplate

**Estimated Effort**: Low

## Decision

We will use **Core-Based Requirement Matrix** (Option 1) because:

- The core capabilities are well-known and stable
- Simple implementation with clear, testable logic
- Enables auto-configuration via `EngineManager.createOptimalConfig()`
- Easy to document and understand

## Consequences

### Positive

- Users don't need to know driver requirements
- Invalid configurations prevented at initialization
- Clear, predictable behavior

### Negative

- If a core adds/removes TUN support, code update required
- Some advanced configurations may require override

### Neutral

- Matrix is documented in both code and specs

## Implementation Notes

```dart
// EngineManager.dart
static bool requiresDriver(CoreType core) {
    switch (core) {
        case CoreType.singbox:
            return false; // Built-in TUN
        case CoreType.libxray:
        case CoreType.v2ray:
            return true;  // Needs SOCKS driver
        case CoreType.wireguard:
            return false; // Built-in TUN (wireguard-go)
    }
}

static bool isCompatible(CoreType core, DriverType driver) {
    if (driver == DriverType.none) {
        return !requiresDriver(core);
    }
    return requiresDriver(core);
}
```

- `requiresDriver()` returns true for LibXray/V2Ray
- `isCompatible()` validates core/driver combinations
- `createOptimalConfig()` auto-selects driver when needed

## Related Decisions

- ADR-001: HevSocks5 as Default Driver (which driver to use when required)

## Related Specs

- `flows/sdd-vpnclient-engine-flutter/`: Main engine specification

## References

- [SingBox TUN Documentation](https://sing-box.sagernet.org/configuration/inbound/tun/)
- [LibXray Architecture](https://github.com/xtls/libxray)
- [wireguard-go](https://github.com/WireGuard/wireguard-go)

## Tags

architecture cores drivers compatibility

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
