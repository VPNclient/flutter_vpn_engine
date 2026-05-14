# Understanding: Data Models

> Enums and data classes for VPN engine state representation.

## Phase: SYNTHESIZING

## Hypothesis

Simple value types (enums, data classes) for representing VPN connection state, statistics, and type selections.

## Sources

> Files/directories that inform this understanding

- `lib/src/models/core_type.dart` - Core type enum
- `lib/src/models/driver_type.dart` - Driver type enum
- `lib/src/models/connection_status.dart` - Connection status enum
- `lib/src/models/connection_stats.dart` - Statistics data class
- `lib/src/models/tun_options.dart` - TUN configuration
- `lib/src/models/platform_tun_handle.dart` - Platform-specific handle

## Validated Understanding

### CoreType Enum

```dart
enum CoreType {
    singbox,   // sing-box
    libxray,   // libxray
    v2ray,     // v2ray
    wireguard; // wireguard

    String toNativeString() => name.toUpperCase(); // SINGBOX, LIBXRAY, etc.
    static CoreType fromString(String value);
}
```

### DriverType Enum

```dart
enum DriverType {
    none,      // No driver (built-in TUN)
    hevSocks5, // hev-socks5-tunnel
    tun2socks; // tun2socks

    String toNativeString() => /* NONE, HEV_SOCKS5, TUN2SOCKS */;
    static DriverType fromString(String value);
}
```

### ConnectionStatus Enum

```dart
enum ConnectionStatus {
    disconnected,  // Not connected
    connecting,    // Connection in progress
    connected,     // Connected and active
    disconnecting, // Disconnection in progress
    error;         // Connection failed

    String toNativeString();
    static ConnectionStatus fromString(String value);
}
```

### ConnectionStats Data Class

```dart
class ConnectionStats {
    final int bytesSent;
    final int bytesReceived;
    final int packetsSent;
    final int packetsReceived;
    final int latencyMs;

    // Computed properties
    int get totalBytes => bytesSent + bytesReceived;
    String get formattedBytesSent => _formatBytes(bytesSent);
    String get formattedBytesReceived => _formatBytes(bytesReceived);
    String get formattedTotalBytes => _formatBytes(totalBytes);

    static String _formatBytes(int bytes) {
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
        if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }

    Map<String, dynamic> toMap();
    factory ConnectionStats.fromMap(Map<String, dynamic> map);
}
```

### Native/Dart Mapping

| C++ Enum | Dart Enum | Int Value |
|----------|-----------|-----------|
| CoreType::SINGBOX | CoreType.singbox | 0 |
| CoreType::LIBXRAY | CoreType.libxray | 1 |
| CoreType::V2RAY | CoreType.v2ray | 2 |
| CoreType::WIREGUARD | CoreType.wireguard | 3 |
| DriverType::NONE | DriverType.none | 0 |
| DriverType::HEV_SOCKS5 | DriverType.hevSocks5 | 1 |
| DriverType::TUN2SOCKS | DriverType.tun2socks | 2 |
| ConnectionStatus::DISCONNECTED | ConnectionStatus.disconnected | 0 |
| ConnectionStatus::CONNECTING | ConnectionStatus.connecting | 1 |
| ConnectionStatus::CONNECTED | ConnectionStatus.connected | 2 |
| ConnectionStatus::DISCONNECTING | ConnectionStatus.disconnecting | 3 |
| ConnectionStatus::ERROR | ConnectionStatus.error | 4 |

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: (none - foundational types)
- **Used by**: All other domains (flutter-api-layer, configuration-system, native-bridge, etc.)

## Key Insights

1. **String Conversion**: All enums have toNativeString()/fromString() for serialization
2. **Int Mapping**: Explicit int values match C++ enum values for FFI
3. **Formatting Helpers**: ConnectionStats includes human-readable byte formatting
4. **Immutable Design**: ConnectionStats uses final fields with const constructor
5. **Foundational Layer**: These types are used throughout the entire codebase

## ADR Candidates

- (Data models are implementation details, no architectural decisions)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Simple data layer with clear serialization contracts

## Synthesis

### Combined Understanding

The Data Models provide:
1. **Type Enums**: CoreType, DriverType for component selection
2. **Status Enum**: ConnectionStatus for state machine representation
3. **Statistics**: ConnectionStats with traffic and latency metrics
4. **Serialization**: Consistent toNativeString/fromString and toMap/fromMap patterns
5. **Formatting**: Human-readable byte formatting utilities

### Type Relationships

```
CoreType ─────────────────────────┐
                                  │
DriverType ───────────────────────┼──> Configuration
                                  │
ConnectionStatus ─────────────────┼──> Runtime State
                                  │
ConnectionStats ──────────────────┘
```

## Bubble Up

> Summary to pass to parent during EXITING

- Four main types: CoreType, DriverType, ConnectionStatus, ConnectionStats
- Consistent serialization patterns (toNativeString, toMap, etc.)
- Int values aligned with C++ enums for FFI compatibility
- ConnectionStats includes byte formatting utilities

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
