import '../cores/core_type.dart';
import '../drivers/driver_type.dart';

/// Управление движками VPN
/// Определяет оптимальную конфигурацию для каждого типа ядра
///
/// Trimmed to the real, portable subset — `createOptimalConfig` (V2/`TunOptions`-only)
/// moved to `lib/src/legacy_v2/engine_manager_v2_extras.dart`.
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
