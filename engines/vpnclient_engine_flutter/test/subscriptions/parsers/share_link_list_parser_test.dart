import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/subscriptions/parsers/share_link_list_parser.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';

const parser = ShareLinkListParser();

void main() {
  test('canParse always returns true (no real rejection concept to port)', () {
    expect(parser.canParse('anything'), isTrue);
  });

  test('parses a realistic base64 share-link list, matching the real updateSubscription', () {
    const ssLine = 'ss://YWVzLTI1Ni1nY206c2VjcmV0@ss.example.com:8388#My-SS';
    const trojanLine = 'trojan://pw@trojan.example.com:443?security=tls&sni=trojan.example.com#My-Trojan';
    final body = base64Encode(utf8.encode('$ssLine\n$trojanLine'));

    final servers = parser.parse(body);

    expect(servers, hasLength(2));
    expect(servers[0].name, 'My-SS');
    expect(servers[0].definition, isA<ShareLinkDefinition>());
    expect(servers[1].name, 'My-Trojan');
  });

  test('falls back to raw (non-base64) content, matching the real fallback', () {
    const raw = 'ss://YWVzLTI1Ni1nY206c2VjcmV0@ss.example.com:8388#Raw-SS';
    final servers = parser.parse(raw);
    expect(servers, hasLength(1));
    expect(servers.single.name, 'Raw-SS');
  });

  test('silently skips unparseable lines instead of throwing', () {
    final body = base64Encode(utf8.encode('not a share link\n\nss://YWVzLTI1Ni1nY206c2VjcmV0@host:1#OK'));
    final servers = parser.parse(body);
    expect(servers, hasLength(1));
    expect(servers.single.name, 'OK');
  });
}
