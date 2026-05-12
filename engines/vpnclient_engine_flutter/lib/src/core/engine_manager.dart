import '../models/core_type.dart';
import '../models/driver_type.dart';
import '../models/config.dart';
import '../models/tun_options.dart';

/// Управление движками VPN
/// Определяет оптимальную конфигурацию для каждого типа ядра
class EngineManager {
  /// Определяет, требуется ли драйвер для указанного ядра
  /// 
  /// SingBox имеет встроенную поддержку TUN и не требует внешних драйверов
  /// LibXray и V2Ray требуют SOCKS драйвер для работы с TUN
  static bool requiresDriver(CoreType core) {
    switch (core) {
      case CoreType.singbox:
        return false; // SingBox имеет встроенный TUN
      case CoreType.libxray:
      case CoreType.v2ray:
        return true; // Требуют SOCKS драйвер
      case CoreType.wireguard:
        return false; // WireGuard имеет встроенный TUN (через wireguard-go)
    }
  }

  /// Создает оптимальную конфигурацию для указанного ядра
  /// 
  /// Автоматически определяет необходимость драйвера и создает
  /// оптимальную конфигурацию
  static VpnEngineConfig createOptimalConfig({
    required CoreType core,
    required String configJson,
    TunOptions? tunOptions,
    DriverType? explicitDriver,
  }) {
    final needsDriver = requiresDriver(core);

    // Если явно указан драйвер, используем его
    // Иначе используем оптимальный по умолчанию
    DriverType driverType;
    if (explicitDriver != null && explicitDriver != DriverType.none) {
      driverType = explicitDriver;
    } else if (needsDriver) {
      driverType = DriverType.hevSocks5; // Используем hev-socks5 по умолчанию
    } else {
      driverType = DriverType.none;
    }

    // Создаем DriverConfig из TunOptions если нужно
    final driverConfig = _createDriverConfigFromTunOptions(
      tunOptions,
      driverType,
      needsDriver,
    );

    return VpnEngineConfig(
      core: CoreConfig(
        type: core,
        configJson: configJson,
      ),
      driver: driverConfig,
    );
  }

  /// Создает DriverConfig из TunOptions
  static DriverConfig _createDriverConfigFromTunOptions(
    TunOptions? tunOptions,
    DriverType driverType,
    bool needsDriver,
  ) {
    if (!needsDriver || driverType == DriverType.none) {
      return const DriverConfig(type: DriverType.none);
    }

    if (tunOptions == null) {
      return DriverConfig(type: driverType);
    }

    return DriverConfig(
      type: driverType,
      mtu: tunOptions.mtu,
      tunName: tunOptions.tunName,
      tunAddress: tunOptions.ipv4Address ?? '10.0.0.2',
      tunGateway: tunOptions.ipv4Gateway ?? '10.0.0.1',
      tunNetmask: tunOptions.ipv4Netmask ?? '255.255.255.0',
      dnsServer: tunOptions.dnsServer ?? '8.8.8.8',
    );
  }

  /// Получить рекомендуемый драйвер для ядра
  static DriverType? getRecommendedDriver(CoreType core) {
    if (requiresDriver(core)) {
      return DriverType.hevSocks5; // Рекомендуем hev-socks5
    }
    return null; // Драйвер не нужен
  }

  /// Проверить совместимость ядра и драйвера
  static bool isCompatible(CoreType core, DriverType driver) {
    if (driver == DriverType.none) {
      return !requiresDriver(core); // None драйвер только для ядер без необходимости драйвера
    }
    return requiresDriver(core); // SOCKS драйверы только для ядер, которые их требуют
  }
}

