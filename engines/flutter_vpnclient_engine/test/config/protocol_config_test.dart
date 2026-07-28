import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/config/transport_config.dart';

void main() {
  test('parses a real VLESS + Reality share-link', () {
    const link = 'vless://2d4e5f6a-1234-5678-9abc-def012345678@example.com:443'
        '?encryption=none&security=reality&pbk=abcPublicKey123&fp=chrome'
        '&sni=www.microsoft.com&sid=0123456789abcdef&type=tcp&flow=xtls-rprx-vision'
        '#My-Server';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<VlessConfig>());
    final vless = config as VlessConfig;
    expect(vless.address, 'example.com');
    expect(vless.port, 443);
    expect(vless.uuid, '2d4e5f6a-1234-5678-9abc-def012345678');
    expect(vless.flow, 'xtls-rprx-vision');
    expect(vless.tls?.sni, 'www.microsoft.com');
    expect(vless.tls?.reality?.publicKey, 'abcPublicKey123');
    expect(vless.tls?.reality?.shortId, '0123456789abcdef');
  });

  test('parses a real VMess share-link (base64 JSON)', () {
    final json = jsonEncode({
      'v': '2',
      'ps': 'vmess-server',
      'add': 'vmess.example.com',
      'port': '443',
      'id': 'b831381d-6324-4d53-ad4f-8cda48b30811',
      'aid': '0',
      'net': 'ws',
      'path': '/vmesspath',
      'tls': 'tls',
      'sni': 'sni.vmess.com',
    });
    final link = 'vmess://${base64Encode(utf8.encode(json))}';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<VmessConfig>());
    final vmess = config as VmessConfig;
    expect(vmess.address, 'vmess.example.com');
    expect(vmess.port, 443);
    expect(vmess.uuid, 'b831381d-6324-4d53-ad4f-8cda48b30811');
    expect(vmess.alterId, 0);
    expect(vmess.transport?.type, TransportType.ws);
    expect(vmess.transport?.path, '/vmesspath');
    expect(vmess.tls?.sni, 'sni.vmess.com');
  });

  test('parses a real Trojan share-link', () {
    const link = 'trojan://mypassword123@trojan.example.com:443'
        '?security=tls&sni=sni.trojan.com&type=ws#Trojan-Server';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<TrojanConfig>());
    final trojan = config as TrojanConfig;
    expect(trojan.address, 'trojan.example.com');
    expect(trojan.port, 443);
    expect(trojan.password, 'mypassword123');
    expect(trojan.transport?.type, TransportType.ws);
    expect(trojan.tls?.sni, 'sni.trojan.com');
  });

  test('parses a real Shadowsocks share-link', () {
    final userInfo = base64Encode(utf8.encode('aes-256-gcm:p@ssw0rd'));
    final link = 'ss://$userInfo@ss.example.com:8388#SS-Server';

    final config = ProtocolConfig.parseShareLink(link);

    expect(config, isA<ShadowsocksConfig>());
    final ss = config as ShadowsocksConfig;
    expect(ss.address, 'ss.example.com');
    expect(ss.port, 8388);
    expect(ss.method, 'aes-256-gcm');
    expect(ss.password, 'p@ssw0rd');
  });

  test('rejects an unsupported/unparseable scheme (incl. socks:// — no ProtocolConfig variant)', () {
    expect(
      () => ProtocolConfig.parseShareLink('socks://user:pass@host:1080'),
      throwsFormatException,
    );
    expect(
      () => ProtocolConfig.parseShareLink('unknownscheme://x'),
      throwsFormatException,
    );
  });

  test('WireGuardConfig has shape parity but no share-link parsing path', () {
    const config = WireGuardConfig(
      address: 'wg.example.com',
      port: 51820,
      publicKey: 'pub',
      privateKey: 'priv',
      allowedIps: ['0.0.0.0/0'],
    );
    expect(config.address, 'wg.example.com');
  });
}
