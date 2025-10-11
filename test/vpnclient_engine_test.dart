import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/vpnclient_engine.dart';

void main() {
  group('VpnClientEngine', () {
    late VpnClientEngine engine;

    setUp(() {
      engine = VpnClientEngine.instance;
    });

    test('should be singleton', () {
      final engine1 = VpnClientEngine.instance;
      final engine2 = VpnClientEngine.instance;
      expect(engine1, same(engine2));
    });

    test('should initialize with valid config', () async {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
        driver: DriverConfig(type: DriverType.hevSocks5),
      );

      final result = await engine.initialize(config);
      expect(result, isTrue);
    });

    test('should not connect without initialization', () async {
      // Create new engine for clean state
      final testEngine = VpnClientEngine.instance;
      final result = await testEngine.connect();

      // Should fail because not initialized
      expect(result, isFalse);
    });

    test('should connect after initialization', () async {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
        driver: DriverConfig(type: DriverType.hevSocks5),
      );

      await engine.initialize(config);
      final result = await engine.connect();

      expect(result, isTrue);
      expect(engine.status, ConnectionStatus.connected);

      await engine.disconnect();
    });

    test('should disconnect successfully', () async {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
      );

      await engine.initialize(config);
      await engine.connect();

      expect(engine.status, ConnectionStatus.connected);

      await engine.disconnect();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(engine.status, ConnectionStatus.disconnected);
    });

    test('should update stats', () async {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
      );

      await engine.initialize(config);
      await engine.connect();

      // Wait for stats to accumulate
      await Future.delayed(const Duration(seconds: 2));
      await engine.updateStats();

      final stats = engine.stats;
      expect(stats.totalBytes, greaterThan(0));

      await engine.disconnect();
    });

    test('should emit status changes via stream', () async {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
      );

      final statuses = <ConnectionStatus>[];
      final subscription = engine.statusStream.listen(statuses.add);

      await engine.initialize(config);
      await engine.connect();
      await engine.disconnect();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(statuses, contains(ConnectionStatus.connecting));
      expect(statuses, contains(ConnectionStatus.connected));
      expect(statuses, contains(ConnectionStatus.disconnecting));

      await subscription.cancel();
    });

    test('should call status callback', () async {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
      );

      final statuses = <ConnectionStatus>[];
      engine.setStatusCallback(statuses.add);

      await engine.initialize(config);
      await engine.connect();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(statuses, contains(ConnectionStatus.connecting));
      expect(statuses, contains(ConnectionStatus.connected));

      await engine.disconnect();
    });

    test('should call log callback', () async {
      final logs = <Map<String, String>>[];
      engine.setLogCallback((level, message) {
        logs.add({'level': level, 'message': message});
      });

      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
        ),
      );

      await engine.initialize(config);
      await engine.connect();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(logs, isNotEmpty);
      expect(logs.any((log) => log['level'] == 'INFO'), isTrue);

      await engine.disconnect();
    });
  });

  group('CoreType', () {
    test('should convert to native string correctly', () {
      expect(CoreType.singbox.toNativeString(), 'SINGBOX');
      expect(CoreType.libxray.toNativeString(), 'LIBXRAY');
      expect(CoreType.v2ray.toNativeString(), 'V2RAY');
      expect(CoreType.wireguard.toNativeString(), 'WIREGUARD');
    });

    test('should create from string correctly', () {
      expect(CoreType.fromString('SINGBOX'), CoreType.singbox);
      expect(CoreType.fromString('LIBXRAY'), CoreType.libxray);
      expect(CoreType.fromString('V2RAY'), CoreType.v2ray);
      expect(CoreType.fromString('WIREGUARD'), CoreType.wireguard);
    });
  });

  group('DriverType', () {
    test('should convert to native string correctly', () {
      expect(DriverType.none.toNativeString(), 'NONE');
      expect(DriverType.hevSocks5.toNativeString(), 'HEV_SOCKS5');
      expect(DriverType.tun2socks.toNativeString(), 'TUN2SOCKS');
    });

    test('should create from string correctly', () {
      expect(DriverType.fromString('NONE'), DriverType.none);
      expect(DriverType.fromString('HEV_SOCKS5'), DriverType.hevSocks5);
      expect(DriverType.fromString('TUN2SOCKS'), DriverType.tun2socks);
    });
  });

  group('ConnectionStats', () {
    test('should format bytes correctly', () {
      const stats1 = ConnectionStats(bytesSent: 512, bytesReceived: 256);
      expect(stats1.formattedBytesSent, '512 B');
      expect(stats1.formattedBytesReceived, '256 B');

      const stats2 = ConnectionStats(bytesSent: 2048, bytesReceived: 1024);
      expect(stats2.formattedBytesSent, '2.00 KB');
      expect(stats2.formattedBytesReceived, '1.00 KB');

      const stats3 = ConnectionStats(
        bytesSent: 2097152,
        bytesReceived: 1048576,
      );
      expect(stats3.formattedBytesSent, '2.00 MB');
      expect(stats3.formattedBytesReceived, '1.00 MB');

      const stats4 = ConnectionStats(
        bytesSent: 2147483648,
        bytesReceived: 1073741824,
      );
      expect(stats4.formattedBytesSent, '2.00 GB');
      expect(stats4.formattedBytesReceived, '1.00 GB');
    });

    test('should calculate totals correctly', () {
      const stats = ConnectionStats(
        bytesSent: 1000,
        bytesReceived: 2000,
        packetsSent: 10,
        packetsReceived: 20,
      );

      expect(stats.totalBytes, 3000);
    });
  });

  group('Config', () {
    test('should serialize and deserialize correctly', () {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.singbox,
          configJson: '{"test": "config"}',
          serverAddress: 'test.example.com',
          serverPort: 443,
          protocol: 'vless',
        ),
        driver: DriverConfig(
          type: DriverType.hevSocks5,
          mtu: 1400,
          tunAddress: '10.0.0.10',
        ),
      );

      final map = config.toMap();
      final restored = VpnEngineConfig.fromMap(map);

      expect(restored.core.type, config.core.type);
      expect(restored.core.serverAddress, config.core.serverAddress);
      expect(restored.core.serverPort, config.core.serverPort);
      expect(restored.driver.type, config.driver.type);
      expect(restored.driver.mtu, config.driver.mtu);
      expect(restored.driver.tunAddress, config.driver.tunAddress);
    });
  });
}




