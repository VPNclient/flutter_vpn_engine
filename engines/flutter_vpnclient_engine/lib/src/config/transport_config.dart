import 'package:meta/meta.dart';

/// Matches `flutter_vpnclient_engine_mock`'s `TransportConfig` shape exactly.
/// A typed container for fields the real `v2ray_url_parser.dart` already
/// extracts (`type`/`path`/`host` query params) — no new extraction logic.
enum TransportType { tcp, ws, grpc, http2 }

@immutable
class TransportConfig {
  const TransportConfig({
    required this.type,
    this.path,
    this.host,
    this.serviceName,
  });

  final TransportType type;
  final String? path;
  final String? host;
  final String? serviceName;

  @override
  bool operator ==(Object other) =>
      other is TransportConfig &&
      other.type == type &&
      other.path == path &&
      other.host == host &&
      other.serviceName == serviceName;

  @override
  int get hashCode => Object.hash(type, path, host, serviceName);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'path': path,
        'host': host,
        'serviceName': serviceName,
      };

  factory TransportConfig.fromJson(Map<String, dynamic> json) {
    return TransportConfig(
      type: TransportType.values.byName(json['type'] as String),
      path: json['path'] as String?,
      host: json['host'] as String?,
      serviceName: json['serviceName'] as String?,
    );
  }
}
