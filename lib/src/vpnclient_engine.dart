import 'dart:async';
import 'package:flutter/services.dart';
import 'models/config.dart';
import 'models/connection_status.dart';
import 'models/connection_stats.dart';
import 'platform/vpn_engine_platform.dart';

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

  // Platform layer
  late final VpnEnginePlatform _platform;

  VpnClientEngine._() {
    _platform = VpnEnginePlatform();
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
      final result = _platform.initialize(config);
      if (result) {
        _log('INFO', 'VPN Engine initialized successfully');
        _log('INFO', 'Core: ${config.core.type.name}');
        _log('INFO', 'Driver: ${config.driver.type.name}');
      }
      return result;
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
      _log('INFO', 'Connecting to VPN...');

      final result = await _platform.connect();

      if (result) {
        _updateStatus(ConnectionStatus.connected);
        _log('INFO', 'Successfully connected to VPN');
        _startStatsPolling();
      } else {
        _updateStatus(ConnectionStatus.error);
        _log('ERROR', 'Failed to connect to VPN');
      }
      return result;
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
      _log('INFO', 'Disconnecting from VPN...');

      _platform.disconnect();

      _updateStatus(ConnectionStatus.disconnected);
      _log('INFO', 'Disconnected from VPN');
      _stopStatsPolling();
    } catch (e) {
      _log('ERROR', 'Failed to disconnect: $e');
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  Timer? _statsTimer;

  void _startStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await updateStats();
    });
  }

  void _stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
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
      _stats = _platform.getStats();
      _statsCallback?.call(_stats);
      _statsStreamController?.add(_stats);
    } catch (e) {
      _log('ERROR', 'Failed to get stats: $e');
    }
  }

  /// Освободить ресурсы
  Future<void> dispose() async {
    await disconnect();
    _stopStatsPolling();
    await _statusStreamController?.close();
    await _statsStreamController?.close();
    await _logStreamController?.close();
    _statusStreamController = null;
    _statsStreamController = null;
    _logStreamController = null;
    _platform.dispose();
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
