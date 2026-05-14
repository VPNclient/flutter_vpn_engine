# Understanding: Driver Abstraction

> Traffic tunneling layer providing TUN interface management and SOCKS proxy routing.

## Phase: SYNTHESIZING

## Hypothesis

Interface-based abstraction (IDriver) for traffic tunneling implementations that route packets through SOCKS5 proxy to the VPN core.

## Sources

> Files/directories that inform this understanding

- `include/vpnclient_engine.h` - IDriver interface definition (lines 82-90)
- `include/drivers/driver_base.h` - BaseDriver abstract class
- `include/drivers/hev_socks5_driver.h` - HevSocks5 implementation
- `include/drivers/tun2socks_driver.h` - Tun2Socks implementation
- `src/drivers/*.cpp` - Implementation files
- `lib/src/models/driver_type.dart` - Dart enum for driver types
- `lib/src/core/engine_manager.dart` - Driver requirement logic

## Validated Understanding

### IDriver Interface (C++)

```cpp
class IDriver {
public:
    virtual ~IDriver() = default;
    virtual bool initialize(const DriverConfig& config) = 0;
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual bool is_running() const = 0;
    virtual std::string get_name() const = 0;
};
```

### DriverConfig Structure

```cpp
struct DriverConfig : public BaseConfig {
    DriverType type = DriverType::NONE;
    uint16_t mtu = 1500;
    std::string tun_name = "tun0";
    std::string tun_address = "10.0.0.2";
    std::string tun_gateway = "10.0.0.1";
    std::string tun_netmask = "255.255.255.0";
    std::string dns_server = "8.8.8.8";
    // Inherited: config_json, enable_logging, log_level
};
```

### Driver Implementations

| Driver | Technology | Use Case |
|--------|------------|----------|
| HevSocks5 | hev-socks5-tunnel | Default, lightweight |
| Tun2Socks | tun2socks | Alternative, more features |
| None | - | For cores with built-in TUN |

### DriverFactory

```cpp
std::unique_ptr<IDriver> DriverFactory::create(DriverType type) {
    switch (type) {
        case DriverType::HEV_SOCKS5: return std::make_unique<drivers::HevSocks5Driver>();
        case DriverType::TUN2SOCKS:  return std::make_unique<drivers::Tun2SocksDriver>();
        case DriverType::NONE:
        default:                     return nullptr;
    }
}
```

### EngineManager Driver Logic (Dart)

```dart
static bool requiresDriver(CoreType core) {
    switch (core) {
        case CoreType.singbox:   return false; // Built-in TUN
        case CoreType.wireguard: return false; // Built-in TUN
        case CoreType.libxray:   return true;  // Needs SOCKS driver
        case CoreType.v2ray:     return true;  // Needs SOCKS driver
    }
}

static DriverType? getRecommendedDriver(CoreType core) {
    if (requiresDriver(core)) {
        return DriverType.hevSocks5; // Default recommendation
    }
    return null;
}
```

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: configuration-system (DriverConfig)
- **Used by**: native-bridge (VPNClientEngineImpl), flutter-api-layer (via EngineManager)

## Key Insights

1. **Strategy Pattern**: IDriver interface allows runtime driver selection
2. **Factory Pattern**: DriverFactory::create() handles instantiation
3. **Optional Component**: Drivers only needed for cores without built-in TUN
4. **HevSocks5 Default**: Recommended for its lightweight footprint
5. **TUN Configuration**: Configurable IP, gateway, MTU, DNS for all drivers

## ADR Candidates

- ADR-001: HevSocks5 as default driver (lightweight, reliable)
- ADR-002: Core/Driver requirement matrix (determines when drivers are needed)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Internal service interface, optional component based on core selection

## Synthesis

### Combined Understanding

The Driver Abstraction provides:
1. **Unified Interface**: IDriver defines contract for traffic tunneling
2. **Two Implementations**: HevSocks5 (default), Tun2Socks (alternative)
3. **Conditional Usage**: Only instantiated when core requires external TUN
4. **TUN Configuration**: Flexible IP addressing and DNS configuration
5. **Factory-Based Creation**: DriverFactory handles instantiation

### Driver Lifecycle

```
EngineManager::requiresDriver(coreType)
        |
        v
    [true?] ─────────────────────────────┐
        |                                 |
        v                                 v
DriverFactory::create(type)          (skip driver)
        |
        v
  IDriver::initialize(config)
        |
        v
   IDriver::start()
        |
        v
   [TUNNELING ACTIVE]
        |
        v
   IDriver::stop()
```

## Bubble Up

> Summary to pass to parent during EXITING

- IDriver interface provides contract for traffic tunneling
- Two implementations: HevSocks5 (recommended default), Tun2Socks
- Only needed for LibXray/V2Ray cores (SingBox/WireGuard have built-in TUN)
- Configurable TUN parameters: IP, gateway, MTU, DNS

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
