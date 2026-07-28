import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/engine/connection_stats.dart';

void main() {
  test('defaults to all-zero', () {
    const stats = ConnectionStats();
    expect(stats.bytesSentTotal, 0);
    expect(stats.bytesReceivedTotal, 0);
    expect(stats.currentUploadBytesPerSecond, 0);
    expect(stats.currentDownloadBytesPerSecond, 0);
    expect(stats.latency, Duration.zero);
  });

  test('equality is value-based', () {
    const a = ConnectionStats(
      bytesSentTotal: 100,
      bytesReceivedTotal: 200,
      currentUploadBytesPerSecond: 1.5,
      currentDownloadBytesPerSecond: 2.5,
      latency: Duration(milliseconds: 50),
    );
    const b = ConnectionStats(
      bytesSentTotal: 100,
      bytesReceivedTotal: 200,
      currentUploadBytesPerSecond: 1.5,
      currentDownloadBytesPerSecond: 2.5,
      latency: Duration(milliseconds: 50),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('rate derivation arithmetic (as VpnEngine will apply it between two real polls)', () {
    const previousTotal = 1000;
    const currentTotal = 1500;
    const pollInterval = Duration(seconds: 1);
    final rate = (currentTotal - previousTotal) / (pollInterval.inMilliseconds / 1000);
    expect(rate, 500.0);
  });
}
