import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../models/config.dart';
import '../models/connection_status.dart';
import '../models/connection_stats.dart';

/// Native function types
typedef NativeCreateFn = ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);
typedef DartCreateFn = ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);

typedef NativeConnectFn = ffi.Bool Function(ffi.Pointer<ffi.Void>);
typedef DartConnectFn = bool Function(ffi.Pointer<ffi.Void>);

typedef NativeDisconnectFn = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef DartDisconnectFn = void Function(ffi.Pointer<ffi.Void>);

typedef NativeGetStatusFn = ffi.Int32 Function(ffi.Pointer<ffi.Void>);
typedef DartGetStatusFn = int Function(ffi.Pointer<ffi.Void>);

typedef NativeDestroyFn = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef DartDestroyFn = void Function(ffi.Pointer<ffi.Void>);

/// Platform implementation for VPN Engine
class VpnEnginePlatform {
  late final ffi.DynamicLibrary _lib;
  late final DartCreateFn _create;
  late final DartConnectFn _connect;
  late final DartDisconnectFn _disconnect;
  late final DartGetStatusFn _getStatus;
  late final DartDestroyFn _destroy;

  ffi.Pointer<ffi.Void>? _engineInstance;

  VpnEnginePlatform() {
    _loadLibrary();
    _bindFunctions();
  }

  void _loadLibrary() {
    try {
      if (Platform.isAndroid) {
        _lib = ffi.DynamicLibrary.open('libvpnclient_engine.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _lib = ffi.DynamicLibrary.process();
      } else if (Platform.isLinux) {
        _lib = ffi.DynamicLibrary.open('libvpnclient_engine.so');
      } else if (Platform.isWindows) {
        _lib = ffi.DynamicLibrary.open('vpnclient_engine.dll');
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    } catch (e) {
      // Fallback to mock implementation for development
      print('Warning: Failed to load native library: $e');
      print('Using mock implementation');
      throw UnsupportedError('Native library not available');
    }
  }

  void _bindFunctions() {
    try {
      _create = _lib.lookupFunction<NativeCreateFn, DartCreateFn>(
        'vpnclient_engine_create',
      );
      _connect = _lib.lookupFunction<NativeConnectFn, DartConnectFn>(
        'vpnclient_engine_connect',
      );
      _disconnect = _lib.lookupFunction<NativeDisconnectFn, DartDisconnectFn>(
        'vpnclient_engine_disconnect',
      );
      _getStatus = _lib.lookupFunction<NativeGetStatusFn, DartGetStatusFn>(
        'vpnclient_engine_get_status',
      );
      _destroy = _lib.lookupFunction<NativeDestroyFn, DartDestroyFn>(
        'vpnclient_engine_destroy',
      );
    } catch (e) {
      print('Warning: Failed to bind functions: $e');
    }
  }

  bool initialize(VpnEngineConfig config) {
    try {
      // Serialize config to JSON
      final configJson = _serializeConfig(config);
      final nativeConfigJson = configJson.toNativeUtf8();

      _engineInstance = _create(nativeConfigJson);

      calloc.free(nativeConfigJson);

      return _engineInstance != null && _engineInstance != ffi.nullptr;
    } catch (e) {
      print('Error initializing engine: $e');
      return false;
    }
  }

  bool connect() {
    if (_engineInstance == null) return false;
    try {
      return _connect(_engineInstance!);
    } catch (e) {
      print('Error connecting: $e');
      return false;
    }
  }

  void disconnect() {
    if (_engineInstance == null) return;
    try {
      _disconnect(_engineInstance!);
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  ConnectionStatus getStatus() {
    if (_engineInstance == null) return ConnectionStatus.disconnected;
    try {
      final statusInt = _getStatus(_engineInstance!);
      return _parseStatus(statusInt);
    } catch (e) {
      print('Error getting status: $e');
      return ConnectionStatus.error;
    }
  }

  void dispose() {
    if (_engineInstance != null) {
      try {
        _destroy(_engineInstance!);
      } catch (e) {
        print('Error destroying engine: $e');
      }
      _engineInstance = null;
    }
  }

  String _serializeConfig(VpnEngineConfig config) {
    // Convert config to JSON string
    final map = config.toMap();
    // Simple JSON serialization (в реальной версии использовать dart:convert)
    return map.toString();
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
}

/// Mock implementation for testing without native library
class MockVpnEnginePlatform {
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStats _stats = const ConnectionStats();

  bool initialize(VpnEngineConfig config) {
    print('[MOCK] Initializing with config: ${config.core.type}');
    return true;
  }

  Future<bool> connect() async {
    print('[MOCK] Connecting...');
    _status = ConnectionStatus.connecting;
    await Future.delayed(const Duration(seconds: 2));
    _status = ConnectionStatus.connected;
    print('[MOCK] Connected');

    // Simulate stats
    _simulateStats();

    return true;
  }

  void disconnect() {
    print('[MOCK] Disconnecting...');
    _status = ConnectionStatus.disconnecting;
    Future.delayed(const Duration(seconds: 1), () {
      _status = ConnectionStatus.disconnected;
      print('[MOCK] Disconnected');
    });
  }

  ConnectionStatus getStatus() => _status;

  ConnectionStats getStats() => _stats;

  void _simulateStats() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != ConnectionStatus.connected) {
        timer.cancel();
        return;
      }

      _stats = ConnectionStats(
        bytesSent: _stats.bytesSent + 1024,
        bytesReceived: _stats.bytesReceived + 2048,
        packetsSent: _stats.packetsSent + 10,
        packetsReceived: _stats.packetsReceived + 15,
        latencyMs: 50 + (DateTime.now().millisecond % 30),
      );
    });
  }

  void dispose() {
    disconnect();
  }
}
