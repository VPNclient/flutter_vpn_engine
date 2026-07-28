import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vpnclient_engine/src/subscriptions/storage/in_memory_subscription_store.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription_manager.dart';

http.Client _mockClientReturning(String body) {
  return MockClient((request) async => http.Response(body, 200));
}

void main() {
  test('refreshSubscription on a local subscription throws StateError', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addLocalSubscription(name: 'Local');

    expect(() => manager.refreshSubscription(sub.id), throwsStateError);
  });

  test('refreshSubscription fetches (real http) + parses (real V2Ray parsing), replaces servers', () async {
    final shareLine = 'ss://${base64Encode(utf8.encode('aes-256-gcm:secret'))}@ss.example.com:8388#Remote-SS';
    final body = base64Encode(utf8.encode(shareLine));

    final manager = SubscriptionManager(
      store: InMemorySubscriptionStore(),
      httpClient: _mockClientReturning(body),
    );
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );
    expect(sub.servers, isEmpty);

    await manager.refreshSubscription(sub.id);

    final refreshed = manager.subscriptions.firstWhere((s) => s.id == sub.id);
    expect(refreshed.servers, hasLength(1));
    expect(refreshed.servers.single.name, 'Remote-SS');
    expect(refreshed.lastUpdatedAt, isNotNull);
  });

  test('a body with zero parseable lines yields zero servers (real tolerant behavior, no throw)', () async {
    final manager = SubscriptionManager(
      store: InMemorySubscriptionStore(),
      httpClient: _mockClientReturning('not a valid subscription body at all'),
    );
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );

    await manager.refreshSubscription(sub.id);

    final refreshed = manager.subscriptions.firstWhere((s) => s.id == sub.id);
    expect(refreshed.servers, isEmpty);
    expect(refreshed.lastUpdatedAt, isNotNull);
  });
}
