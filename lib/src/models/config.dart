import 'core_type.dart';
import 'driver_type.dart';

/// Конфигурация ядра VPN
class CoreConfig {
  /// Тип ядра
  final CoreType type;

  /// JSON конфигурация
  final String configJson;

  /// Адрес сервера
  final String? serverAddress;

  /// Порт сервера
  final int? serverPort;

  /// Протокол (vless, vmess, shadowsocks, etc.)
  final String? protocol;

  /// Уровень логирования
  final String logLevel;

  /// Включить логирование
  final bool enableLogging;

  const CoreConfig({
    required this.type,
    required this.configJson,
    this.serverAddress,
    this.serverPort,
    this.protocol,
    this.logLevel = 'info',
    this.enableLogging = true,
  });

  /// Создание из Map
  factory CoreConfig.fromMap(Map<String, dynamic> map) {
    return CoreConfig(
      type: CoreType.fromString(map['type'] as String),
      configJson: map['configJson'] as String,
      serverAddress: map['serverAddress'] as String?,
      serverPort: map['serverPort'] as int?,
      protocol: map['protocol'] as String?,
      logLevel: map['logLevel'] as String? ?? 'info',
      enableLogging: map['enableLogging'] as bool? ?? true,
    );
  }

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.toNativeString(),
      'configJson': configJson,
      'serverAddress': serverAddress,
      'serverPort': serverPort,
      'protocol': protocol,
      'logLevel': logLevel,
      'enableLogging': enableLogging,
    };
  }
}

/// Конфигурация драйвера туннелирования
class DriverConfig {
  /// Тип драйвера
  final DriverType type;

  /// JSON конфигурация
  final String configJson;

  /// MTU (Maximum Transmission Unit)
  final int mtu;

  /// Имя TUN устройства
  final String tunName;

  /// IP адрес TUN устройства
  final String tunAddress;

  /// Шлюз TUN устройства
  final String tunGateway;

  /// Маска сети TUN устройства
  final String tunNetmask;

  /// DNS сервер
  final String dnsServer;

  /// Уровень логирования
  final String logLevel;

  /// Включить логирование
  final bool enableLogging;

  const DriverConfig({
    this.type = DriverType.none,
    this.configJson = '{}',
    this.mtu = 1500,
    this.tunName = 'tun0',
    this.tunAddress = '10.0.0.2',
    this.tunGateway = '10.0.0.1',
    this.tunNetmask = '255.255.255.0',
    this.dnsServer = '8.8.8.8',
    this.logLevel = 'info',
    this.enableLogging = true,
  });

  /// Создание из Map
  factory DriverConfig.fromMap(Map<String, dynamic> map) {
    return DriverConfig(
      type: DriverType.fromString(map['type'] as String),
      configJson: map['configJson'] as String? ?? '{}',
      mtu: map['mtu'] as int? ?? 1500,
      tunName: map['tunName'] as String? ?? 'tun0',
      tunAddress: map['tunAddress'] as String? ?? '10.0.0.2',
      tunGateway: map['tunGateway'] as String? ?? '10.0.0.1',
      tunNetmask: map['tunNetmask'] as String? ?? '255.255.255.0',
      dnsServer: map['dnsServer'] as String? ?? '8.8.8.8',
      logLevel: map['logLevel'] as String? ?? 'info',
      enableLogging: map['enableLogging'] as bool? ?? true,
    );
  }

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.toNativeString(),
      'configJson': configJson,
      'mtu': mtu,
      'tunName': tunName,
      'tunAddress': tunAddress,
      'tunGateway': tunGateway,
      'tunNetmask': tunNetmask,
      'dnsServer': dnsServer,
      'logLevel': logLevel,
      'enableLogging': enableLogging,
    };
  }
}

/// Общая конфигурация VPN Engine
class VpnEngineConfig {
  /// Конфигурация ядра
  final CoreConfig core;

  /// Конфигурация драйвера
  final DriverConfig driver;

  /// Автоматическое подключение
  final bool autoConnect;

  /// Таймаут подключения (секунды)
  final int connectionTimeout;

  const VpnEngineConfig({
    required this.core,
    this.driver = const DriverConfig(),
    this.autoConnect = false,
    this.connectionTimeout = 30,
  });

  /// Создание из Map
  factory VpnEngineConfig.fromMap(Map<String, dynamic> map) {
    return VpnEngineConfig(
      core: CoreConfig.fromMap(map['core'] as Map<String, dynamic>),
      driver: map['driver'] != null
          ? DriverConfig.fromMap(map['driver'] as Map<String, dynamic>)
          : const DriverConfig(),
      autoConnect: map['autoConnect'] as bool? ?? false,
      connectionTimeout: map['connectionTimeout'] as int? ?? 30,
    );
  }

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'core': core.toMap(),
      'driver': driver.toMap(),
      'autoConnect': autoConnect,
      'connectionTimeout': connectionTimeout,
    };
  }
}




