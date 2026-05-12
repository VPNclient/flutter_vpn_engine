import 'dart:async';
import 'package:flutter/services.dart';
import 'unified_platform_interface.dart';
import '../models/tun_options.dart';
import '../models/platform_tun_handle.dart';

/// Android реализация Unified Platform Interface
/// Использует Android VPN API через MethodChannel
class AndroidPlatformInterface implements UnifiedPlatformInterface {
  static const MethodChannel _channel = MethodChannel('vpnclient_engine');

  PlatformTunHandle? _currentHandle;

  @override
  Future<PlatformTunHandle> openTun(TunOptions options) async {
    try {
      final result = await _channel.invokeMethod<int>('openTun', options.toMap());
      
      if (result == null || result < 0) {
        throw PlatformException(
          code: 'TUN_OPEN_FAILED',
          message: 'Failed to open TUN interface on Android',
        );
      }

      _currentHandle = AndroidTunHandle(result);
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
    try {
      final result = await _channel.invokeMethod<bool>('checkPrivileges');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> setupPerAppProxy({
    required List<String> packages,
    required String mode,
  }) async {
    try {
      await _channel.invokeMethod('setupPerAppProxy', {
        'packages': packages,
        'mode': mode, // 'include' or 'exclude'
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to setup per-app proxy: ${e.message}');
    }
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
    try {
      final result = await _channel.invokeMethod<List>('getNetworkInterfaces');
      if (result == null) return [];

      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return NetworkInterfaceInfo(
          name: map['name'] as String,
          address: map['address'] as String,
          index: map['index'] as int,
          mtu: map['mtu'] as int? ?? 1500,
          isUp: map['isUp'] as bool? ?? false,
        );
      }).toList();
    } on PlatformException {
      return [];
    }
  }

  @override
  void dispose() {
    if (_currentHandle != null) {
      closeTun(_currentHandle!);
    }
    _currentHandle = null;
  }
}

