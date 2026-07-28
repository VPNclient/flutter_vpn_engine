import 'package:meta/meta.dart';

import '../config/protocol_config.dart';
import 'server_definition.dart';

/// Matches `flutter_vpnclient_engine_mock`'s `Server` shape. Restructuring of
/// the real `ServerConfig` (address/port/remark/protocol fields, previously
/// addressed by list position) into a stable-id, immutable model.
@immutable
class Server {
  const Server({
    required this.id,
    required this.name,
    required this.definition,
    this.lastPingMs,
  });

  final String id;
  final String name;
  final ServerDefinition definition;

  /// Real value once `SubscriptionManager.pingServer` has run (ported real
  /// `Socket.connect`+`Stopwatch` timing) — null until then.
  final int? lastPingMs;

  ProtocolConfig get protocolConfig => definition.resolve();

  Server copyWith({
    String? id,
    String? name,
    ServerDefinition? definition,
    int? lastPingMs,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      definition: definition ?? this.definition,
      lastPingMs: lastPingMs ?? this.lastPingMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Server &&
      other.id == id &&
      other.name == name &&
      other.definition == definition &&
      other.lastPingMs == lastPingMs;

  @override
  int get hashCode => Object.hash(id, name, definition, lastPingMs);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'definition': definition.toJson(),
        'lastPingMs': lastPingMs,
      };

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] as String,
      name: json['name'] as String,
      definition: ServerDefinition.fromJson(json['definition'] as Map<String, dynamic>),
      lastPingMs: json['lastPingMs'] as int?,
    );
  }
}
