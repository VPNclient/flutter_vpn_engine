import 'package:meta/meta.dart';

/// A snapshot of connection statistics.
///
/// Ported from the real `models/connection_stats.dart` (`bytesSent`→
/// `bytesSentTotal`, `bytesReceived`→`bytesReceivedTotal`, `latencyMs`→
/// `latency` as a [Duration]) to match `flutter_vpnclient_engine_mock`'s
/// shape exactly. `packetsSent`/`packetsReceived` are dropped — the mock
/// never had them and nothing in this port reads them (the real
/// `NativeEngineStats` FFI struct still reports them if a future need
/// arises; no native ABI change was made).
///
/// `current*BytesPerSecond` are **not** reported by the native layer — they
/// are computed by [VpnEngine]'s stats-poll timer from two real consecutive
/// polls at a known interval (arithmetic over real data, not fabricated).
@immutable
class ConnectionStats {
  const ConnectionStats({
    this.bytesSentTotal = 0,
    this.bytesReceivedTotal = 0,
    this.currentUploadBytesPerSecond = 0,
    this.currentDownloadBytesPerSecond = 0,
    this.latency = Duration.zero,
  });

  final int bytesSentTotal;
  final int bytesReceivedTotal;
  final double currentUploadBytesPerSecond;
  final double currentDownloadBytesPerSecond;
  final Duration latency;

  @override
  bool operator ==(Object other) =>
      other is ConnectionStats &&
      other.bytesSentTotal == bytesSentTotal &&
      other.bytesReceivedTotal == bytesReceivedTotal &&
      other.currentUploadBytesPerSecond == currentUploadBytesPerSecond &&
      other.currentDownloadBytesPerSecond == currentDownloadBytesPerSecond &&
      other.latency == latency;

  @override
  int get hashCode => Object.hash(
        bytesSentTotal,
        bytesReceivedTotal,
        currentUploadBytesPerSecond,
        currentDownloadBytesPerSecond,
        latency,
      );
}
