import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'server.dart';

/// Matches `flutter_vpnclient_engine_mock`'s `Subscription` shape.
/// Restructuring of the real `Subscription` (was mutable, URL-only, no
/// local/remote distinction) into an immutable model with a `local`
/// (`url == null`) option — no new capability, just the id/immutability
/// restructuring already applied to [Server].
@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.refreshInterval,
    this.lastUpdatedAt,
    required this.servers,
  });

  final String id;
  final String name;
  final Uri? url;
  final Duration? refreshInterval;
  final DateTime? lastUpdatedAt;
  final List<Server> servers;

  bool get isLocal => url == null;

  static const _serverListEquality = ListEquality<Server>();

  Subscription copyWith({
    String? id,
    String? name,
    Uri? url,
    bool clearUrl = false,
    Duration? refreshInterval,
    DateTime? lastUpdatedAt,
    List<Server>? servers,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: clearUrl ? null : (url ?? this.url),
      refreshInterval: refreshInterval ?? this.refreshInterval,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      servers: servers ?? this.servers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.id == id &&
      other.name == name &&
      other.url == url &&
      other.refreshInterval == refreshInterval &&
      other.lastUpdatedAt == lastUpdatedAt &&
      _serverListEquality.equals(other.servers, servers);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        url,
        refreshInterval,
        lastUpdatedAt,
        _serverListEquality.hash(servers),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url?.toString(),
        'refreshIntervalMs': refreshInterval?.inMilliseconds,
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
        'servers': servers.map((server) => server.toJson()).toList(),
      };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] != null ? Uri.parse(json['url'] as String) : null,
      refreshInterval: json['refreshIntervalMs'] != null
          ? Duration(milliseconds: json['refreshIntervalMs'] as int)
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : null,
      servers: (json['servers'] as List<dynamic>)
          .map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
