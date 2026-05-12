import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'unified_platform_interface.dart';
import '../models/tun_options.dart';
import '../models/platform_tun_handle.dart';

/// Linux реализация Unified Platform Interface
/// Использует прямой доступ к /dev/net/tun через FFI
class LinuxPlatformInterface implements UnifiedPlatformInterface {
  late final ffi.DynamicLibrary _nativeLib;
  PlatformTunHandle? _currentHandle;

  LinuxPlatformInterface() {
    _nativeLib = _loadLibrary();
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libvpnclient_engine.so');
    }
    throw UnsupportedError('Linux platform interface only works on Linux');
  }

  @override
  Future<PlatformTunHandle> openTun(TunOptions options) async {
    try {
      // Вызов нативной функции для открытия TUN
      final openTunFunc = _nativeLib.lookupFunction<
          ffi.Int32 Function(ffi.Pointer<Utf8>),
          int Function(ffi.Pointer<Utf8>)>('linux_open_tun');

      final optionsJson = _optionsToJson(options);
      final optionsPtr = optionsJson.toNativeUtf8();

      try {
        final fd = openTunFunc(optionsPtr);
        
        if (fd < 0) {
          throw Exception('Failed to open TUN interface: error code $fd');
        }

        _currentHandle = LinuxTunHandle(fd);
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
          ffi.Void Function(ffi.Int32),
          void Function(int)>('linux_close_tun');

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
          int Function(ffi.Pointer<Utf8>)>('linux_setup_routes');

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
    // Проверка прав доступа к /dev/net/tun
    try {
      final checkPrivilegesFunc = _nativeLib.lookupFunction<
          ffi.Bool Function(),
          bool Function()>('linux_check_privileges');

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
    throw UnsupportedError('Per-app proxy is not supported on Linux');
  }

  @override
  Future<void> clearDNSCache() async {
    // На Linux очистка DNS кеша не требуется
    // DNS кеш управляется systemd-resolved или nscd
  }

  @override
  Future<List<NetworkInterfaceInfo>> getNetworkInterfaces() async {
    // Можно реализовать через netlink socket
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
    // Простая JSON сериализация для передачи в нативный код
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

