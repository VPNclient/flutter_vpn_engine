// Archived from `core/engine_config.dart` — used only by the now-archived
// `VpnClientEngineV2`. Moved verbatim (import paths updated only), not deleted.

import '../cores/core_type.dart';
import '../drivers/driver_type.dart';
import 'tun_options.dart';
import '../models/config.dart';
import '../core/engine_manager.dart';
import 'engine_manager_v2_extras.dart' as v2_extras;

/// Конфигурация движка с учетом необходимости драйверов
class EngineConfig {
  final CoreType coreType;
  final String configJson;
  final TunOptions? tunOptions;
  final bool useNativeTun; // true для SingBox (встроенный TUN)
  final DriverType? driverType; // null если не нужен драйвер

  const EngineConfig({
    required this.coreType,
    required this.configJson,
    this.tunOptions,
    required this.useNativeTun,
    this.driverType,
  });

  /// Создание из VpnEngineConfig с автоматической оптимизацией
  factory EngineConfig.fromVpnEngineConfig(
    VpnEngineConfig config, {
    TunOptions? tunOptions,
  }) {
    final needsDriver = EngineManager.requiresDriver(config.core.type);

    return EngineConfig(
      coreType: config.core.type,
      configJson: config.core.configJson,
      tunOptions: tunOptions ?? TunOptions.fromDriverConfig(config.driver),
      useNativeTun: !needsDriver,
      driverType: needsDriver ? config.driver.type : null,
    );
  }

  /// Преобразование в VpnEngineConfig (для обратной совместимости)
  VpnEngineConfig toVpnEngineConfig() {
    return v2_extras.createOptimalConfig(
      core: coreType,
      configJson: configJson,
      tunOptions: tunOptions,
      explicitDriver: driverType,
    );
  }
}
