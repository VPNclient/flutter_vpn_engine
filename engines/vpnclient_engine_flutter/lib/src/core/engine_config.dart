import '../models/core_type.dart';
import '../models/driver_type.dart';
import '../models/tun_options.dart';
import '../models/config.dart';
import 'engine_manager.dart';

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
    return EngineManager.createOptimalConfig(
      core: coreType,
      configJson: configJson,
      tunOptions: tunOptions,
      explicitDriver: driverType,
    );
  }
}

