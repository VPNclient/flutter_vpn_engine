/// Типы VPN ядер
enum CoreType {
  /// SingBox - https://sing-box.sagernet.org/
  singbox,

  /// LibXray - https://github.com/xtls/libxray
  libxray,

  /// V2Ray - https://www.v2ray.com/
  v2ray,

  /// WireGuard - https://www.wireguard.com/
  wireguard;

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

