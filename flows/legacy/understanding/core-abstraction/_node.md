# Understanding: Core Abstraction

> VPN protocol handling layer with pluggable core implementations.

## Phase: SYNTHESIZING

## Hypothesis

Interface-based abstraction layer (ICore) that allows swapping between different VPN protocol implementations (SingBox, LibXray, V2Ray, WireGuard) without changing calling code.

## Sources

> Files/directories that inform this understanding

- `include/vpnclient_engine.h` - ICore interface definition (lines 93-102)
- `include/cores/core_base.h` - BaseCore abstract class
- `include/cores/singbox_core.h` - SingBox implementation header
- `include/cores/libxray_core.h` - LibXray implementation header
- `include/cores/v2ray_core.h` - V2Ray implementation header
- `src/cores/*.cpp` - Implementation files
- `lib/src/models/core_type.dart` - Dart enum for core types

## Validated Understanding

### ICore Interface (C++)

```cpp
class ICore {
public:
    virtual ~ICore() = default;
    virtual bool initialize(const CoreConfig& config) = 0;
    virtual bool start() = 0;
    virtual void stop() = 0;
    virtual bool is_running() const = 0;
    virtual std::string get_name() const = 0;
    virtual std::string get_version() const = 0;
};
```

### CoreConfig Structure

```cpp
struct CoreConfig : public BaseConfig {
    CoreType type = CoreType::SINGBOX;     // Core selection
    std::string server_address;             // VPN server
    uint16_t server_port = 0;               // Server port
    std::string protocol;                   // vless, vmess, etc.
    // Inherited: config_json, enable_logging, log_level
};
```

### Core Implementations

| Core | Built-in TUN | Requires Driver | Protocols |
|------|-------------|-----------------|-----------|
| SingBox | Yes | No | vless, vmess, trojan, shadowsocks, hysteria |
| LibXray | No | Yes | vless, vmess, trojan, shadowsocks |
| V2Ray | No | Yes | vless, vmess, trojan, shadowsocks |
| WireGuard | Yes | No | wireguard |

### CoreFactory

Factory pattern for core instantiation:

```cpp
std::unique_ptr<ICore> CoreFactory::create(CoreType type) {
    switch (type) {
        case CoreType::SINGBOX:  return std::make_unique<cores::SingBoxCore>();
        case CoreType::LIBXRAY:  return std::make_unique<cores::LibXrayCore>();
        case CoreType::V2RAY:    return std::make_unique<cores::V2RayCore>();
        default:                 return nullptr;
    }
}
```

### BaseCore Abstract Class

Provides common functionality:
- `running_` state tracking
- `name_` and `version_` storage
- `log()` helper method
- Default `is_running()`, `get_name()`, `get_version()` implementations

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: configuration-system (CoreConfig)
- **Used by**: native-bridge (VPNClientEngineImpl), flutter-api-layer (via CoreType enum)

## Key Insights

1. **Strategy Pattern**: ICore interface allows runtime core selection
2. **Factory Pattern**: CoreFactory::create() handles instantiation
3. **Driver Requirement Matrix**: SingBox/WireGuard self-contained, LibXray/V2Ray need external SOCKS driver
4. **JSON Configuration**: All cores accept configJson for protocol-specific settings
5. **Lifecycle Contract**: initialize() -> start() -> stop() with is_running() checks

## ADR Candidates

- ADR-002: Core/Driver requirement matrix (SingBox/WireGuard built-in TUN vs LibXray/V2Ray requiring driver)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Internal service interface with clear contract, multiple implementations

## Synthesis

### Combined Understanding

The Core Abstraction provides:
1. **Unified Interface**: ICore defines contract for all VPN protocol handlers
2. **Pluggable Implementations**: SingBox, LibXray, V2Ray, WireGuard
3. **Factory-Based Creation**: CoreFactory handles instantiation logic
4. **Driver Awareness**: Some cores (SingBox, WireGuard) have built-in TUN, others require external driver
5. **Configuration Flexibility**: JSON-based protocol configuration

### Core Lifecycle

```
CoreFactory::create(type)
        |
        v
  ICore::initialize(config)
        |
        v
   ICore::start()
        |
        v
   [VPN ACTIVE]
        |
        v
   ICore::stop()
```

## Bubble Up

> Summary to pass to parent during EXITING

- ICore interface provides unified contract for VPN protocol handlers
- Four implementations: SingBox, LibXray, V2Ray, WireGuard
- SingBox/WireGuard have built-in TUN; LibXray/V2Ray require external driver
- Factory pattern for core instantiation

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
