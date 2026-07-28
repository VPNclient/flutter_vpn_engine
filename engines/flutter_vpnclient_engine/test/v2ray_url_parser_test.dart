import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/v2ray_url_parser.dart';

void main() {
  group('parseV2RayURL', () {
    test('should return VmessURL for vmess:// protocol', () {
      final vmessConfig = base64.encode(utf8.encode(json.encode({
        'v': '2',
        'ps': 'Test Server',
        'add': 'example.com',
        'port': '443',
        'id': 'test-uuid',
        'aid': '0',
        'net': 'tcp',
        'tls': 'tls',
      })));
      final url = 'vmess://$vmessConfig';

      final result = parseV2RayURL(url);

      expect(result, isA<VmessURL>());
    });

    test('should return VlessURL for vless:// protocol', () {
      const url =
          'vless://test-uuid@example.com:443?encryption=none&security=tls&sni=example.com&type=tcp#Test%20Server';

      final result = parseV2RayURL(url);

      expect(result, isA<VlessURL>());
    });

    test('should return TrojanURL for trojan:// protocol', () {
      const url =
          'trojan://password123@example.com:443?sni=example.com&type=tcp#Test%20Server';

      final result = parseV2RayURL(url);

      expect(result, isA<TrojanURL>());
    });

    test('should return ShadowsocksURL for ss:// protocol', () {
      final userInfo = base64.encode(utf8.encode('aes-256-gcm:password123'));
      final url = 'ss://$userInfo@example.com:8388#Test%20Server';

      final result = parseV2RayURL(url);

      expect(result, isA<ShadowsocksURL>());
    });

    test('should return SocksURL for socks:// protocol', () {
      const url = 'socks://user:pass@example.com:1080#Test%20Server';

      final result = parseV2RayURL(url);

      expect(result, isA<SocksURL>());
    });

    test('should return null for unknown protocol', () {
      const url = 'http://example.com';

      final result = parseV2RayURL(url);

      expect(result, isNull);
    });

    test('should handle uppercase protocol', () {
      final vmessConfig = base64.encode(utf8.encode(json.encode({
        'ps': 'Test',
        'add': 'example.com',
        'port': '443',
        'id': 'uuid',
      })));
      final url = 'VMESS://$vmessConfig';

      final result = parseV2RayURL(url);

      expect(result, isA<VmessURL>());
    });
  });

  group('VmessURL', () {
    late String validVmessUrl;

    setUp(() {
      final config = {
        'v': '2',
        'ps': 'VMess Test Server',
        'add': 'vmess.example.com',
        'port': '443',
        'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'aid': '0',
        'net': 'ws',
        'tls': 'tls',
        'sni': 'vmess.example.com',
        'scy': 'auto',
      };
      validVmessUrl = 'vmess://${base64.encode(utf8.encode(json.encode(config)))}';
    });

    test('should parse valid VMess URL', () {
      final vmess = VmessURL(url: validVmessUrl);
      final parsed = vmess.parse();

      expect(parsed['add'], 'vmess.example.com');
      expect(parsed['port'], '443');
      expect(parsed['id'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(parsed['aid'], '0');
      expect(parsed['net'], 'ws');
      expect(parsed['tls'], 'tls');
    });

    test('should extract remark correctly', () {
      final vmess = VmessURL(url: validVmessUrl);

      expect(vmess.remark, 'VMess Test Server');
    });

    test('should use default remark when ps is missing', () {
      final config = {'add': 'example.com', 'port': '443', 'id': 'uuid'};
      final url = 'vmess://${base64.encode(utf8.encode(json.encode(config)))}';
      final vmess = VmessURL(url: url);

      expect(vmess.remark, 'VMess Server');
    });

    test('should generate valid V2Ray configuration', () {
      final vmess = VmessURL(url: validVmessUrl);
      final configJson = vmess.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      expect(config['outbounds'], isA<List>());
      final outbound = config['outbounds'][0] as Map<String, dynamic>;
      expect(outbound['protocol'], 'vmess');

      final vnext = outbound['settings']['vnext'][0] as Map<String, dynamic>;
      expect(vnext['address'], 'vmess.example.com');
      expect(vnext['port'], 443);

      final user = vnext['users'][0] as Map<String, dynamic>;
      expect(user['id'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(user['alterId'], 0);
    });

    test('should handle invalid base64 gracefully', () {
      const url = 'vmess://invalid-base64!!!';
      final vmess = VmessURL(url: url);

      expect(vmess.parse(), isEmpty);
    });

    test('should handle port as integer or string', () {
      final configWithIntPort = {
        'add': 'example.com',
        'port': 443,
        'id': 'uuid',
      };
      final url =
          'vmess://${base64.encode(utf8.encode(json.encode(configWithIntPort)))}';
      final vmess = VmessURL(url: url);
      final configJson = vmess.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final vnext = config['outbounds'][0]['settings']['vnext'][0];
      expect(vnext['port'], 443);
    });
  });

  group('VlessURL', () {
    test('should parse valid VLess URL', () {
      const url =
          'vless://a1b2c3d4-e5f6-7890-abcd-ef1234567890@vless.example.com:443?encryption=none&security=tls&sni=vless.example.com&type=tcp#VLess%20Test%20Server';

      final vless = VlessURL(url: url);
      final parsed = vless.parse();

      expect(parsed['uuid'], 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(parsed['address'], 'vless.example.com');
      expect(parsed['port'], 443);
      expect(parsed['encryption'], 'none');
      expect(parsed['security'], 'tls');
      expect(parsed['sni'], 'vless.example.com');
      expect(parsed['type'], 'tcp');
    });

    test('should extract remark from fragment', () {
      const url =
          'vless://uuid@example.com:443?security=tls#My%20VLess%20Server';

      final vless = VlessURL(url: url);

      expect(vless.remark, 'My VLess Server');
    });

    test('should parse REALITY settings', () {
      const url =
          'vless://uuid@example.com:443?encryption=none&security=reality&sni=www.google.com&fp=chrome&pbk=publickey123&sid=shortid#REALITY%20Server';

      final vless = VlessURL(url: url);
      final parsed = vless.parse();

      expect(parsed['security'], 'reality');
      expect(parsed['fp'], 'chrome');
      expect(parsed['pbk'], 'publickey123');
      expect(parsed['sid'], 'shortid');
    });

    test('should generate V2Ray config with REALITY settings', () {
      const url =
          'vless://uuid@example.com:443?encryption=none&security=reality&sni=www.google.com&fp=chrome&pbk=publickey123&sid=shortid#REALITY';

      final vless = VlessURL(url: url);
      final configJson = vless.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final streamSettings =
          config['outbounds'][0]['streamSettings'] as Map<String, dynamic>;
      expect(streamSettings['security'], 'reality');
      expect(streamSettings['realitySettings'], isNotNull);
      expect(streamSettings['realitySettings']['publicKey'], 'publickey123');
      expect(streamSettings['realitySettings']['shortId'], 'shortid');
    });

    test('should generate V2Ray config with TLS settings', () {
      const url =
          'vless://uuid@example.com:443?encryption=none&security=tls&sni=example.com#TLS%20Server';

      final vless = VlessURL(url: url);
      final configJson = vless.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final streamSettings =
          config['outbounds'][0]['streamSettings'] as Map<String, dynamic>;
      expect(streamSettings['security'], 'tls');
      expect(streamSettings['tlsSettings'], isNotNull);
      expect(streamSettings['tlsSettings']['serverName'], 'example.com');
    });

    test('should use defaults for missing parameters', () {
      const url = 'vless://uuid@example.com:443#Minimal';

      final vless = VlessURL(url: url);
      final parsed = vless.parse();

      expect(parsed['encryption'], 'none');
      expect(parsed['security'], 'none');
      expect(parsed['type'], 'tcp');
    });

    test('should handle flow parameter for XTLS', () {
      const url =
          'vless://uuid@example.com:443?flow=xtls-rprx-vision&security=tls#XTLS';

      final vless = VlessURL(url: url);
      final parsed = vless.parse();

      expect(parsed['flow'], 'xtls-rprx-vision');
    });
  });

  group('TrojanURL', () {
    test('should parse valid Trojan URL', () {
      const url =
          'trojan://password123@trojan.example.com:443?sni=trojan.example.com&type=tcp#Trojan%20Test';

      final trojan = TrojanURL(url: url);
      final parsed = trojan.parse();

      expect(parsed['password'], 'password123');
      expect(parsed['address'], 'trojan.example.com');
      expect(parsed['port'], 443);
      expect(parsed['sni'], 'trojan.example.com');
      expect(parsed['type'], 'tcp');
    });

    test('should extract remark from fragment', () {
      const url = 'trojan://pass@example.com:443#My%20Trojan%20Server';

      final trojan = TrojanURL(url: url);

      expect(trojan.remark, 'My Trojan Server');
    });

    test('should default sni to host if not provided', () {
      const url = 'trojan://pass@trojan.example.com:443#Test';

      final trojan = TrojanURL(url: url);
      final parsed = trojan.parse();

      expect(parsed['sni'], 'trojan.example.com');
    });

    test('should default security to tls', () {
      const url = 'trojan://pass@example.com:443#Test';

      final trojan = TrojanURL(url: url);
      final parsed = trojan.parse();

      expect(parsed['security'], 'tls');
    });

    test('should generate valid V2Ray configuration', () {
      const url = 'trojan://password123@example.com:443?sni=example.com#Test';

      final trojan = TrojanURL(url: url);
      final configJson = trojan.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final outbound = config['outbounds'][0] as Map<String, dynamic>;
      expect(outbound['protocol'], 'trojan');

      final server = outbound['settings']['servers'][0] as Map<String, dynamic>;
      expect(server['address'], 'example.com');
      expect(server['port'], 443);
      expect(server['password'], 'password123');

      final streamSettings = outbound['streamSettings'] as Map<String, dynamic>;
      expect(streamSettings['tlsSettings']['serverName'], 'example.com');
    });
  });

  group('ShadowsocksURL', () {
    test('should parse valid Shadowsocks URL', () {
      final userInfo = base64.encode(utf8.encode('aes-256-gcm:mypassword'));
      final url = 'ss://$userInfo@ss.example.com:8388#SS%20Test';

      final ss = ShadowsocksURL(url: url);
      final parsed = ss.parse();

      expect(parsed['method'], 'aes-256-gcm');
      expect(parsed['password'], 'mypassword');
      expect(parsed['address'], 'ss.example.com');
      expect(parsed['port'], 8388);
    });

    test('should extract remark from fragment', () {
      final userInfo = base64.encode(utf8.encode('aes-256-gcm:pass'));
      final url = 'ss://$userInfo@example.com:8388#My%20SS%20Server';

      final ss = ShadowsocksURL(url: url);

      expect(ss.remark, 'My SS Server');
    });

    test('should handle various encryption methods', () {
      final methods = [
        'aes-128-gcm',
        'aes-256-gcm',
        'chacha20-ietf-poly1305',
        'xchacha20-ietf-poly1305',
      ];

      for (final method in methods) {
        final userInfo = base64.encode(utf8.encode('$method:password'));
        final url = 'ss://$userInfo@example.com:8388#Test';

        final ss = ShadowsocksURL(url: url);
        final parsed = ss.parse();

        expect(parsed['method'], method);
      }
    });

    test('should generate valid V2Ray configuration', () {
      final userInfo = base64.encode(utf8.encode('aes-256-gcm:testpass'));
      final url = 'ss://$userInfo@example.com:8388#Test';

      final ss = ShadowsocksURL(url: url);
      final configJson = ss.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final outbound = config['outbounds'][0] as Map<String, dynamic>;
      expect(outbound['protocol'], 'shadowsocks');

      final server = outbound['settings']['servers'][0] as Map<String, dynamic>;
      expect(server['address'], 'example.com');
      expect(server['port'], 8388);
      expect(server['method'], 'aes-256-gcm');
      expect(server['password'], 'testpass');
    });

    test('should handle invalid base64 gracefully', () {
      const url = 'ss://invalid!!!@example.com:8388#Test';
      final ss = ShadowsocksURL(url: url);

      expect(ss.parse(), isEmpty);
    });
  });

  group('SocksURL', () {
    test('should parse valid Socks URL with auth', () {
      const url = 'socks://user:pass@socks.example.com:1080#Socks%20Test';

      final socks = SocksURL(url: url);
      final parsed = socks.parse();

      expect(parsed['username'], 'user');
      expect(parsed['password'], 'pass');
      expect(parsed['address'], 'socks.example.com');
      expect(parsed['port'], 1080);
    });

    test('should parse Socks URL without auth', () {
      const url = 'socks://socks.example.com:1080#No%20Auth';

      final socks = SocksURL(url: url);
      final parsed = socks.parse();

      expect(parsed['username'], '');
      expect(parsed['password'], '');
      expect(parsed['address'], 'socks.example.com');
      expect(parsed['port'], 1080);
    });

    test('should extract remark from fragment', () {
      const url = 'socks://example.com:1080#My%20Socks%20Proxy';

      final socks = SocksURL(url: url);

      expect(socks.remark, 'My Socks Proxy');
    });

    test('should generate V2Ray config with auth', () {
      const url = 'socks://user:pass@example.com:1080#Test';

      final socks = SocksURL(url: url);
      final configJson = socks.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final outbound = config['outbounds'][0] as Map<String, dynamic>;
      expect(outbound['protocol'], 'socks');

      final server = outbound['settings']['servers'][0] as Map<String, dynamic>;
      expect(server['address'], 'example.com');
      expect(server['port'], 1080);
      expect(server['users'], isNotNull);
      expect(server['users'][0]['user'], 'user');
      expect(server['users'][0]['pass'], 'pass');
    });

    test('should generate V2Ray config without auth', () {
      const url = 'socks://example.com:1080#Test';

      final socks = SocksURL(url: url);
      final configJson = socks.getFullConfiguration();
      final config = json.decode(configJson) as Map<String, dynamic>;

      final server =
          config['outbounds'][0]['settings']['servers'][0] as Map<String, dynamic>;
      expect(server.containsKey('users'), isFalse);
    });

    test('should handle username without password', () {
      const url = 'socks://useronly@example.com:1080#Test';

      final socks = SocksURL(url: url);
      final parsed = socks.parse();

      expect(parsed['username'], 'useronly');
      expect(parsed['password'], '');
    });
  });

  group('Configuration Generation', () {
    test('all parsers should generate valid JSON with inbounds', () {
      final urls = [
        'vmess://${base64.encode(utf8.encode(json.encode({'add': 'a.com', 'port': '443', 'id': 'uuid'})))}',
        'vless://uuid@b.com:443#Test',
        'trojan://pass@c.com:443#Test',
        'ss://${base64.encode(utf8.encode('aes-256-gcm:pass'))}@d.com:8388#Test',
        'socks://e.com:1080#Test',
      ];

      for (final url in urls) {
        final parser = parseV2RayURL(url);
        expect(parser, isNotNull, reason: 'Failed to parse: $url');

        final configJson = parser!.getFullConfiguration();
        final config = json.decode(configJson) as Map<String, dynamic>;

        expect(config['inbounds'], isA<List>());
        expect(config['inbounds'][0]['port'], 1080);
        expect(config['inbounds'][0]['protocol'], 'socks');
        expect(config['outbounds'], isA<List>());
      }
    });

    test('toShareUrl should return original URL', () {
      final vmessConfig = base64.encode(utf8.encode(json.encode({
        'add': 'example.com',
        'port': '443',
        'id': 'uuid',
      })));
      final urls = [
        'vmess://$vmessConfig',
        'vless://uuid@example.com:443#Test',
        'trojan://pass@example.com:443#Test',
        'ss://${base64.encode(utf8.encode('aes-256-gcm:pass'))}@example.com:8388#Test',
        'socks://example.com:1080#Test',
      ];

      for (final url in urls) {
        final parser = parseV2RayURL(url);
        expect(parser!.toShareUrl(), url);
      }
    });
  });
}
