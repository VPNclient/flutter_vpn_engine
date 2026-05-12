import 'dart:async';
import 'package:flutter/services.dart';
import 'unified_platform_interface.dart';
import '../models/tun_options.dart';
import '../models/platform_tun_handle.dart';

/// iOS реализация Unified Platform Interface
/// Использует NetworkExtension через MethodChannel
class IOSPlatformInterface implements UnifiedPlatformInterface {
  static const MethodChannel _channel = MethodChannel('vpnclient_engine');

  PlatformTunHandle? _currentHandle;

  @override
  Future<PlatformTunHandle> openTun(TunOptions options) async {
    try {
      final result = await _channel.invokeMethod<int>('openTun', options.toMap());
      
      if (result == null || result < 0) {
        throw PlatformException(
          code: 'TUN_OPEN_FAILED',
          message: 'Failed to open TUN interface on iOS',
        );
      }

      _currentHandle = IOSTunHandle(result);
      return _currentHandle!;
    } on PlatformException catch (e) {
      throw Exception('Failed to open TUN: ${e.message}');
    }
  }

  @override
  Future<void> closeTun(PlatformTunHandle handle) async {
    try {
      await _channel.invokeMethod('closeTun', {'fd': handle.fileDescriptor});
      _currentHandle = null;
    } on PlatformException catch (e) {
      throw Exception('Failed to close TUN: ${e.message}');
    }
  }

  @override
  Future<void> setupRoutes(TunOptions options) async {
    try {
      await _channel.invokeMethod('setupRoutes', options.toMap());
    } on PlatformException catch (e) {
      throw Exception('Failed to setup routes: ${e.message}');
    }
  }

  @override
  Future<bool> checkPrivileges() async {
    // iOS всегда требует привилегии для NetworkExtension
    // Проверка выполняется системой при запуске расширения
    return true;
  }

  @override
  Future<void> setupPerAppProxy({
    required List<String> packages,
    required String mode,
  }) async {
    // Per-app proxy не поддерживается на iOS через NetworkExtension
    throw UnsupportedError('Per-app proxy is not supported on iOS');
  }

  @override
  Future<void> clearDNSCache() async {
    try {
      await _channel.invokeMethod('clearDNSCache');
    } on PlatformException {
      // Игнорируем ошибки очистки DNS кеша
    }
  }

  @override
  Future<List<NetworkInterfaceInfo>> getNetworkInterfaces() async {
    // На iOS получить список интерфейсов через публичный API невозможно
    return [];
  }

  @override
  void dispose() {
    if (_currentHandle != null) {
      closeTun(_currentHandle!);
    }
    _currentHandle = null;
  }
}

