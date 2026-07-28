import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Matches `flutter_vpnclient_engine_mock`'s `RealityConfig`/`TlsConfig`
/// shape exactly. Typed containers for fields the real `VlessURL` parser
/// already extracts (`pbk`/`sid`/`spx`/`sni`/`security` query params).
@immutable
class RealityConfig {
  const RealityConfig({
    required this.publicKey,
    required this.shortId,
    this.spiderX,
  });

  final String publicKey;
  final String shortId;
  final String? spiderX;

  @override
  bool operator ==(Object other) =>
      other is RealityConfig &&
      other.publicKey == publicKey &&
      other.shortId == shortId &&
      other.spiderX == spiderX;

  @override
  int get hashCode => Object.hash(publicKey, shortId, spiderX);

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'shortId': shortId,
        'spiderX': spiderX,
      };

  factory RealityConfig.fromJson(Map<String, dynamic> json) {
    return RealityConfig(
      publicKey: json['publicKey'] as String,
      shortId: json['shortId'] as String,
      spiderX: json['spiderX'] as String?,
    );
  }
}

@immutable
class TlsConfig {
  const TlsConfig({
    required this.sni,
    this.alpn = const [],
    this.reality,
  });

  final String sni;
  final List<String> alpn;
  final RealityConfig? reality;

  static const _listEquality = ListEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is TlsConfig &&
      other.sni == sni &&
      _listEquality.equals(other.alpn, alpn) &&
      other.reality == reality;

  @override
  int get hashCode => Object.hash(sni, _listEquality.hash(alpn), reality);

  Map<String, dynamic> toJson() => {
        'sni': sni,
        'alpn': alpn,
        'reality': reality?.toJson(),
      };

  factory TlsConfig.fromJson(Map<String, dynamic> json) {
    return TlsConfig(
      sni: json['sni'] as String,
      alpn: (json['alpn'] as List<dynamic>? ?? const []).cast<String>(),
      reality: json['reality'] != null
          ? RealityConfig.fromJson(json['reality'] as Map<String, dynamic>)
          : null,
    );
  }
}
