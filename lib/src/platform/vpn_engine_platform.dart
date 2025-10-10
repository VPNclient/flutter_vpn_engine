import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../models/config.dart';
import '../models/connection_status.dart';
import '../models/connection_stats.dart';

/// Native VPN Engine instance pointer
typedef NativeEngineInstance = ffi.Pointer<ffi.Void>;

/// Native configuration struct
final class NativeEngineConfig extends ffi.Struct {
  @ffi.Int32()
  external int core_type;

  @ffi.Int32()
  external int driver_type;

  external ffi.Pointer<Utf8> config_json;
}

/// Native statistics struct
final class NativeEngineStats extends ffi.Struct {
  @ffi.Uint64()
  external int bytes_sent;

  @ffi.Uint64()
  external int bytes_received;

  @ffi.Uint64()
  external int packets_sent;

  @ffi.Uint64()
  external int packets_received;

  @ffi.Uint32()
  external int latency_ms;
}

/// FFI bindings for VPN Engine
class VpnEngineBindings {
  late final ffi.DynamicLibrary _lib;

  VpnEngineBindings() {
    _lib = _loadLibrary();
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libvpnclient_engine.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libvpnclient_engine.so');
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('vpnclient_engine.dll');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  NativeEngineInstance create(ffi.Pointer<NativeEngineConfig> config) {
    return _lib.lookupFunction<
        NativeEngineInstance Function(ffi.Pointer<NativeEngineConfig>),
        NativeEngineInstance Function(ffi.Pointer<NativeEngineConfig>)>(
      'vpnclient_engine_create',
    )(config);
  }

  bool connect(NativeEngineInstance instance) {
    return _lib.lookupFunction<ffi.Bool Function(NativeEngineInstance),
        bool Function(NativeEngineInstance)>(
      'vpnclient_engine_connect',
    )(instance);
  }

  void disconnect(NativeEngineInstance instance) {
    _lib.lookupFunction<ffi.Void Function(NativeEngineInstance),
        void Function(NativeEngineInstance)>(
      'vpnclient_engine_disconnect',
    )(instance);
  }

  int getStatus(NativeEngineInstance instance) {
    return _lib.lookupFunction<ffi.Int32 Function(NativeEngineInstance),
        int Function(NativeEngineInstance)>(
      'vpnclient_engine_get_status',
    )(instance);
  }

  bool getStats(
    NativeEngineInstance instance,
    ffi.Pointer<NativeEngineStats> stats,
  ) {
    return _lib.lookupFunction<
        ffi.Bool Function(
          NativeEngineInstance,
          ffi.Pointer<NativeEngineStats>,
        ),
        bool Function(
          NativeEngineInstance,
          ffi.Pointer<NativeEngineStats>,
        )>(
      'vpnclient_engine_get_stats',
    )(instance, stats);
  }

  void destroy(NativeEngineInstance instance) {
    _lib.lookupFunction<ffi.Void Function(NativeEngineInstance),
        void Function(NativeEngineInstance)>(
      'vpnclient_engine_destroy',
    )(instance);
  }
}

/// Platform implementation for VPN Engine
class VpnEnginePlatform {
  late final VpnEngineBindings _bindings;
  NativeEngineInstance? _engineInstance;

  VpnEnginePlatform() {
    _bindings = VpnEngineBindings();
  }

  bool initialize(VpnEngineConfig config) {
    final nativeConfig = calloc<NativeEngineConfig>();

    try {
      // Map CoreType to native enum
      nativeConfig.ref.core_type = _coreTypeToNative(config.core.type);
      nativeConfig.ref.driver_type = _driverTypeToNative(config.driver.type);

      // Serialize config to JSON
      final configMap = config.toMap();
      final configJson = _serializeToJson(configMap);
      nativeConfig.ref.config_json = configJson.toNativeUtf8();

      // Create engine instance
      _engineInstance = _bindings.create(nativeConfig);

      return _engineInstance != null && _engineInstance != ffi.nullptr;
    } finally {
      if (nativeConfig.ref.config_json != ffi.nullptr) {
        calloc.free(nativeConfig.ref.config_json);
      }
      calloc.free(nativeConfig);
    }
  }

  Future<bool> connect() async {
    if (_engineInstance == null) return false;

    return await Future(() {
      return _bindings.connect(_engineInstance!);
    });
  }

  void disconnect() {
    if (_engineInstance == null) return;
    _bindings.disconnect(_engineInstance!);
  }

  ConnectionStatus getStatus() {
    if (_engineInstance == null) return ConnectionStatus.disconnected;

    final statusInt = _bindings.getStatus(_engineInstance!);
    return _parseStatus(statusInt);
  }

  ConnectionStats getStats() {
    if (_engineInstance == null) return const ConnectionStats();

    final nativeStats = calloc<NativeEngineStats>();
    try {
      final success = _bindings.getStats(_engineInstance!, nativeStats);
      if (!success) return const ConnectionStats();

      return ConnectionStats(
        bytesSent: nativeStats.ref.bytes_sent,
        bytesReceived: nativeStats.ref.bytes_received,
        packetsSent: nativeStats.ref.packets_sent,
        packetsReceived: nativeStats.ref.packets_received,
        latencyMs: nativeStats.ref.latency_ms,
      );
    } finally {
      calloc.free(nativeStats);
    }
  }

  void dispose() {
    if (_engineInstance != null) {
      _bindings.destroy(_engineInstance!);
      _engineInstance = null;
    }
  }

  int _coreTypeToNative(CoreType type) {
    switch (type) {
      case CoreType.singbox:
        return 0;
      case CoreType.libxray:
        return 1;
      case CoreType.v2ray:
        return 2;
      case CoreType.wireguard:
        return 3;
    }
  }

  int _driverTypeToNative(DriverType type) {
    switch (type) {
      case DriverType.none:
        return 0;
      case DriverType.hevSocks5:
        return 1;
      case DriverType.tun2socks:
        return 2;
    }
  }

  ConnectionStatus _parseStatus(int status) {
    switch (status) {
      case 0:
        return ConnectionStatus.disconnected;
      case 1:
        return ConnectionStatus.connecting;
      case 2:
        return ConnectionStatus.connected;
      case 3:
        return ConnectionStatus.disconnecting;
      case 4:
        return ConnectionStatus.error;
      default:
        return ConnectionStatus.disconnected;
    }
  }

  String _serializeToJson(Map<String, dynamic> map) {
    // Simple JSON serialization
    final buffer = StringBuffer();
    buffer.write('{');

    final entries = map.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');

      final value = entry.value;
      if (value is String) {
        buffer.write('"${_escapeJson(value)}"');
      } else if (value is num || value is bool) {
        buffer.write(value);
      } else if (value is Map) {
        buffer.write(_serializeToJson(Map<String, dynamic>.from(value)));
      } else {
        buffer.write('null');
      }

      if (i < entries.length - 1) buffer.write(',');
    }

    buffer.write('}');
    return buffer.toString();
  }

  String _escapeJson(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
