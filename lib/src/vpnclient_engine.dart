import 'dart:async';
import 'package:flutter/services.dart';
import 'models/config.dart';
import 'models/connection_status.dart';
import 'models/connection_stats.dart';

/// Callback для логов
typedef LogCallback = void Function(String level, String message);

/// Callback для статуса соединения
typedef StatusCallback = void Function(ConnectionStatus status);

/// Callback для статистики
typedef StatsCallback = void Function(ConnectionStats stats);

/// Основной класс VPN Client Engine
/// Предоставляет единый интерфейс для работы с различными VPN ядрами и драйверами
class VpnClientEngine {
  static const MethodChannel _channel = MethodChannel('vpnclient_engine');

  static VpnClientEngine? _instance;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStats _stats = const ConnectionStats();

  LogCallback? _logCallback;
  StatusCallback? _statusCallback;
  StatsCallback? _statsCallback;

  VpnEngineConfig? _config;

  StreamController<ConnectionStatus>? _statusStreamController;
  StreamController<ConnectionStats>? _statsStreamController;
  StreamController<Map<String, String>>? _logStreamController;

  VpnClientEngine._() {
    _setupMethodCallHandler();
  }

  /// Получить экземпляр движка (синглтон)
  static VpnClientEngine get instance {
    _instance ??= VpnClientEngine._();
    return _instance!;
  }

  /// Инициализация с конфигурацией
  Future<bool> initialize(VpnEngineConfig config) async {
    _config = config;
    try {
      final result = await _channel.invokeMethod<bool>(
        'initialize',
        config.toMap(),
      );
      return result ?? false;
    } catch (e) {
      _log('ERROR', 'Failed to initialize: $e');
      return false;
    }
  }

  /// Подключиться к VPN
  Future<bool> connect() async {
    if (_config == null) {
      _log('ERROR', 'Engine not initialized. Call initialize() first.');
      return false;
    }

    try {
      _updateStatus(ConnectionStatus.connecting);
      final result = await _channel.invokeMethod<bool>('connect');
      if (result == true) {
        _updateStatus(ConnectionStatus.connected);
      } else {
        _updateStatus(ConnectionStatus.error);
      }
      return result ?? false;
    } catch (e) {
      _log('ERROR', 'Failed to connect: $e');
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  /// Отключиться от VPN
  Future<void> disconnect() async {
    try {
      _updateStatus(ConnectionStatus.disconnecting);
      await _channel.invokeMethod('disconnect');
      _updateStatus(ConnectionStatus.disconnected);
    } catch (e) {
      _log('ERROR', 'Failed to disconnect: $e');
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  /// Получить текущий статус
  ConnectionStatus get status => _status;

  /// Получить текущую статистику
  ConnectionStats get stats => _stats;

  /// Stream статусов соединения
  Stream<ConnectionStatus> get statusStream {
    _statusStreamController ??= StreamController<ConnectionStatus>.broadcast();
    return _statusStreamController!.stream;
  }

  /// Stream статистики
  Stream<ConnectionStats> get statsStream {
    _statsStreamController ??= StreamController<ConnectionStats>.broadcast();
    return _statsStreamController!.stream;
  }

  /// Stream логов
  Stream<Map<String, String>> get logStream {
    _logStreamController ??= StreamController<Map<String, String>>.broadcast();
    return _logStreamController!.stream;
  }

  /// Установить callback для логов
  void setLogCallback(LogCallback callback) {
    _logCallback = callback;
  }

  /// Установить callback для статуса
  void setStatusCallback(StatusCallback callback) {
    _statusCallback = callback;
  }

  /// Установить callback для статистики
  void setStatsCallback(StatsCallback callback) {
    _statsCallback = callback;
  }

  /// Получить имя ядра
  Future<String> getCoreName() async {
    try {
      final result = await _channel.invokeMethod<String>('getCoreName');
      return result ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Получить версию ядра
  Future<String> getCoreVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getCoreVersion');
      return result ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Получить имя драйвера
  Future<String> getDriverName() async {
    try {
      final result = await _channel.invokeMethod<String>('getDriverName');
      return result ?? 'None';
    } catch (e) {
      return 'None';
    }
  }

  /// Протестировать соединение
  Future<bool> testConnection() async {
    try {
      final result = await _channel.invokeMethod<bool>('testConnection');
      return result ?? false;
    } catch (e) {
      _log('ERROR', 'Failed to test connection: $e');
      return false;
    }
  }

  /// Обновить статистику
  Future<void> updateStats() async {
    try {
      final result = await _channel.invokeMethod<Map>('getStats');
      if (result != null) {
        _stats = ConnectionStats.fromMap(Map<String, dynamic>.from(result));
        _statsCallback?.call(_stats);
        _statsStreamController?.add(_stats);
      }
    } catch (e) {
      _log('ERROR', 'Failed to get stats: $e');
    }
  }

  /// Освободить ресурсы
  Future<void> dispose() async {
    await disconnect();
    await _statusStreamController?.close();
    await _statsStreamController?.close();
    await _logStreamController?.close();
    _statusStreamController = null;
    _statsStreamController = null;
    _logStreamController = null;
  }

  // Приватные методы

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStatusChanged':
          final status = ConnectionStatus.fromString(call.arguments as String);
          _updateStatus(status);
          break;
        case 'onStatsUpdated':
          final stats = ConnectionStats.fromMap(
            Map<String, dynamic>.from(call.arguments as Map),
          );
          _stats = stats;
          _statsCallback?.call(stats);
          _statsStreamController?.add(stats);
          break;
        case 'onLog':
          final data = Map<String, dynamic>.from(call.arguments as Map);
          final level = data['level'] as String;
          final message = data['message'] as String;
          _log(level, message);
          break;
      }
    });
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _statusCallback?.call(status);
    _statusStreamController?.add(status);
  }

  void _log(String level, String message) {
    _logCallback?.call(level, message);
    _logStreamController?.add({'level': level, 'message': message});
  }
}
