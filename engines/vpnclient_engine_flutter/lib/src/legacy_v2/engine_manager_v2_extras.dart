// Archived from `core/engine_manager.dart` — `EngineManager.createOptimalConfig` and
// its `TunOptions`-based helper, used only by the now-archived `VpnClientEngineV2`.
// Moved verbatim (not deleted), per the "moving, not deleting" policy in
// flows/sdd-flutter-vpnclient-engine/. Not part of the public API.

import '../core/engine_manager.dart';
import '../cores/core_type.dart';
import '../drivers/driver_type.dart';
import '../models/config.dart';
import 'tun_options.dart';

/// Создает оптимальную конфигурацию для указанного ядра
///
/// Автоматически определяет необходимость драйвера и создает
/// оптимальную конфигурацию
VpnEngineConfig createOptimalConfig({
  required CoreType core,
  required String configJson,
  TunOptions? tunOptions,
  DriverType? explicitDriver,
}) {
  final needsDriver = EngineManager.requiresDriver(core);

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
DriverConfig _createDriverConfigFromTunOptions(
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
