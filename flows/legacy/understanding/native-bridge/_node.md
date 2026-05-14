# Understanding: Native Bridge

> FFI bindings and platform channel communication between Dart and C++ layers.

## Phase: SYNTHESIZING

## Hypothesis

Bridge layer providing FFI (Foreign Function Interface) bindings for native C++ engine and MethodChannel for platform-specific callbacks.

## Sources

> Files/directories that inform this understanding

- `lib/src/platform/vpn_engine_platform.dart` - FFI bindings (277 lines)
- `src/core/vpnclient_engine_c_api.cpp` - C API exports
- `include/vpnclient_engine_c_api.h` - C API header

## Validated Understanding

### VpnEngineBindings (Dart FFI)

```dart
class VpnEngineBindings {
    late final DynamicLibrary _lib;

    VpnEngineBindings() {
        _lib = _loadLibrary(); // Platform-specific library loading
    }

    DynamicLibrary _loadLibrary() {
        if (Platform.isAndroid) return DynamicLibrary.open('libvpnclient_engine.so');
        if (Platform.isIOS || Platform.isMacOS) return DynamicLibrary.process();
        if (Platform.isLinux) return DynamicLibrary.open('libvpnclient_engine.so');
        if (Platform.isWindows) return DynamicLibrary.open('vpnclient_engine.dll');
    }

    // FFI function bindings
    NativeEngineInstance create(Pointer<NativeEngineConfig> config);
    bool connect(NativeEngineInstance instance);
    void disconnect(NativeEngineInstance instance);
    int getStatus(NativeEngineInstance instance);
    bool getStats(NativeEngineInstance instance, Pointer<NativeEngineStats> stats);
    void destroy(NativeEngineInstance instance);
}
```

### Native Structs

```dart
final class NativeEngineConfig extends Struct {
    @Int32() external int core_type;
    @Int32() external int driver_type;
    external Pointer<Utf8> config_json;
}

final class NativeEngineStats extends Struct {
    @Uint64() external int bytes_sent;
    @Uint64() external int bytes_received;
    @Uint64() external int packets_sent;
    @Uint64() external int packets_received;
    @Uint32() external int latency_ms;
}
```

### VpnEnginePlatform (Platform Implementation)

```dart
class VpnEnginePlatform {
    late final VpnEngineBindings _bindings;
    NativeEngineInstance? _engineInstance;

    bool initialize(VpnEngineConfig config);  // Create native instance
    Future<bool> connect();                   // Connect via FFI
    void disconnect();                        // Disconnect via FFI
    ConnectionStatus getStatus();             // Query status
    ConnectionStats getStats();               // Query statistics
    void dispose();                           // Destroy native instance
}
```

### Type Mapping

| Dart Type | Native Type | FFI Type |
|-----------|-------------|----------|
| CoreType enum | CoreType enum | int32 |
| DriverType enum | DriverType enum | int32 |
| ConnectionStatus | ConnectionStatus | int32 |
| VpnEngineConfig | Config struct | Struct pointer |
| ConnectionStats | ConnectionStats | Struct pointer |

### Memory Management

```dart
bool initialize(VpnEngineConfig config) {
    final nativeConfig = calloc<NativeEngineConfig>();
    try {
        nativeConfig.ref.core_type = _coreTypeToNative(config.core.type);
        nativeConfig.ref.driver_type = _driverTypeToNative(config.driver.type);
        nativeConfig.ref.config_json = configJson.toNativeUtf8();

        _engineInstance = _bindings.create(nativeConfig);
        return _engineInstance != null && _engineInstance != nullptr;
    } finally {
        if (nativeConfig.ref.config_json != nullptr) {
            calloc.free(nativeConfig.ref.config_json);
        }
        calloc.free(nativeConfig);
    }
}
```

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: configuration-system (VpnEngineConfig), data-models (ConnectionStatus, ConnectionStats)
- **Used by**: flutter-api-layer (VpnClientEngine._platform)

## Key Insights

1. **Platform-Specific Loading**: Different library names for Android, iOS, Linux, Windows
2. **Struct Marshaling**: FFI structs map directly to C++ structs
3. **Memory Safety**: calloc/free pattern for native memory allocation
4. **Enum Mapping**: Dart enums converted to native int32 values
5. **Sync FFI Calls**: Most operations are synchronous FFI invocations

## ADR Candidates

- ADR-004: FFI-based native communication vs method channels (hybrid approach - FFI for engine, MethodChannel for callbacks)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Internal bridge layer with clear FFI contracts

## Synthesis

### Combined Understanding

The Native Bridge provides:
1. **FFI Bindings**: Dynamic library loading and function lookup
2. **Struct Marshaling**: Dart <-> C++ struct conversion
3. **Memory Management**: Safe allocation/deallocation pattern
4. **Platform Abstraction**: Unified interface across 5 platforms
5. **Type Mapping**: Enum and struct conversion utilities

### Communication Flow

```
VpnClientEngine (Dart)
      |
      v [Dart method call]
VpnEnginePlatform
      |
      v [FFI call]
VpnEngineBindings
      |
      v [dlsym/lookup]
C API (vpnclient_engine_create, etc.)
      |
      v
VPNClientEngineImpl (C++)
```

## Bubble Up

> Summary to pass to parent during EXITING

- FFI-based bridge with platform-specific library loading
- NativeEngineConfig/NativeEngineStats structs for data marshaling
- Memory-safe allocation pattern with calloc/free
- Synchronous FFI calls wrapped in VpnEnginePlatform

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
