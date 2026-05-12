import 'dart:async';
import 'package:flutter/services.dart';
import 'models/config.dart';
import 'models/connection_status.dart';
import 'models/connection_stats.dart';
import 'models/tun_options.dart';
import 'core/engine_manager.dart';
import 'core/engine_config.dart';
import 'platform/platform_interface_factory.dart';
import 'platform/unified_platform_interface.dart';
import 'subscription_manager.dart';
import 'v2ray_url_parser.dart';

/// Callback для логов
typedef LogCallback = void Function(String level, String message);

/// Callback для статуса соединения
typedef StatusCallback = void Function(ConnectionStatus status);

/// Callback для статистики
typedef StatsCallback = void Function(ConnectionStats stats);

/// Обновленный VPN Client Engine с поддержкой Unified Platform Interface
/// 
/// Автоматически определяет оптимальную конфигурацию:
/// - SingBox: использует встроенный TUN (без драйверов)
/// - LibXray/V2Ray: использует SOCKS драйверы
class VpnClientEngineV2 {
  static const MethodChannel _channel = MethodChannel('vpnclient_engine');

  static VpnClientEngineV2? _instance;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStats _stats = const ConnectionStats();

  LogCallback? _logCallback;
  StatusCallback? _statusCallback;
  StatsCallback? _statsCallback;

  EngineConfig? _engineConfig;
  UnifiedPlatformInterface? _platformInterface;
  PlatformTunHandle? _tunHandle;

  StreamController<ConnectionStatus>? _statusStreamController;
  StreamController<ConnectionStats>? _statsStreamController;
  StreamController<Map<String, String>>? _logStreamController;

  // Subscription manager
  late final SubscriptionManager _subscriptionManager;

  VpnClientEngineV2._() {
    _subscriptionManager = SubscriptionManager();
    _setupMethodCallHandler();
  }

  /// Получить экземпляр движка (синглтон)
  static VpnClientEngineV2 get instance {
    _instance ??= VpnClientEngineV2._();
    return _instance!;
  }

  /// Инициализация с конфигурацией (упрощенная версия)
  /// 
  /// Автоматически определяет оптимальную конфигурацию:
  /// - Если указан CoreType.singbox, драйвер не требуется
  /// - Если указан CoreType.libxray или CoreType.v2ray, используется драйвер
  Future<bool> initialize({
    required CoreType coreType,
    required String configJson,
    TunOptions? tunOptions,
    DriverType? explicitDriver, // Явное указание драйвера (опционально)
  }) async {
    try {
      // Создаем оптимальную конфигурацию
      _engineConfig = EngineConfig(
        coreType: coreType,
        configJson: configJson,
        tunOptions: tunOptions,
        useNativeTun: !EngineManager.requiresDriver(coreType),
        driverType: explicitDriver ?? (EngineManager.requiresDriver(coreType) 
            ? DriverType.hevSocks5 
            : null),
      );

      // Создаем Platform Interface для текущей платформы
      _platformInterface = PlatformInterfaceFactory.create();

      _log('INFO', 'VPN Engine initialized successfully');
      _log('INFO', 'Core: ${coreType.name}');
      _log('INFO', 'Using native TUN: ${_engineConfig!.useNativeTun}');
      if (_engineConfig!.driverType != null) {
        _log('INFO', 'Driver: ${_engineConfig!.driverType!.name}');
      } else {
        _log('INFO', 'Driver: None (native TUN)');
      }

      return true;
    } catch (e) {
      _log('ERROR', 'Failed to initialize: $e');
      return false;
    }
  }

  /// Инициализация с VpnEngineConfig (для обратной совместимости)
  Future<bool> initializeWithConfig(VpnEngineConfig config) async {
    final tunOptions = TunOptions.fromDriverConfig(config.driver);
    
    return initialize(
      coreType: config.core.type,
      configJson: config.core.configJson,
      tunOptions: tunOptions,
      explicitDriver: config.driver.type != DriverType.none ? config.driver.type : null,
    );
  }

  /// Подключиться к VPN
  Future<bool> connect() async {
    if (_engineConfig == null || _platformInterface == null) {
      _log('ERROR', 'Engine not initialized. Call initialize() first.');
      return false;
    }

    try {
      _updateStatus(ConnectionStatus.connecting);
      _log('INFO', 'Connecting to VPN...');

      // Проверяем привилегии
      final hasPrivileges = await _platformInterface!.checkPrivileges();
      if (!hasPrivileges) {
        _log('ERROR', 'Missing required privileges for VPN connection');
        _updateStatus(ConnectionStatus.error);
        return false;
      }

      // Открываем TUN интерфейс если нужен
      if (_engineConfig!.tunOptions != null) {
        _tunHandle = await _platformInterface!.openTun(_engineConfig!.tunOptions!);
        _log('INFO', 'TUN interface opened: FD=${_tunHandle!.fileDescriptor}');
      }

      // Настраиваем маршруты если нужно
      if (_engineConfig!.tunOptions?.autoRoute == true) {
        await _platformInterface!.setupRoutes(_engineConfig!.tunOptions!);
        _log('INFO', 'Routes configured');
      }

      // Запускаем движок через нативный код
      final result = await _startNativeEngine();

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

  /// Запуск нативного движка
  Future<bool> _startNativeEngine() async {
    // TODO: Реализовать вызов нативного кода через MethodChannel или FFI
    // Пока возвращаем заглушку
    return true;
  }

  /// Отключиться от VPN
  Future<void> disconnect() async {
    try {
      _updateStatus(ConnectionStatus.disconnecting);
      _log('INFO', 'Disconnecting from VPN...');

      // Закрываем TUN интерфейс
      if (_tunHandle != null && _platformInterface != null) {
        await _platformInterface!.closeTun(_tunHandle!);
        _tunHandle = null;
        _log('INFO', 'TUN interface closed');
      }

      // Останавливаем нативный движок
      await _stopNativeEngine();

      _updateStatus(ConnectionStatus.disconnected);
      _log('INFO', 'Disconnected from VPN');
      _stopStatsPolling();
    } catch (e) {
      _log('ERROR', 'Failed to disconnect: $e');
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  /// Остановка нативного движка
  Future<void> _stopNativeEngine() async {
    // TODO: Реализовать остановку нативного движка
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

  /// Обновить статистику
  Future<void> updateStats() async {
    try {
      // TODO: Получать статистику из нативного кода
      _statsCallback?.call(_stats);
      _statsStreamController?.add(_stats);
    } catch (e) {
      _log('ERROR', 'Failed to get stats: $e');
    }
  }

  // ============ Subscription API ============

  /// Add subscription
  void addSubscription({required String subscriptionURL, String? name}) {
    _subscriptionManager.addSubscription(
      subscriptionURL: subscriptionURL,
      name: name,
    );
  }

  /// Clear all subscriptions
  void clearSubscriptions() {
    _subscriptionManager.clearSubscriptions();
  }

  /// Update subscription
  Future<bool> updateSubscription({required int subscriptionIndex}) {
    return _subscriptionManager.updateSubscription(
      subscriptionIndex: subscriptionIndex,
    );
  }

  /// Ping server
  Future<void> pingServer({
    required int subscriptionIndex,
    required int serverIndex,
    String testUrl = 'https://www.google.com/generate_204',
  }) {
    return _subscriptionManager.pingServer(
      subscriptionIndex: subscriptionIndex,
      serverIndex: serverIndex,
      testUrl: testUrl,
    );
  }

  /// Stream of ping results
  Stream<PingResult> get onPingResult => _subscriptionManager.onPingResult;

  /// Get subscriptions
  List<Subscription> get subscriptions => _subscriptionManager.subscriptions;

  /// Get server from subscription
  ServerConfig? getServer({
    required int subscriptionIndex,
    required int serverIndex,
  }) {
    return _subscriptionManager.getServer(
      subscriptionIndex: subscriptionIndex,
      serverIndex: serverIndex,
    );
  }

  /// Connect to specific server from subscription
  Future<bool> connectToServer({
    required int subscriptionIndex,
    required int serverIndex,
  }) async {
    final server = getServer(
      subscriptionIndex: subscriptionIndex,
      serverIndex: serverIndex,
    );

    if (server == null) {
      _log('ERROR', 'Server not found');
      return false;
    }

    // Parse V2Ray URL
    final v2rayUrl = parseV2RayURL(server.url);
    if (v2rayUrl == null) {
      _log('ERROR', 'Failed to parse server URL');
      return false;
    }

    // Определяем тип ядра из URL
    CoreType coreType = CoreType.singbox; // По умолчанию
    // TODO: Определить тип ядра из конфигурации сервера

    // Initialize with server configuration
    await initialize(
      coreType: coreType,
      configJson: v2rayUrl.getFullConfiguration(),
    );

    return await connect();
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
    _subscriptionManager.dispose();
    _platformInterface?.dispose();
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

// Импорты для типов
import 'models/core_type.dart';
import 'models/driver_type.dart';

// Типы из subscription_manager экспортируются через сам файл subscription_manager.dart
// Subscription, ServerConfig, PingResult определены там

