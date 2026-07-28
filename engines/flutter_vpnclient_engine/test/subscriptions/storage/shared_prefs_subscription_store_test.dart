import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';
import 'package:vpnclient_engine/src/subscriptions/storage/shared_prefs_subscription_store.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save() then load() with a *new* store instance round-trips exactly, '
      'including ShareLink vs FullConfig discrimination', () async {
    final subscriptions = [
      Subscription(
        id: 'sub-remote',
        name: 'Remote sub',
        url: Uri.parse('https://example.com/sub.txt'),
        refreshInterval: const Duration(hours: 6),
        lastUpdatedAt: DateTime.utc(2026, 7, 28),
        servers: [
          Server(
            id: 's1',
            name: 'Share-link server',
            definition: const ShareLinkDefinition('ss://YWVzLTI1Ni1nY206c2VjcmV0@host:1#r'),
            lastPingMs: 42,
          ),
          Server(
            id: 's2',
            name: 'Full-config server',
            definition: const FullConfigDefinition(
              WireGuardConfig(
                address: 'wg.example.com',
                port: 51820,
                publicKey: 'pub',
                privateKey: 'priv',
                allowedIps: ['0.0.0.0/0'],
              ),
            ),
          ),
        ],
      ),
      Subscription(id: 'sub-local', name: 'Local sub', url: null, servers: const []),
    ];

    final writer = SharedPrefsSubscriptionStore();
    await writer.save(subscriptions);

    final reader = SharedPrefsSubscriptionStore();
    final loaded = await reader.load();

    expect(loaded, subscriptions);
    expect(loaded[0].servers[0].definition, isA<ShareLinkDefinition>());
    expect(loaded[0].servers[1].definition, isA<FullConfigDefinition>());
    expect(loaded[1].isLocal, isTrue);
  });

  test('load() returns an empty list when nothing has been saved yet', () async {
    final store = SharedPrefsSubscriptionStore();
    expect(await store.load(), isEmpty);
  });
}
