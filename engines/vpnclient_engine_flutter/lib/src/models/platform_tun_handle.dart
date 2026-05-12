/// Handle для платформенного TUN интерфейса
/// Абстракция над file descriptor/handle для разных платформ
abstract class PlatformTunHandle {
  /// Получить file descriptor (для нативного кода)
  int get fileDescriptor;

  /// Платформа
  String get platform;

  /// Закрыть handle
  void close();
}

/// Android TUN Handle (использует ParcelFileDescriptor)
class AndroidTunHandle implements PlatformTunHandle {
  final int _fd;

  AndroidTunHandle(this._fd);

  @override
  int get fileDescriptor => _fd;

  @override
  String get platform => 'android';

  @override
  void close() {
    // Закрытие обрабатывается на платформе
  }
}

/// iOS TUN Handle (использует NEPacketTunnelProvider packetFlow)
class IOSTunHandle implements PlatformTunHandle {
  final int _fd;

  IOSTunHandle(this._fd);

  @override
  int get fileDescriptor => _fd;

  @override
  String get platform => 'ios';

  @override
  void close() {
    // Закрытие обрабатывается на платформе
  }
}

/// Linux TUN Handle (прямой file descriptor)
class LinuxTunHandle implements PlatformTunHandle {
  final int _fd;

  LinuxTunHandle(this._fd);

  @override
  int get fileDescriptor => _fd;

  @override
  String get platform => 'linux';

  @override
  void close() {
    // Закрытие обрабатывается на платформе
  }
}

/// macOS TUN Handle (utun device)
class MacOSTunHandle implements PlatformTunHandle {
  final int _fd;

  MacOSTunHandle(this._fd);

  @override
  int get fileDescriptor => _fd;

  @override
  String get platform => 'macos';

  @override
  void close() {
    // Закрытие обрабатывается на платформе
  }
}

/// Windows TUN Handle (TAP adapter handle)
class WindowsTunHandle implements PlatformTunHandle {
  final int _handle;

  WindowsTunHandle(this._handle);

  @override
  int get fileDescriptor => _handle; // На Windows это handle, но используем тот же интерфейс

  @override
  String get platform => 'windows';

  @override
  void close() {
    // Закрытие обрабатывается на платформе
  }
}

