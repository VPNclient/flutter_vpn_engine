import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/core/engine_manager.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';
import 'package:vpnclient_engine/src/drivers/driver_type.dart';

void main() {
  test('requiresDriver/isCompatible/getRecommendedDriver unchanged after trimming', () {
    expect(EngineManager.requiresDriver(CoreType.singbox), isFalse);
    expect(EngineManager.requiresDriver(CoreType.wireguard), isFalse);
    expect(EngineManager.requiresDriver(CoreType.libxray), isTrue);
    expect(EngineManager.requiresDriver(CoreType.v2ray), isTrue);

    expect(EngineManager.getRecommendedDriver(CoreType.singbox), isNull);
    expect(EngineManager.getRecommendedDriver(CoreType.libxray), DriverType.hevSocks5);

    expect(EngineManager.isCompatible(CoreType.singbox, DriverType.none), isTrue);
    expect(EngineManager.isCompatible(CoreType.libxray, DriverType.hevSocks5), isTrue);
    expect(EngineManager.isCompatible(CoreType.libxray, DriverType.none), isFalse);
  });
}
