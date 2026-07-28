import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/core/engine_manager.dart';
import 'package:vpnclient_engine/src/models/core_type.dart';
import 'package:vpnclient_engine/src/models/driver_type.dart';
import 'package:vpnclient_engine/src/models/tun_options.dart';

void main() {
  group('EngineManager.requiresDriver', () {
    test('SingBox should NOT require driver (built-in TUN)', () {
      expect(EngineManager.requiresDriver(CoreType.singbox), isFalse);
    });

    test('WireGuard should NOT require driver (built-in TUN via wireguard-go)', () {
      expect(EngineManager.requiresDriver(CoreType.wireguard), isFalse);
    });

    test('LibXray should require driver (SOCKS only)', () {
      expect(EngineManager.requiresDriver(CoreType.libxray), isTrue);
    });

    test('V2Ray should require driver (SOCKS only)', () {
      expect(EngineManager.requiresDriver(CoreType.v2ray), isTrue);
    });

    test('should cover all CoreType values', () {
      // Ensure all enum values are tested
      for (final core in CoreType.values) {
        // Should not throw
        final result = EngineManager.requiresDriver(core);
        expect(result, isA<bool>());
      }
    });
  });

  group('EngineManager.getRecommendedDriver', () {
    test('should return HevSocks5 for LibXray', () {
      expect(
        EngineManager.getRecommendedDriver(CoreType.libxray),
        DriverType.hevSocks5,
      );
    });

    test('should return HevSocks5 for V2Ray', () {
      expect(
        EngineManager.getRecommendedDriver(CoreType.v2ray),
        DriverType.hevSocks5,
      );
    });

    test('should return null for SingBox (no driver needed)', () {
      expect(
        EngineManager.getRecommendedDriver(CoreType.singbox),
        isNull,
      );
    });

    test('should return null for WireGuard (no driver needed)', () {
      expect(
        EngineManager.getRecommendedDriver(CoreType.wireguard),
        isNull,
      );
    });
  });

  group('EngineManager.isCompatible', () {
    group('valid combinations', () {
      test('SingBox + none should be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.singbox, DriverType.none),
          isTrue,
        );
      });

      test('WireGuard + none should be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.wireguard, DriverType.none),
          isTrue,
        );
      });

      test('LibXray + HevSocks5 should be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.libxray, DriverType.hevSocks5),
          isTrue,
        );
      });

      test('LibXray + Tun2Socks should be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.libxray, DriverType.tun2socks),
          isTrue,
        );
      });

      test('V2Ray + HevSocks5 should be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.v2ray, DriverType.hevSocks5),
          isTrue,
        );
      });

      test('V2Ray + Tun2Socks should be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.v2ray, DriverType.tun2socks),
          isTrue,
        );
      });
    });

    group('invalid combinations', () {
      test('SingBox + HevSocks5 should NOT be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.singbox, DriverType.hevSocks5),
          isFalse,
        );
      });

      test('SingBox + Tun2Socks should NOT be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.singbox, DriverType.tun2socks),
          isFalse,
        );
      });

      test('WireGuard + HevSocks5 should NOT be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.wireguard, DriverType.hevSocks5),
          isFalse,
        );
      });

      test('LibXray + none should NOT be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.libxray, DriverType.none),
          isFalse,
        );
      });

      test('V2Ray + none should NOT be compatible', () {
        expect(
          EngineManager.isCompatible(CoreType.v2ray, DriverType.none),
          isFalse,
        );
      });
    });
  });

  group('EngineManager.createOptimalConfig', () {
    const testConfigJson = '{"test": "config"}';

    group('for cores without driver requirement', () {
      test('SingBox should create config with DriverType.none', () {
        final config = EngineManager.createOptimalConfig(
          core: CoreType.singbox,
          configJson: testConfigJson,
        );

        expect(config.core.type, CoreType.singbox);
        expect(config.core.configJson, testConfigJson);
        expect(config.driver.type, DriverType.none);
      });

      test('WireGuard should create config with DriverType.none', () {
        final config = EngineManager.createOptimalConfig(
          core: CoreType.wireguard,
          configJson: testConfigJson,
        );

        expect(config.core.type, CoreType.wireguard);
        expect(config.driver.type, DriverType.none);
      });
    });

    group('for cores requiring driver', () {
      test('LibXray should auto-select HevSocks5 driver', () {
        final config = EngineManager.createOptimalConfig(
          core: CoreType.libxray,
          configJson: testConfigJson,
        );

        expect(config.core.type, CoreType.libxray);
        expect(config.driver.type, DriverType.hevSocks5);
      });

      test('V2Ray should auto-select HevSocks5 driver', () {
        final config = EngineManager.createOptimalConfig(
          core: CoreType.v2ray,
          configJson: testConfigJson,
        );

        expect(config.core.type, CoreType.v2ray);
        expect(config.driver.type, DriverType.hevSocks5);
      });
    });

    group('with explicit driver', () {
      test('should use explicitly specified driver for cores that need it', () {
        final config = EngineManager.createOptimalConfig(
          core: CoreType.libxray,
          configJson: testConfigJson,
          explicitDriver: DriverType.tun2socks,
        );

        expect(config.driver.type, DriverType.tun2socks);
      });

      test('should ignore DriverType.none for cores that need driver', () {
        final config = EngineManager.createOptimalConfig(
          core: CoreType.libxray,
          configJson: testConfigJson,
          explicitDriver: DriverType.none,
        );

        // Should fall back to default HevSocks5
        expect(config.driver.type, DriverType.hevSocks5);
      });
    });

    group('with TunOptions', () {
      test('should apply TunOptions to driver config', () {
        const tunOptions = TunOptions(
          mtu: 1400,
          tunName: 'utun99',
          ipv4Address: '10.10.10.2',
          ipv4Gateway: '10.10.10.1',
          ipv4Netmask: '255.255.255.252',
          dnsServer: '1.1.1.1',
        );

        final config = EngineManager.createOptimalConfig(
          core: CoreType.libxray,
          configJson: testConfigJson,
          tunOptions: tunOptions,
        );

        expect(config.driver.mtu, 1400);
        expect(config.driver.tunName, 'utun99');
        expect(config.driver.tunAddress, '10.10.10.2');
        expect(config.driver.tunGateway, '10.10.10.1');
        expect(config.driver.tunNetmask, '255.255.255.252');
        expect(config.driver.dnsServer, '1.1.1.1');
      });

      test('should use defaults for null TunOptions fields', () {
        const tunOptions = TunOptions(
          mtu: 1400,
          // Other fields null
        );

        final config = EngineManager.createOptimalConfig(
          core: CoreType.v2ray,
          configJson: testConfigJson,
          tunOptions: tunOptions,
        );

        expect(config.driver.mtu, 1400);
        expect(config.driver.tunAddress, '10.0.0.2');
        expect(config.driver.tunGateway, '10.0.0.1');
        expect(config.driver.tunNetmask, '255.255.255.0');
        expect(config.driver.dnsServer, '8.8.8.8');
      });

      test('should ignore TunOptions for cores that do not need driver', () {
        const tunOptions = TunOptions(
          mtu: 1400,
          ipv4Address: '10.10.10.2',
        );

        final config = EngineManager.createOptimalConfig(
          core: CoreType.singbox,
          configJson: testConfigJson,
          tunOptions: tunOptions,
        );

        // Driver should be none, TunOptions ignored
        expect(config.driver.type, DriverType.none);
      });
    });

    test('should preserve configJson in core config', () {
      const complexConfig = '{"inbounds":[{"port":1080}],"outbounds":[]}';

      final config = EngineManager.createOptimalConfig(
        core: CoreType.singbox,
        configJson: complexConfig,
      );

      expect(config.core.configJson, complexConfig);
    });
  });

  group('Core/Driver Matrix (ADR-002)', () {
    // Document the expected behavior as a reference test
    test('matrix should match documented behavior', () {
      // From ADR-002: Core/Driver Requirement Matrix
      final matrix = {
        CoreType.singbox: {'requiresDriver': false, 'reason': 'Built-in TUN'},
        CoreType.libxray: {'requiresDriver': true, 'reason': 'SOCKS only'},
        CoreType.v2ray: {'requiresDriver': true, 'reason': 'SOCKS only'},
        CoreType.wireguard: {'requiresDriver': false, 'reason': 'wireguard-go TUN'},
      };

      for (final entry in matrix.entries) {
        final core = entry.key;
        final expected = entry.value['requiresDriver'] as bool;

        expect(
          EngineManager.requiresDriver(core),
          expected,
          reason: '${core.name}: ${entry.value['reason']}',
        );
      }
    });
  });
}
