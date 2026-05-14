# ADR-003: Singleton Pattern for VpnClientEngine

## Meta

- **Number**: ADR-003
- **Type**: constraining
- **Status**: APPROVED
- **Created**: 2026-05-14
- **Decided**: Implicit (discovered via /legacy analysis)
- **Author**: /legacy reverse engineering
- **Reviewers**: -

## Context

The VPN Client Engine manages system-level resources:
- Native FFI engine instance
- Platform VPN service (Android VPNService, iOS NetworkExtension)
- TUN interface (single device per OS)
- Connection status and statistics streams

Multiple VpnClientEngine instances would conflict when accessing these shared resources. The API design needs to prevent this while providing a convenient interface for Flutter developers.

## Decision Drivers

- **Resource Safety**: Prevent conflicts from multiple VPN connections
- **API Simplicity**: Easy-to-use interface for Flutter developers
- **State Consistency**: Single source of truth for connection status
- **Stream Management**: Predictable stream lifecycle

## Considered Options

### Option 1: Singleton Instance

**Description**: Single `VpnClientEngine.instance` for entire application.

```dart
class VpnClientEngine {
    static VpnClientEngine? _instance;
    VpnClientEngine._();
    static VpnClientEngine get instance {
        _instance ??= VpnClientEngine._();
        return _instance!;
    }
}
```

**Pros**:
- Simple access pattern (`VpnClientEngine.instance`)
- Prevents multiple engine instances
- Automatic state sharing across app
- Flutter widget-friendly

**Cons**:
- Global state (testing concerns)
- Hard to mock in isolation
- No support for multiple VPN profiles simultaneously

**Estimated Effort**: Low (already implemented)

### Option 2: Factory with Instance Tracking

**Description**: Factory that throws if instance already exists.

```dart
class VpnClientEngine {
    static VpnClientEngine? _activeInstance;
    factory VpnClientEngine() {
        if (_activeInstance != null) {
            throw StateError('VpnClientEngine already exists');
        }
        return _activeInstance = VpnClientEngine._();
    }
}
```

**Pros**:
- Clearer instantiation pattern
- Can explicitly dispose and recreate
- Slightly better testability

**Cons**:
- More verbose usage
- Error handling required
- Still effectively singleton

**Estimated Effort**: Low

### Option 3: Dependency Injection

**Description**: Pass VpnClientEngine instance through constructors.

**Pros**:
- Maximum testability
- Explicit dependencies
- Flexible composition

**Cons**:
- Verbose - must thread instance through widget tree
- Requires provider/service locator pattern
- Overkill for single-instance resource

**Estimated Effort**: Medium

## Decision

We will use **Singleton Instance** (Option 1) because:

- VPN connection is inherently a singleton resource (one TUN device)
- Simple access pattern matches Flutter conventions
- Streams naturally shared across widgets via `instance`
- Prevents accidental duplicate connections

## Consequences

### Positive

- Simple, intuitive API (`VpnClientEngine.instance.connect()`)
- No risk of multiple engine instances
- Status and stats streams automatically shared
- Works naturally with Flutter's reactive patterns

### Negative

- Global state makes unit testing harder
- Must use `dispose()` carefully to reset state
- No multi-profile support (single active connection)

### Neutral

- Standard Flutter plugin pattern
- Similar to other singleton services (Firebase, etc.)

## Implementation Notes

```dart
class VpnClientEngine {
    static VpnClientEngine? _instance;

    VpnClientEngine._() {
        _platform = VpnEnginePlatform();
        _subscriptionManager = SubscriptionManager();
        _setupMethodCallHandler();
    }

    static VpnClientEngine get instance {
        _instance ??= VpnClientEngine._();
        return _instance!;
    }

    Future<void> dispose() async {
        await disconnect();
        // ... cleanup streams
        _platform.dispose();
    }
}
```

- Private constructor prevents external instantiation
- Lazy initialization on first access
- `dispose()` releases all resources
- Streams created lazily on first access

### Testing Considerations

For unit tests, consider:
1. Using `setUp`/`tearDown` with `dispose()`
2. Creating mockable wrapper interface
3. Integration tests for actual VPN behavior

## Related Decisions

- (none)

## Related Specs

- `flows/sdd-vpnclient-engine-flutter/`: Main engine specification

## References

- [Flutter Service Locator Patterns](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)
- [Singleton Pattern in Dart](https://dart.dev/guides/language/language-tour#factory-constructors)

## Tags

architecture flutter patterns api-design

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
