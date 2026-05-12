import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'unified_platform_interface.dart';
import '../models/tun_options.dart';
import '../models/platform_tun_handle.dart';

/// Windows реализация Unified Platform Interface
/// Использует TAP адаптеры через Win32 API
class WindowsPlatformInterface implements UnifiedPlatformInterface {
  late final ffi.DynamicLibrary _nativeLib;
  PlatformTunHandle? _currentHandle;

  WindowsPlatformInterface() {
    _nativeLib = _loadLibrary();
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('vpnclient_engine.dll');
    }
    throw UnsupportedError('Windows platform interface only works on Windows');
  }

  @override
  Future<PlatformTunHandle> openTun(TunOptions options) async {
    try {
      // Вызов нативной функции для открытия TAP адаптера
      final openTunFunc = _nativeLib.lookupFunction<
          ffi.IntPtr Function(ffi.Pointer<Utf8>),
          int Function(ffi.Pointer<Utf8>)>('windows_open_tun');

      final optionsJson = _optionsToJson(options);
      final optionsPtr = optionsJson.toNativeUtf8();

      try {
        final handle = openTunFunc(optionsPtr);
        
        if (handle == 0 || handle == -1) {
          throw Exception('Failed to open TUN interface: invalid handle');
        }

        _currentHandle = WindowsTunHandle(handle);
        return _currentHandle!;
      } finally {
        malloc.free(optionsPtr);
      }
    } catch (e) {
      throw Exception('Failed to open TUN: $e');
    }
  }

  @override
  Future<void> closeTun(PlatformTunHandle handle) async {
    try {
      final closeTunFunc = _nativeLib.lookupFunction<
          ffi.Void Function(ffi.IntPtr),
          void Function(int)>('windows_close_tun');

      closeTunFunc(handle.fileDescriptor);
      _currentHandle = null;
    } catch (e) {
      throw Exception('Failed to close TUN: $e');
    }
  }

  @override
  Future<void> setupRoutes(TunOptions options) async {
    try {
      final setupRoutesFunc = _nativeLib.lookupFunction<
          ffi.Int32 Function(ffi.Pointer<Utf8>),
          int Function(ffi.Pointer<Utf8>)>('windows_setup_routes');

      final optionsJson = _optionsToJson(options);
      final optionsPtr = optionsJson.toNativeUtf8();

      try {
        final result = setupRoutesFunc(optionsPtr);
        
        if (result < 0) {
          throw Exception('Failed to setup routes: error code $result');
        }
      } finally {
        malloc.free(optionsPtr);
      }
    } catch (e) {
      throw Exception('Failed to setup routes: $e');
    }
  }

  @override
  Future<bool> checkPrivileges() async {
    // Проверка прав администратора на Windows
    try {
      final checkPrivilegesFunc = _nativeLib.lookupFunction<
          ffi.Bool Function(),
          bool Function()>('windows_check_privileges');

      return checkPrivilegesFunc();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setupPerAppProxy({
    required List<String> packages,
    required String mode,
  }) async {
    throw UnsupportedError('Per-app proxy is not supported on Windows');
  }

  @override
  Future<void> clearDNSCache() async {
    // На Windows можно очистить DNS кеш через ipconfig /flushdns
    // Но это требует системных привилегий
  }

  @override
  Future<List<NetworkInterfaceInfo>> getNetworkInterfaces() async {
    // Можно реализовать через Windows API (GetAdaptersInfo)
    // Пока возвращаем пустой список
    return [];
  }

  @override
  void dispose() {
    if (_currentHandle != null) {
      closeTun(_currentHandle!);
    }
    _currentHandle = null;
  }

  String _optionsToJson(TunOptions options) {
    final buffer = StringBuffer();
    buffer.write('{');
    buffer.write('"mtu":${options.mtu},');
    buffer.write('"tunName":"${options.tunName}",');
    if (options.ipv4Address != null) {
      buffer.write('"ipv4Address":"${options.ipv4Address}",');
    }
    if (options.ipv4Netmask != null) {
      buffer.write('"ipv4Netmask":"${options.ipv4Netmask}",');
    }
    if (options.dnsServer != null) {
      buffer.write('"dnsServer":"${options.dnsServer}",');
    }
    buffer.write('"autoRoute":${options.autoRoute}');
    buffer.write('}');
    return buffer.toString();
  }
}

