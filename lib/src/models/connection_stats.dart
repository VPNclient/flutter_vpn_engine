/// Статистика VPN соединения
class ConnectionStats {
  /// Отправлено байт
  final int bytesSent;

  /// Получено байт
  final int bytesReceived;

  /// Отправлено пакетов
  final int packetsSent;

  /// Получено пакетов
  final int packetsReceived;

  /// Задержка в миллисекундах
  final int latencyMs;

  const ConnectionStats({
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.packetsSent = 0,
    this.packetsReceived = 0,
    this.latencyMs = 0,
  });

  /// Создание из Map
  factory ConnectionStats.fromMap(Map<String, dynamic> map) {
    return ConnectionStats(
      bytesSent: map['bytesSent'] as int? ?? 0,
      bytesReceived: map['bytesReceived'] as int? ?? 0,
      packetsSent: map['packetsSent'] as int? ?? 0,
      packetsReceived: map['packetsReceived'] as int? ?? 0,
      latencyMs: map['latencyMs'] as int? ?? 0,
    );
  }

  /// Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'bytesSent': bytesSent,
      'bytesReceived': bytesReceived,
      'packetsSent': packetsSent,
      'packetsReceived': packetsReceived,
      'latencyMs': latencyMs,
    };
  }

  /// Форматированный размер отправленных данных
  String get formattedBytesSent => _formatBytes(bytesSent);

  /// Форматированный размер полученных данных
  String get formattedBytesReceived => _formatBytes(bytesReceived);

  /// Общий объем данных
  int get totalBytes => bytesSent + bytesReceived;

  /// Форматированный общий объем
  String get formattedTotalBytes => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() {
    return 'ConnectionStats(sent: $formattedBytesSent, received: $formattedBytesReceived, latency: ${latencyMs}ms)';
  }
}




