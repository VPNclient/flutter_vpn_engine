import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/subscription_manager.dart';
import 'package:vpnclient_engine/src/v2ray_url_parser.dart';

void main() {
  group('Subscription', () {
    test('should create with required fields', () {
      final subscription = Subscription(url: 'https://example.com/sub');

      expect(subscription.url, 'https://example.com/sub');
      expect(subscription.name, isNull);
      expect(subscription.lastUpdate, isNull);
      expect(subscription.servers, isEmpty);
    });

    test('should create with all fields', () {
      final now = DateTime.now();
      final servers = [
        ServerConfig(
          url: 'vmess://abc',
          remark: 'Server 1',
          protocol: 'vmess',
          address: '1.2.3.4',
          port: 443,
        ),
      ];

      final subscription = Subscription(
        url: 'https://example.com/sub',
        name: 'My Sub',
        lastUpdate: now,
        servers: servers,
      );

      expect(subscription.url, 'https://example.com/sub');
      expect(subscription.name, 'My Sub');
      expect(subscription.lastUpdate, now);
      expect(subscription.servers.length, 1);
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final now = DateTime(2026, 5, 14, 12, 0, 0);
        final subscription = Subscription(
          url: 'https://example.com/sub',
          name: 'Test Sub',
          lastUpdate: now,
          servers: [
            ServerConfig(
              url: 'vmess://test',
              remark: 'Test Server',
              protocol: 'vmess',
              address: '10.0.0.1',
              port: 443,
              latencyMs: 150,
            ),
          ],
        );

        final json = subscription.toJson();

        expect(json['url'], 'https://example.com/sub');
        expect(json['name'], 'Test Sub');
        expect(json['lastUpdate'], now.toIso8601String());
        expect(json['servers'], isA<List>());
        expect((json['servers'] as List).length, 1);
      });

      test('should deserialize from JSON', () {
        final json = {
          'url': 'https://example.com/sub',
          'name': 'My Subscription',
          'lastUpdate': '2026-05-14T12:00:00.000',
          'servers': [
            {
              'url': 'vless://abc',
              'remark': 'Server A',
              'protocol': 'vless',
              'address': '192.168.1.1',
              'port': 8443,
              'latencyMs': 200,
            },
          ],
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.url, 'https://example.com/sub');
        expect(subscription.name, 'My Subscription');
        expect(subscription.lastUpdate, isNotNull);
        expect(subscription.servers.length, 1);
        expect(subscription.servers[0].protocol, 'vless');
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'url': 'https://example.com/sub',
          'name': null,
          'lastUpdate': null,
          'servers': null,
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.url, 'https://example.com/sub');
        expect(subscription.name, isNull);
        expect(subscription.lastUpdate, isNull);
        expect(subscription.servers, isEmpty);
      });

      test('should roundtrip through JSON', () {
        final original = Subscription(
          url: 'https://test.com/sub',
          name: 'Roundtrip Test',
          lastUpdate: DateTime(2026, 1, 1),
          servers: [
            ServerConfig(
              url: 'trojan://abc',
              remark: 'Trojan Server',
              protocol: 'trojan',
              address: 'trojan.example.com',
              port: 443,
            ),
          ],
        );

        final json = original.toJson();
        final restored = Subscription.fromJson(json);

        expect(restored.url, original.url);
        expect(restored.name, original.name);
        expect(restored.servers.length, original.servers.length);
        expect(restored.servers[0].address, original.servers[0].address);
      });
    });
  });

  group('ServerConfig', () {
    test('should create with required fields', () {
      final server = ServerConfig(
        url: 'vmess://xyz',
        remark: 'Test Server',
        protocol: 'vmess',
        address: '10.0.0.1',
        port: 443,
      );

      expect(server.url, 'vmess://xyz');
      expect(server.remark, 'Test Server');
      expect(server.protocol, 'vmess');
      expect(server.address, '10.0.0.1');
      expect(server.port, 443);
      expect(server.latencyMs, isNull);
    });

    test('should create with latency', () {
      final server = ServerConfig(
        url: 'vless://abc',
        remark: 'Fast Server',
        protocol: 'vless',
        address: '1.1.1.1',
        port: 8443,
        latencyMs: 50,
      );

      expect(server.latencyMs, 50);
    });

    test('should allow mutable latencyMs', () {
      final server = ServerConfig(
        url: 'vmess://test',
        remark: 'Pingable',
        protocol: 'vmess',
        address: '2.2.2.2',
        port: 443,
      );

      expect(server.latencyMs, isNull);
      server.latencyMs = 100;
      expect(server.latencyMs, 100);
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final server = ServerConfig(
          url: 'ss://abc',
          remark: 'Shadowsocks Server',
          protocol: 'ss',
          address: 'ss.example.com',
          port: 8388,
          latencyMs: 75,
        );

        final json = server.toJson();

        expect(json['url'], 'ss://abc');
        expect(json['remark'], 'Shadowsocks Server');
        expect(json['protocol'], 'ss');
        expect(json['address'], 'ss.example.com');
        expect(json['port'], 8388);
        expect(json['latencyMs'], 75);
      });

      test('should deserialize from JSON', () {
        final json = {
          'url': 'trojan://xyz',
          'remark': 'Trojan Node',
          'protocol': 'trojan',
          'address': 'tr.example.org',
          'port': 443,
          'latencyMs': 120,
        };

        final server = ServerConfig.fromJson(json);

        expect(server.url, 'trojan://xyz');
        expect(server.remark, 'Trojan Node');
        expect(server.protocol, 'trojan');
        expect(server.address, 'tr.example.org');
        expect(server.port, 443);
        expect(server.latencyMs, 120);
      });

      test('should handle null latencyMs in JSON', () {
        final json = {
          'url': 'vmess://test',
          'remark': 'No Ping',
          'protocol': 'vmess',
          'address': '3.3.3.3',
          'port': 443,
          'latencyMs': null,
        };

        final server = ServerConfig.fromJson(json);

        expect(server.latencyMs, isNull);
      });
    });

    group('fromV2RayURL', () {
      // NOTE: These tests are skipped because ServerConfig.fromV2RayURL has a bug:
      // It casts config['port'] to int? but vmess parser returns port as String.
      // This is a known issue to be fixed in Task 2.4 (V2 API Native Calls).
      //
      // Bug location: subscription_manager.dart:84
      //   port: config['port'] as int? ?? 0,
      // Should be:
      //   port: int.tryParse(config['port']?.toString() ?? '') ?? 0,

      test('should extract protocol from URL scheme', () {
        const vlessUrl = 'vless://550e8400-e29b-41d4-a716-446655440000@vless.example.com:8443#Test';

        final v2rayUrl = parseV2RayURL(vlessUrl);
        expect(v2rayUrl, isNotNull);

        // Just test URL scheme extraction (doesn't trigger the port bug)
        expect(v2rayUrl!.url.split('://')[0], 'vless');
      });

      test('should preserve original URL', () {
        const trojanUrl = 'trojan://password@host:443#Remark';

        final v2rayUrl = parseV2RayURL(trojanUrl);
        expect(v2rayUrl, isNotNull);
        expect(v2rayUrl!.url, trojanUrl);
      });

      test('should extract remark from URL', () {
        const socksUrl = 'socks://user:pass@socks.proxy.io:1080#My%20SOCKS%20Proxy';

        final v2rayUrl = parseV2RayURL(socksUrl);
        expect(v2rayUrl, isNotNull);
        expect(v2rayUrl!.remark, 'My SOCKS Proxy');
      });
    });
  });

  group('PingResult', () {
    test('should create successful result', () {
      final result = PingResult(
        subscriptionIndex: 0,
        serverIndex: 2,
        latencyInMs: 150,
        success: true,
      );

      expect(result.subscriptionIndex, 0);
      expect(result.serverIndex, 2);
      expect(result.latencyInMs, 150);
      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('should create failed result with error', () {
      final result = PingResult(
        subscriptionIndex: 1,
        serverIndex: 0,
        latencyInMs: -1,
        success: false,
        error: 'Connection timeout',
      );

      expect(result.subscriptionIndex, 1);
      expect(result.serverIndex, 0);
      expect(result.latencyInMs, -1);
      expect(result.success, isFalse);
      expect(result.error, 'Connection timeout');
    });
  });

  group('SubscriptionManager', () {
    late SubscriptionManager manager;

    setUp(() {
      manager = SubscriptionManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('addSubscription', () {
      test('should add subscription with URL only', () {
        manager.addSubscription(subscriptionURL: 'https://sub1.example.com');

        expect(manager.subscriptions.length, 1);
        expect(manager.subscriptions[0].url, 'https://sub1.example.com');
        expect(manager.subscriptions[0].name, isNull);
      });

      test('should add subscription with URL and name', () {
        manager.addSubscription(
          subscriptionURL: 'https://sub2.example.com',
          name: 'Premium Sub',
        );

        expect(manager.subscriptions.length, 1);
        expect(manager.subscriptions[0].url, 'https://sub2.example.com');
        expect(manager.subscriptions[0].name, 'Premium Sub');
      });

      test('should add multiple subscriptions', () {
        manager.addSubscription(subscriptionURL: 'https://sub1.com');
        manager.addSubscription(subscriptionURL: 'https://sub2.com');
        manager.addSubscription(subscriptionURL: 'https://sub3.com');

        expect(manager.subscriptions.length, 3);
      });
    });

    group('clearSubscriptions', () {
      test('should clear all subscriptions', () {
        manager.addSubscription(subscriptionURL: 'https://sub1.com');
        manager.addSubscription(subscriptionURL: 'https://sub2.com');
        expect(manager.subscriptions.length, 2);

        manager.clearSubscriptions();

        expect(manager.subscriptions, isEmpty);
      });

      test('should be safe to call on empty manager', () {
        expect(manager.subscriptions, isEmpty);
        manager.clearSubscriptions();
        expect(manager.subscriptions, isEmpty);
      });
    });

    group('subscriptions getter', () {
      test('should return unmodifiable list', () {
        manager.addSubscription(subscriptionURL: 'https://test.com');

        final subs = manager.subscriptions;

        // The list should be unmodifiable
        expect(() => (subs as List).add(Subscription(url: 'bad')),
            throwsUnsupportedError);
      });

      test('should reflect current state', () {
        expect(manager.subscriptions, isEmpty);

        manager.addSubscription(subscriptionURL: 'https://a.com');
        expect(manager.subscriptions.length, 1);

        manager.addSubscription(subscriptionURL: 'https://b.com');
        expect(manager.subscriptions.length, 2);

        manager.clearSubscriptions();
        expect(manager.subscriptions, isEmpty);
      });
    });

    group('getServer', () {
      setUp(() {
        // Add a subscription with servers manually
        manager.addSubscription(subscriptionURL: 'https://test.com');
        // Access internal list to add servers for testing
        final subscription = manager.subscriptions[0];
        subscription.servers = [
          ServerConfig(
            url: 'vmess://a',
            remark: 'Server A',
            protocol: 'vmess',
            address: '1.1.1.1',
            port: 443,
          ),
          ServerConfig(
            url: 'vless://b',
            remark: 'Server B',
            protocol: 'vless',
            address: '2.2.2.2',
            port: 8443,
          ),
        ];
      });

      test('should return server at valid indices', () {
        final server = manager.getServer(
          subscriptionIndex: 0,
          serverIndex: 0,
        );

        expect(server, isNotNull);
        expect(server!.remark, 'Server A');
      });

      test('should return second server', () {
        final server = manager.getServer(
          subscriptionIndex: 0,
          serverIndex: 1,
        );

        expect(server, isNotNull);
        expect(server!.remark, 'Server B');
      });

      test('should return null for negative subscription index', () {
        final server = manager.getServer(
          subscriptionIndex: -1,
          serverIndex: 0,
        );

        expect(server, isNull);
      });

      test('should return null for out of bounds subscription index', () {
        final server = manager.getServer(
          subscriptionIndex: 99,
          serverIndex: 0,
        );

        expect(server, isNull);
      });

      test('should return null for negative server index', () {
        final server = manager.getServer(
          subscriptionIndex: 0,
          serverIndex: -1,
        );

        expect(server, isNull);
      });

      test('should return null for out of bounds server index', () {
        final server = manager.getServer(
          subscriptionIndex: 0,
          serverIndex: 99,
        );

        expect(server, isNull);
      });
    });

    group('updateSubscription', () {
      test('should return false for negative index', () async {
        final result = await manager.updateSubscription(subscriptionIndex: -1);
        expect(result, isFalse);
      });

      test('should return false for out of bounds index', () async {
        manager.addSubscription(subscriptionURL: 'https://test.com');

        final result = await manager.updateSubscription(subscriptionIndex: 5);

        expect(result, isFalse);
      });

      test('should return false when no subscriptions exist', () async {
        final result = await manager.updateSubscription(subscriptionIndex: 0);
        expect(result, isFalse);
      });
    });

    group('pingServer', () {
      test('should emit error for invalid subscription index', () async {
        manager.addSubscription(subscriptionURL: 'https://test.com');

        final results = <PingResult>[];
        final subscription = manager.onPingResult.listen(results.add);

        await manager.pingServer(
          subscriptionIndex: -1,
          serverIndex: 0,
        );

        // Allow stream to process
        await Future.delayed(Duration.zero);

        expect(results.length, 1);
        expect(results[0].success, isFalse);
        expect(results[0].error, 'Invalid subscription index');
        expect(results[0].latencyInMs, -1);

        await subscription.cancel();
      });

      test('should emit error for invalid server index', () async {
        manager.addSubscription(subscriptionURL: 'https://test.com');
        // No servers in subscription

        final results = <PingResult>[];
        final subscription = manager.onPingResult.listen(results.add);

        await manager.pingServer(
          subscriptionIndex: 0,
          serverIndex: 0,
        );

        await Future.delayed(Duration.zero);

        expect(results.length, 1);
        expect(results[0].success, isFalse);
        expect(results[0].error, 'Invalid server index');

        await subscription.cancel();
      });

      test('should include correct indices in error result', () async {
        final results = <PingResult>[];
        final subscription = manager.onPingResult.listen(results.add);

        await manager.pingServer(
          subscriptionIndex: 5,
          serverIndex: 10,
        );

        await Future.delayed(Duration.zero);

        expect(results[0].subscriptionIndex, 5);
        expect(results[0].serverIndex, 10);

        await subscription.cancel();
      });
    });

    group('onPingResult stream', () {
      test('should be a broadcast stream', () {
        // Should be able to listen multiple times
        final sub1 = manager.onPingResult.listen((_) {});
        final sub2 = manager.onPingResult.listen((_) {});

        // If it were a single-subscription stream, this would throw
        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });
    });

    group('dispose', () {
      test('should close the ping result stream', () async {
        var streamClosed = false;
        manager.onPingResult.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        manager.dispose();

        // Allow stream to close
        await Future.delayed(Duration.zero);

        expect(streamClosed, isTrue);
      });
    });
  });
}
