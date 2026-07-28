/// Типы VPN ядер
///
/// Relocated from `models/core_type.dart`; `needsExternalDriver` is new,
/// ported from `EngineManager.requiresDriver`'s switch (see
/// `core/engine_manager.dart`) as an inherent property, matching
/// `flutter_vpnclient_engine_mock`'s `CoreType` shape (minus `h2` — no real
/// equivalent exists in this package).
enum CoreType {
  /// SingBox - https://sing-box.sagernet.org/
  singbox(needsExternalDriver: false),

  /// LibXray - https://github.com/xtls/libxray
  libxray(needsExternalDriver: true),

  /// V2Ray - https://www.v2ray.com/
  v2ray(needsExternalDriver: true),

  /// WireGuard - https://www.wireguard.com/
  wireguard(needsExternalDriver: false);

  const CoreType({required this.needsExternalDriver});

  /// Whether this core requires an external tunneling driver, as opposed to
  /// establishing its own TUN. Ported from `EngineManager.requiresDriver`.
  final bool needsExternalDriver;

  /// Преобразование в строку для нативного кода
  String toNativeString() {
    switch (this) {
      case CoreType.singbox:
        return 'SINGBOX';
      case CoreType.libxray:
        return 'LIBXRAY';
      case CoreType.v2ray:
        return 'V2RAY';
      case CoreType.wireguard:
        return 'WIREGUARD';
    }
  }

  /// Создание из строки
  static CoreType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SINGBOX':
        return CoreType.singbox;
      case 'LIBXRAY':
        return CoreType.libxray;
      case 'V2RAY':
        return CoreType.v2ray;
      case 'WIREGUARD':
        return CoreType.wireguard;
      default:
        throw ArgumentError('Unknown core type: $value');
    }
  }
}
