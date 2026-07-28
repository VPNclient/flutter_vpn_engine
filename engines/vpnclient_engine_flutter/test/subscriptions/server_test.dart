import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';

void main() {
  test('Server with a ShareLinkDefinition resolves protocolConfig via the real parser', () {
    final server = Server(
      id: 's1',
      name: 'Share-link server',
      definition: const ShareLinkDefinition(
        'trojan://pw@trojan.example.com:443?security=tls&sni=trojan.example.com',
      ),
    );

    final config = server.protocolConfig;

    expect(config, isA<TrojanConfig>());
    expect((config as TrojanConfig).address, 'trojan.example.com');
    expect(config.password, 'pw');
  });

  test('Server with a FullConfigDefinition resolves protocolConfig directly', () {
    const config = ShadowsocksConfig(
      address: 'ss.example.com',
      port: 8388,
      method: 'aes-256-gcm',
      password: 'secret',
    );
    final server = Server(
      id: 's2',
      name: 'Full-config server',
      definition: const FullConfigDefinition(config),
    );

    expect(server.protocolConfig, same(config));
  });

  test('copyWith overrides only given fields', () {
    final server = Server(
      id: 's3',
      name: 'Original',
      definition: const ShareLinkDefinition('ss://x@host:1#r'),
    );
    final updated = server.copyWith(lastPingMs: 42);
    expect(updated.lastPingMs, 42);
    expect(updated.name, 'Original');
    expect(server.lastPingMs, isNull, reason: 'copyWith must not mutate original');
  });
}
