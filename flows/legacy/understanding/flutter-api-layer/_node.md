# Understanding: Flutter API Layer

> Public Dart API providing unified VPN engine interface for Flutter applications.

## Phase: SYNTHESIZING

## Hypothesis

Singleton-based public API that wraps native FFI calls and provides Flutter-friendly abstractions (streams, futures, callbacks) for VPN connection management.

## Sources

> Files/directories that inform this understanding

- `lib/vpnclient_engine.dart` - Library exports and entry point
- `lib/src/vpnclient_engine.dart` - Main VpnClientEngine class (373 lines)
- `lib/src/vpnclient_engine_v2.dart` - V2 API (newer version)
- `lib/src/legacy_api.dart` - Legacy backwards-compatible API

## Validated Understanding

The Flutter API Layer provides:

### VpnClientEngine Class (Singleton)
- **Lifecycle**: `initialize(config)` -> `connect()` -> `disconnect()` -> `dispose()`
- **Status Management**: `ConnectionStatus` enum with `statusStream` for reactive updates
- **Statistics**: `ConnectionStats` with `statsStream` for traffic monitoring
- **Logging**: `logStream` + `setLogCallback()` for debug output
- **Platform Bridge**: Uses `VpnEnginePlatform` for native FFI communication

### Key Methods
```dart
// Initialization
Future<bool> initialize(VpnEngineConfig config)

// Connection control
Future<bool> connect()
Future<void> disconnect()

// Subscription API integration
void addSubscription({required String subscriptionURL, String? name})
Future<bool> connectToServer({required int subscriptionIndex, required int serverIndex})

// Info getters
Future<String> getCoreName()
Future<String> getCoreVersion()
Future<String> getDriverName()
```

### Reactive Streams
- `Stream<ConnectionStatus> statusStream` - Connection state changes
- `Stream<ConnectionStats> statsStream` - Traffic and latency metrics
- `Stream<Map<String, String>> logStream` - Log messages with levels

### Method Channel Handler
Receives native callbacks via `MethodChannel('vpnclient_engine')`:
- `onStatusChanged` - Native status updates
- `onStatsUpdated` - Native statistics updates
- `onLog` - Native log messages

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: configuration-system (VpnEngineConfig), data-models (ConnectionStatus, ConnectionStats), native-bridge (VpnEnginePlatform), subscription-management (SubscriptionManager)
- **Used by**: Flutter application layer

## Key Insights

1. **Singleton Pattern**: `VpnClientEngine.instance` ensures single engine instance across app
2. **Hybrid Communication**: Uses FFI for native calls + MethodChannel for callbacks
3. **Stats Polling**: Timer-based polling every 1 second when connected
4. **V2Ray Integration**: `connectToServer()` parses V2Ray URLs and updates config
5. **Backward Compatibility**: Legacy API available for migration from older versions

## ADR Candidates

- ADR-003: Singleton pattern for VpnClientEngine (prevents multiple engine instances)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Internal module API, well-defined interface contract, no stakeholder-facing docs needed

## Synthesis

### Combined Understanding

The Flutter API Layer is the primary consumer-facing interface. It:
1. Exposes a singleton `VpnClientEngine` for app-wide VPN management
2. Wraps native FFI calls in Flutter-friendly async patterns
3. Provides reactive streams for UI binding
4. Integrates subscription management for server selection
5. Maintains backward compatibility through legacy exports

### API Surface Summary

| Category | Methods/Properties |
|----------|-------------------|
| Lifecycle | `initialize()`, `connect()`, `disconnect()`, `dispose()` |
| Status | `status`, `statusStream`, `setStatusCallback()` |
| Stats | `stats`, `statsStream`, `updateStats()`, `setStatsCallback()` |
| Logging | `logStream`, `setLogCallback()` |
| Info | `getCoreName()`, `getCoreVersion()`, `getDriverName()`, `testConnection()` |
| Subscriptions | `addSubscription()`, `clearSubscriptions()`, `updateSubscription()`, `pingServer()`, `connectToServer()`, `getServer()`, `subscriptions`, `onPingResult` |

## Bubble Up

> Summary to pass to parent during EXITING

- Flutter API provides singleton VpnClientEngine with reactive streams
- Uses FFI + MethodChannel hybrid for native communication
- Integrates subscription management for V2Ray server selection
- Maintains backward compatibility through legacy API exports

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
