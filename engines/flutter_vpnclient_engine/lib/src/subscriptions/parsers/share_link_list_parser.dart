import 'dart:convert';

import '../../v2ray_url_parser.dart';
import '../id_generator.dart';
import '../server.dart';
import '../server_definition.dart';
import '../subscription_parser.dart';

/// The only registered parser in this port (no real precedent exists for the
/// mock's JSON-array/sing-box-config parsers — genuine gap, not built here).
///
/// Ports `subscription_manager.dart`'s real `updateSubscription` body
/// verbatim: attempt base64 decode, fall back to the raw body if that fails,
/// split on newline, parse each non-empty line via the real `parseV2RayURL`,
/// **silently skip lines that don't parse** — this tolerant behavior (no
/// per-line exception) is the real, existing behavior, not a design choice
/// made by this port.
class ShareLinkListParser extends SubscriptionParser {
  const ShareLinkListParser();

  /// The real code never rejects a subscription body outright — it always
  /// attempts a parse (falling back to raw content, and to zero servers if no
  /// line matches). No format-sniffing concept exists to port, so this always
  /// returns `true`: this parser is unconditionally the one used, matching
  /// reality (only one exists to register).
  @override
  bool canParse(String rawBody) => true;

  @override
  List<Server> parse(String rawBody) {
    String content;
    try {
      content = utf8.decode(base64.decode(rawBody));
    } catch (_) {
      content = rawBody;
    }

    final servers = <Server>[];
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final v2rayUrl = parseV2RayURL(trimmed);
      if (v2rayUrl == null) continue;
      servers.add(Server(
        id: generateId('srv'),
        name: v2rayUrl.remark,
        definition: ShareLinkDefinition(trimmed),
      ));
    }
    return servers;
  }
}
