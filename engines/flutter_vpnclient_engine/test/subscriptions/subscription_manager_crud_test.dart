import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';
import 'package:vpnclient_engine/src/subscriptions/storage/in_memory_subscription_store.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription_manager.dart';

void main() {
  test('ready resolves; a second manager against the same store sees the first\'s writes', () async {
    final store = InMemorySubscriptionStore();

    final first = SubscriptionManager(store: store);
    await first.ready;
    expect(first.subscriptions, isEmpty);

    await first.addLocalSubscription(name: 'My local list');

    final second = SubscriptionManager(store: store);
    await second.ready;

    expect(second.subscriptions, hasLength(1));
    expect(second.subscriptions.single.name, 'My local list');
    expect(second.subscriptions.single.isLocal, isTrue);
  });

  test('addRemoteSubscription creates a subscription with url/refreshInterval set', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
      refreshInterval: const Duration(hours: 12),
    );

    expect(sub.isLocal, isFalse);
    expect(sub.url, Uri.parse('https://example.com/sub'));
    expect(sub.refreshInterval, const Duration(hours: 12));
    expect(manager.subscriptions, contains(sub));
  });

  test('removeSubscription and renameSubscription mutate and persist', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addLocalSubscription(name: 'Original');

    await manager.renameSubscription(sub.id, 'Renamed');
    expect(manager.subscriptions.single.name, 'Renamed');

    await manager.removeSubscription(sub.id);
    expect(manager.subscriptions, isEmpty);
  });

  test('addServer/updateServer/removeServer work on a local subscription', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addLocalSubscription(name: 'Local');

    final server = await manager.addServer(
      sub.id,
      const ShareLinkDefinition('ss://x@host:1#r'),
      name: 'Manual server',
    );
    expect(manager.subscriptions.single.servers, hasLength(1));

    await manager.updateServer(sub.id, server.id, const ShareLinkDefinition('ss://y@host2:2#r2'));
    expect(
      (manager.subscriptions.single.servers.single.definition as ShareLinkDefinition).raw,
      'ss://y@host2:2#r2',
    );

    await manager.removeServer(sub.id, server.id);
    expect(manager.subscriptions.single.servers, isEmpty);
  });

  test('addServer/updateServer/removeServer on a remote subscription throw StateError', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );

    expect(
      () => manager.addServer(sub.id, const ShareLinkDefinition('ss://x@host:1#r')),
      throwsStateError,
    );
    expect(
      () => manager.updateServer(sub.id, 'whatever', const ShareLinkDefinition('ss://x@host:1#r')),
      throwsStateError,
    );
    expect(() => manager.removeServer(sub.id, 'whatever'), throwsStateError);
  });
}
