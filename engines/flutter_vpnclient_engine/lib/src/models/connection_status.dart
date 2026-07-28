/// Статус VPN соединения
enum ConnectionStatus {
  /// Отключено
  disconnected,

  /// Подключается
  connecting,

  /// Подключено
  connected,

  /// Отключается
  disconnecting,

  /// Ошибка
  error;

  /// Создание из строки
  static ConnectionStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DISCONNECTED':
        return ConnectionStatus.disconnected;
      case 'CONNECTING':
        return ConnectionStatus.connecting;
      case 'CONNECTED':
        return ConnectionStatus.connected;
      case 'DISCONNECTING':
        return ConnectionStatus.disconnecting;
      case 'ERROR':
        return ConnectionStatus.error;
      default:
        throw ArgumentError('Unknown connection status: $value');
    }
  }

  /// Преобразование в строку
  String toNativeString() {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING';
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.disconnecting:
        return 'DISCONNECTING';
      case ConnectionStatus.error:
        return 'ERROR';
    }
  }
}




