// Импортируем для обратной совместимости
import 'config.dart';

/// Опции для настройки TUN интерфейса
class TunOptions {
  /// MTU (Maximum Transmission Unit)
  final int mtu;

  /// Имя TUN устройства
  final String tunName;

  /// IPv4 адрес TUN устройства (например, "10.0.0.2")
  final String? ipv4Address;

  /// IPv4 маска сети (например, "255.255.255.0")
  final String? ipv4Netmask;

  /// IPv4 шлюз (например, "10.0.0.1")
  final String? ipv4Gateway;

  /// IPv6 адрес (например, "2001:db8::1")
  final String? ipv6Address;

  /// IPv6 префикс (например, 64)
  final int? ipv6Prefix;

  /// DNS сервер (IPv4)
  final String? dnsServer;

  /// DNS серверы (список)
  final List<String>? dnsServers;

  /// Автоматическая маршрутизация
  final bool autoRoute;

  /// Строгая маршрутизация
  final bool strictRoute;

  /// Включить IPv6
  final bool enableIPv6;

  /// Включить per-app proxy (Android)
  final bool enablePerAppProxy;

  /// Список приложений для включения в per-app proxy (Android)
  final List<String>? includePackages;

  /// Список приложений для исключения из per-app proxy (Android)
  final List<String>? excludePackages;

  const TunOptions({
    this.mtu = 1500,
    this.tunName = 'tun0',
    this.ipv4Address,
    this.ipv4Netmask,
    this.ipv4Gateway,
    this.ipv6Address,
    this.ipv6Prefix,
    this.dnsServer,
    this.dnsServers,
    this.autoRoute = true,
    this.strictRoute = false,
    this.enableIPv6 = false,
    this.enablePerAppProxy = false,
    this.includePackages,
    this.excludePackages,
  });

  /// Создание из DriverConfig (для обратной совместимости)
  factory TunOptions.fromDriverConfig(DriverConfig config) {
    return TunOptions(
      mtu: config.mtu,
      tunName: config.tunName,
      ipv4Address: config.tunAddress,
      ipv4Netmask: config.tunNetmask,
      ipv4Gateway: config.tunGateway,
      dnsServer: config.dnsServer,
      autoRoute: true,
    );
  }

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'mtu': mtu,
      'tunName': tunName,
      'ipv4Address': ipv4Address,
      'ipv4Netmask': ipv4Netmask,
      'ipv4Gateway': ipv4Gateway,
      'ipv6Address': ipv6Address,
      'ipv6Prefix': ipv6Prefix,
      'dnsServer': dnsServer,
      'dnsServers': dnsServers,
      'autoRoute': autoRoute,
      'strictRoute': strictRoute,
      'enableIPv6': enableIPv6,
      'enablePerAppProxy': enablePerAppProxy,
      'includePackages': includePackages,
      'excludePackages': excludePackages,
    };
  }

  /// Создание из Map
  factory TunOptions.fromMap(Map<String, dynamic> map) {
    return TunOptions(
      mtu: map['mtu'] as int? ?? 1500,
      tunName: map['tunName'] as String? ?? 'tun0',
      ipv4Address: map['ipv4Address'] as String?,
      ipv4Netmask: map['ipv4Netmask'] as String?,
      ipv4Gateway: map['ipv4Gateway'] as String?,
      ipv6Address: map['ipv6Address'] as String?,
      ipv6Prefix: map['ipv6Prefix'] as int?,
      dnsServer: map['dnsServer'] as String?,
      dnsServers: map['dnsServers'] != null
          ? List<String>.from(map['dnsServers'] as List)
          : null,
      autoRoute: map['autoRoute'] as bool? ?? true,
      strictRoute: map['strictRoute'] as bool? ?? false,
      enableIPv6: map['enableIPv6'] as bool? ?? false,
      enablePerAppProxy: map['enablePerAppProxy'] as bool? ?? false,
      includePackages: map['includePackages'] != null
          ? List<String>.from(map['includePackages'] as List)
          : null,
      excludePackages: map['excludePackages'] != null
          ? List<String>.from(map['excludePackages'] as List)
          : null,
    );
  }
}

