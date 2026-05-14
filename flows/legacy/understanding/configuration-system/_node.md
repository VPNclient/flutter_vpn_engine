# Understanding: Configuration System

> Hierarchical configuration classes for VPN engine, core, and driver settings.

## Phase: SYNTHESIZING

## Hypothesis

Multi-level configuration system with VpnEngineConfig as root, containing CoreConfig and DriverConfig for component-specific settings.

## Sources

> Files/directories that inform this understanding

- `lib/src/models/config.dart` - Dart configuration classes (189 lines)
- `lib/src/core/engine_config.dart` - Additional config utilities
- `lib/src/core/engine_manager.dart` - Config optimization logic
- `include/vpnclient_engine.h` - C++ config structures

## Validated Understanding

### Configuration Hierarchy

```
VpnEngineConfig (root)
├── CoreConfig          # VPN protocol settings
├── DriverConfig        # Traffic tunneling settings
├── autoConnect         # Auto-connect flag
└── connectionTimeout   # Timeout in seconds
```

### VpnEngineConfig (Dart)

```dart
class VpnEngineConfig {
    final CoreConfig core;
    final DriverConfig driver;
    final bool autoConnect;
    final int connectionTimeout;

    const VpnEngineConfig({
        required this.core,
        this.driver = const DriverConfig(),
        this.autoConnect = false,
        this.connectionTimeout = 30,
    });

    Map<String, dynamic> toMap();
    factory VpnEngineConfig.fromMap(Map<String, dynamic> map);
}
```

### CoreConfig

```dart
class CoreConfig {
    final CoreType type;       // singbox, libxray, v2ray, wireguard
    final String configJson;   // Protocol-specific JSON config
    final String? serverAddress;
    final int? serverPort;
    final String? protocol;    // vless, vmess, etc.
    final String logLevel;     // info, debug, error
    final bool enableLogging;
}
```

### DriverConfig

```dart
class DriverConfig {
    final DriverType type;     // none, hevSocks5, tun2socks
    final String configJson;
    final int mtu;             // 1500 default
    final String tunName;      // tun0 default
    final String tunAddress;   // 10.0.0.2 default
    final String tunGateway;   // 10.0.0.1 default
    final String tunNetmask;   // 255.255.255.0 default
    final String dnsServer;    // 8.8.8.8 default
    final String logLevel;
    final bool enableLogging;
}
```

### C++ Equivalent (include/vpnclient_engine.h)

```cpp
struct Config {
    CoreConfig core;
    DriverConfig driver;
    bool auto_connect = false;
    int connection_timeout = 30;
};

struct CoreConfig : public BaseConfig {
    CoreType type = CoreType::SINGBOX;
    std::string server_address;
    uint16_t server_port = 0;
    std::string protocol;
};

struct DriverConfig : public BaseConfig {
    DriverType type = DriverType::NONE;
    uint16_t mtu = 1500;
    std::string tun_name = "tun0";
    std::string tun_address = "10.0.0.2";
    std::string tun_gateway = "10.0.0.1";
    std::string tun_netmask = "255.255.255.0";
    std::string dns_server = "8.8.8.8";
};
```

### EngineManager Optimization

```dart
static VpnEngineConfig createOptimalConfig({
    required CoreType core,
    required String configJson,
    TunOptions? tunOptions,
    DriverType? explicitDriver,
}) {
    final needsDriver = requiresDriver(core);

    // Auto-select driver if needed
    DriverType driverType;
    if (explicitDriver != null && explicitDriver != DriverType.none) {
        driverType = explicitDriver;
    } else if (needsDriver) {
        driverType = DriverType.hevSocks5; // Default recommendation
    } else {
        driverType = DriverType.none;
    }

    return VpnEngineConfig(
        core: CoreConfig(type: core, configJson: configJson),
        driver: _createDriverConfigFromTunOptions(tunOptions, driverType, needsDriver),
    );
}
```

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: data-models (CoreType, DriverType enums)
- **Used by**: flutter-api-layer (VpnClientEngine), native-bridge (serialization)

## Key Insights

1. **Hierarchical Design**: Root config contains component-specific configs
2. **Sensible Defaults**: TUN defaults suitable for most deployments
3. **Serialization**: `toMap()`/`fromMap()` for JSON serialization
4. **Optimization Helper**: EngineManager auto-selects driver based on core type
5. **Dart/C++ Parity**: Configuration structures mirror between Dart and C++

## ADR Candidates

- (Configuration structure is an implementation detail, no architectural decision)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Data model layer with serialization contracts

## Synthesis

### Combined Understanding

The Configuration System provides:
1. **Hierarchical Structure**: VpnEngineConfig -> CoreConfig + DriverConfig
2. **Default Values**: Sensible defaults for all TUN parameters
3. **Serialization**: JSON-compatible toMap/fromMap pattern
4. **Auto-Optimization**: EngineManager selects appropriate driver
5. **Cross-Language Parity**: Matching Dart and C++ structures

### Configuration Flow

```
User Specifies:
- CoreType (singbox, libxray, v2ray, wireguard)
- configJson (protocol-specific config)
- (optional) DriverType override
- (optional) TunOptions

      |
      v
EngineManager.createOptimalConfig()
      |
      v
VpnEngineConfig
├── CoreConfig (type, configJson, ...)
└── DriverConfig (auto or explicit, TUN params)
      |
      v
VpnClientEngine.initialize(config)
      |
      v
Serialized to native via FFI
```

## Bubble Up

> Summary to pass to parent during EXITING

- Hierarchical config: VpnEngineConfig contains CoreConfig and DriverConfig
- EngineManager provides optimization helper for config creation
- Sensible defaults for TUN parameters (10.0.0.x network, 1500 MTU)
- JSON serialization via toMap/fromMap pattern

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
