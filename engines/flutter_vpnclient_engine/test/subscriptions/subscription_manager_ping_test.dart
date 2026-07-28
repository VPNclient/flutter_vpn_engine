import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';
import 'package:vpnclient_engine/src/subscriptions/storage/in_memory_subscription_store.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription_manager.dart';

void main() {
  test('pingServer performs a real TCP connect against a locally-bound ServerSocket', () async {
    final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = serverSocket.listen((socket) => socket.close());

    try {
      final manager = SubscriptionManager(store: InMemorySubscriptionStore());
      final sub = await manager.addLocalSubscription(name: 'Local');
      final server = await manager.addServer(
        sub.id,
        FullConfigDefinition(
          ShadowsocksConfig(
            address: '127.0.0.1',
            port: serverSocket.port,
            method: 'aes-256-gcm',
            password: 'secret',
          ),
        ),
        name: 'Local test server',
      );
      expect(server.lastPingMs, isNull);

      final resultFuture = manager.onPingResult.first;
      manager.pingServer(sub.id, server.id);
      final result = await resultFuture;

      expect(result.success, isTrue);
      expect(result.latencyMs, greaterThanOrEqualTo(0));

      final updated = manager.subscriptions.single.servers.single;
      expect(updated.lastPingMs, result.latencyMs);
    } finally {
      await subscription.cancel();
      await serverSocket.close();
    }
  });

  test('pingServer against an unknown server id emits a failure PingResult, no throw', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addLocalSubscription(name: 'Local');

    final resultFuture = manager.onPingResult.first;
    manager.pingServer(sub.id, 'no-such-server');
    final result = await resultFuture;

    expect(result.success, isFalse);
    expect(result.latencyMs, -1);
    expect(result.error, isNotNull);
  });

  test('pingServer against an unreachable port fails and reports via onPingResult', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addLocalSubscription(name: 'Local');
    final server = await manager.addServer(
      sub.id,
      const FullConfigDefinition(
        ShadowsocksConfig(
          address: '127.0.0.1',
          port: 1, // reserved/unlikely-to-be-listening port
          method: 'aes-256-gcm',
          password: 'secret',
        ),
      ),
      name: 'Unreachable',
    );

    final resultFuture = manager.onPingResult.first;
    manager.pingServer(sub.id, server.id);
    final result = await resultFuture;

    expect(result.success, isFalse);
    expect(result.error, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
