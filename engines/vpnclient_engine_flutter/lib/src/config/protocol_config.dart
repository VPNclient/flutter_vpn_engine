import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../v2ray_url_parser.dart';
import 'transport_config.dart';
import 'tls_config.dart';

/// A server's connection parameters, one concrete variant per protocol.
///
/// Matches `flutter_vpnclient_engine_mock`'s `ProtocolConfig` shape exactly.
/// Built from the real, already-working `v2ray_url_parser.dart` field
/// extraction — no new parsing logic, only a typed adapter over its output.
@immutable
sealed class ProtocolConfig {
  const ProtocolConfig({required this.address, required this.port});

  final String address;
  final int port;

  /// Parses a share-link via the real `parseV2RayURL` (unchanged) and adapts
  /// its extracted fields into the matching typed variant.
  ///
  /// No `WireGuardConfig` case: `v2ray_url_parser.dart` has no real WireGuard
  /// share-link parser to adapt (matches the mock's own scope — it has no
  /// real WireGuard share-link parsing either). No `socks://` case: the real
  /// `SocksURL` parser has no matching `ProtocolConfig` variant in the mock
  /// (Won't Have — extending the mock's own API is out of scope here).
  static ProtocolConfig parseShareLink(String raw) {
    final v2rayUrl = parseV2RayURL(raw);
    return switch (v2rayUrl) {
      VmessURL() => _fromVmess(v2rayUrl),
      VlessURL() => _fromVless(v2rayUrl),
      TrojanURL() => _fromTrojan(v2rayUrl),
      ShadowsocksURL() => _fromShadowsocks(v2rayUrl),
      _ => throw FormatException('Unsupported or unparseable share-link: $raw'),
    };
  }

  Map<String, dynamic> toJson();

  static ProtocolConfig fromJson(Map<String, dynamic> json) {
    return switch (json['protocol']) {
      'vless' => VlessConfig._fromJson(json),
      'vmess' => VmessConfig._fromJson(json),
      'trojan' => TrojanConfig._fromJson(json),
      'shadowsocks' => ShadowsocksConfig._fromJson(json),
      'wireguard' => WireGuardConfig._fromJson(json),
      _ => throw FormatException('Unknown protocol discriminator: ${json['protocol']}'),
    };
  }
}

@immutable
class VlessConfig extends ProtocolConfig {
  const VlessConfig({
    required super.address,
    required super.port,
    required this.uuid,
    this.flow,
    this.transport,
    this.tls,
  });

  final String uuid;
  final String? flow;
  final TransportConfig? transport;
  final TlsConfig? tls;

  @override
  bool operator ==(Object other) =>
      other is VlessConfig &&
      other.address == address &&
      other.port == port &&
      other.uuid == uuid &&
      other.flow == flow &&
      other.transport == transport &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(address, port, uuid, flow, transport, tls);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'vless',
        'address': address,
        'port': port,
        'uuid': uuid,
        'flow': flow,
        'transport': transport?.toJson(),
        'tls': tls?.toJson(),
      };

  factory VlessConfig._fromJson(Map<String, dynamic> json) {
    return VlessConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      uuid: json['uuid'] as String,
      flow: json['flow'] as String?,
      transport: json['transport'] != null
          ? TransportConfig.fromJson(json['transport'] as Map<String, dynamic>)
          : null,
      tls: json['tls'] != null
          ? TlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class VmessConfig extends ProtocolConfig {
  const VmessConfig({
    required super.address,
    required super.port,
    required this.uuid,
    required this.alterId,
    this.transport,
    this.tls,
  });

  final String uuid;
  final int alterId;
  final TransportConfig? transport;
  final TlsConfig? tls;

  @override
  bool operator ==(Object other) =>
      other is VmessConfig &&
      other.address == address &&
      other.port == port &&
      other.uuid == uuid &&
      other.alterId == alterId &&
      other.transport == transport &&
      other.tls == tls;

  @override
  int get hashCode =>
      Object.hash(address, port, uuid, alterId, transport, tls);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'vmess',
        'address': address,
        'port': port,
        'uuid': uuid,
        'alterId': alterId,
        'transport': transport?.toJson(),
        'tls': tls?.toJson(),
      };

  factory VmessConfig._fromJson(Map<String, dynamic> json) {
    return VmessConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      uuid: json['uuid'] as String,
      alterId: json['alterId'] as int,
      transport: json['transport'] != null
          ? TransportConfig.fromJson(json['transport'] as Map<String, dynamic>)
          : null,
      tls: json['tls'] != null
          ? TlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class TrojanConfig extends ProtocolConfig {
  const TrojanConfig({
    required super.address,
    required super.port,
    required this.password,
    this.transport,
    this.tls,
  });

  final String password;
  final TransportConfig? transport;
  final TlsConfig? tls;

  @override
  bool operator ==(Object other) =>
      other is TrojanConfig &&
      other.address == address &&
      other.port == port &&
      other.password == password &&
      other.transport == transport &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(address, port, password, transport, tls);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'trojan',
        'address': address,
        'port': port,
        'password': password,
        'transport': transport?.toJson(),
        'tls': tls?.toJson(),
      };

  factory TrojanConfig._fromJson(Map<String, dynamic> json) {
    return TrojanConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      password: json['password'] as String,
      transport: json['transport'] != null
          ? TransportConfig.fromJson(json['transport'] as Map<String, dynamic>)
          : null,
      tls: json['tls'] != null
          ? TlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class ShadowsocksConfig extends ProtocolConfig {
  const ShadowsocksConfig({
    required super.address,
    required super.port,
    required this.method,
    required this.password,
  });

  final String method;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is ShadowsocksConfig &&
      other.address == address &&
      other.port == port &&
      other.method == method &&
      other.password == password;

  @override
  int get hashCode => Object.hash(address, port, method, password);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'shadowsocks',
        'address': address,
        'port': port,
        'method': method,
        'password': password,
      };

  factory ShadowsocksConfig._fromJson(Map<String, dynamic> json) {
    return ShadowsocksConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      method: json['method'] as String,
      password: json['password'] as String,
    );
  }
}

/// Shape parity with the mock only — `v2ray_url_parser.dart` has no real
/// WireGuard share-link parser to adapt, so nothing ever constructs one via
/// [ProtocolConfig.parseShareLink]. Matches the mock's own scope exactly.
@immutable
class WireGuardConfig extends ProtocolConfig {
  const WireGuardConfig({
    required super.address,
    required super.port,
    required this.publicKey,
    required this.privateKey,
    this.presharedKey,
    required this.allowedIps,
  });

  final String publicKey;
  final String privateKey;
  final String? presharedKey;
  final List<String> allowedIps;

  static const _listEquality = ListEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is WireGuardConfig &&
      other.address == address &&
      other.port == port &&
      other.publicKey == publicKey &&
      other.privateKey == privateKey &&
      other.presharedKey == presharedKey &&
      _listEquality.equals(other.allowedIps, allowedIps);

  @override
  int get hashCode => Object.hash(
        address,
        port,
        publicKey,
        privateKey,
        presharedKey,
        _listEquality.hash(allowedIps),
      );

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'wireguard',
        'address': address,
        'port': port,
        'publicKey': publicKey,
        'privateKey': privateKey,
        'presharedKey': presharedKey,
        'allowedIps': allowedIps,
      };

  factory WireGuardConfig._fromJson(Map<String, dynamic> json) {
    return WireGuardConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      publicKey: json['publicKey'] as String,
      privateKey: json['privateKey'] as String,
      presharedKey: json['presharedKey'] as String?,
      allowedIps: (json['allowedIps'] as List<dynamic>).cast<String>(),
    );
  }
}

TransportType _parseTransportType(String? net) => switch (net) {
      'ws' => TransportType.ws,
      'grpc' => TransportType.grpc,
      'http2' || 'h2' => TransportType.http2,
      _ => TransportType.tcp,
    };

TransportConfig? _transportFrom(Map<String, dynamic> fields, {required String typeKey}) {
  final type = _parseTransportType(fields[typeKey] as String?);
  final path = fields['path'] as String?;
  final host = fields['host'] as String?;
  if (type == TransportType.tcp && path == null && host == null) return null;
  return TransportConfig(type: type, path: path, host: host);
}

VlessConfig _fromVless(VlessURL parsed) {
  final f = parsed.extractedFields;
  final security = f['security'] as String?;
  final sni = (f['sni'] as String?)?.isNotEmpty == true ? f['sni'] as String : f['address'] as String;
  RealityConfig? reality;
  if (security == 'reality') {
    final pbk = f['pbk'] as String?;
    final sid = f['sid'] as String?;
    if (pbk != null && pbk.isNotEmpty && sid != null && sid.isNotEmpty) {
      reality = RealityConfig(publicKey: pbk, shortId: sid);
    }
  }
  final tls = (security == 'tls' || security == 'reality')
      ? TlsConfig(sni: sni, reality: reality)
      : null;
  final flow = f['flow'] as String?;
  return VlessConfig(
    address: f['address'] as String,
    port: f['port'] as int,
    uuid: f['uuid'] as String,
    flow: (flow == null || flow.isEmpty) ? null : flow,
    transport: _transportFrom(f, typeKey: 'type'),
    tls: tls,
  );
}

VmessConfig _fromVmess(VmessURL parsed) {
  final f = parsed.extractedFields;
  final tlsField = f['tls'] as String?;
  final sni = (f['sni'] as String?) ?? (f['add'] as String);
  return VmessConfig(
    address: f['add'] as String,
    port: int.tryParse(f['port']?.toString() ?? '') ?? 443,
    uuid: f['id'] as String,
    alterId: int.tryParse(f['aid']?.toString() ?? '') ?? 0,
    transport: _transportFrom(f, typeKey: 'net'),
    tls: (tlsField == 'tls' || tlsField == 'reality') ? TlsConfig(sni: sni) : null,
  );
}

TrojanConfig _fromTrojan(TrojanURL parsed) {
  final f = parsed.extractedFields;
  final sni = (f['sni'] as String?)?.isNotEmpty == true ? f['sni'] as String : f['address'] as String;
  return TrojanConfig(
    address: f['address'] as String,
    port: f['port'] as int,
    password: f['password'] as String,
    transport: _transportFrom(f, typeKey: 'type'),
    tls: TlsConfig(sni: sni),
  );
}

ShadowsocksConfig _fromShadowsocks(ShadowsocksURL parsed) {
  final f = parsed.extractedFields;
  return ShadowsocksConfig(
    address: f['address'] as String,
    port: f['port'] as int,
    method: f['method'] as String,
    password: f['password'] as String,
  );
}
