import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';
import 'package:vpnclient_engine/src/subscriptions/storage/in_memory_subscription_store.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription.dart';

void main() {
  test('load() returns an empty list before any save()', () async {
    final store = InMemorySubscriptionStore();
    expect(await store.load(), isEmpty);
  });

  test('save() then load() round-trips a List<Subscription> exactly', () async {
    final store = InMemorySubscriptionStore();
    final subscriptions = [
      Subscription(
        id: 'sub1',
        name: 'Local',
        url: null,
        servers: [
          Server(
            id: 's1',
            name: 'Server 1',
            definition: const ShareLinkDefinition('ss://YWVzLTI1Ni1nY206c2VjcmV0@host:1#r'),
          ),
        ],
      ),
    ];

    await store.save(subscriptions);
    final loaded = await store.load();

    expect(loaded, subscriptions);
  });
}
