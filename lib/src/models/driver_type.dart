/// Типы драйверов туннелирования
enum DriverType {
  /// Без драйвера (прямое подключение)
  none,

  /// HevSocks5 Tunnel - https://github.com/heiher/hev-socks5-tunnel
  hevSocks5,

  /// Tun2Socks - https://github.com/xjasonlyu/tun2socks
  tun2socks;

  /// Преобразование в строку для нативного кода
  String toNativeString() {
    switch (this) {
      case DriverType.none:
        return 'NONE';
      case DriverType.hevSocks5:
        return 'HEV_SOCKS5';
      case DriverType.tun2socks:
        return 'TUN2SOCKS';
    }
  }

  /// Создание из строки
  static DriverType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'NONE':
        return DriverType.none;
      case 'HEV_SOCKS5':
        return DriverType.hevSocks5;
      case 'TUN2SOCKS':
        return DriverType.tun2socks;
      default:
        throw ArgumentError('Unknown driver type: $value');
    }
  }
}

