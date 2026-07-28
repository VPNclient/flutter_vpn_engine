import 'package:meta/meta.dart';

import '../config/protocol_config.dart';

/// How a [Server]'s connection parameters were authored.
///
/// Matches `flutter_vpnclient_engine_mock`'s `ServerDefinition` shape.
/// Restructuring of the real `ServerConfig`'s data (was a mutable class
/// keyed by list position) into a stable, immutable, id-addressed shape —
/// not new capability.
@immutable
sealed class ServerDefinition {
  const ServerDefinition();

  ProtocolConfig resolve();

  Map<String, dynamic> toJson();

  static ServerDefinition fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'shareLink' => ShareLinkDefinition(json['raw'] as String),
      'fullConfig' =>
        FullConfigDefinition(ProtocolConfig.fromJson(json['config'] as Map<String, dynamic>)),
      _ => throw FormatException('Unknown ServerDefinition type: ${json['type']}'),
    };
  }
}

@immutable
class ShareLinkDefinition extends ServerDefinition {
  const ShareLinkDefinition(this.raw);

  /// Real xray-style share-link, e.g. `vless://uuid@host:443?...#remark`.
  final String raw;

  @override
  ProtocolConfig resolve() => ProtocolConfig.parseShareLink(raw);

  @override
  bool operator ==(Object other) =>
      other is ShareLinkDefinition && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  @override
  Map<String, dynamic> toJson() => {'type': 'shareLink', 'raw': raw};
}

@immutable
class FullConfigDefinition extends ServerDefinition {
  const FullConfigDefinition(this.config);

  final ProtocolConfig config;

  @override
  ProtocolConfig resolve() => config;

  @override
  bool operator ==(Object other) =>
      other is FullConfigDefinition && other.config == config;

  @override
  int get hashCode => config.hashCode;

  @override
  Map<String, dynamic> toJson() => {'type': 'fullConfig', 'config': config.toJson()};
}
