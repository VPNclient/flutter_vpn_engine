import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/engine/connection_state.dart';
import 'package:vpnclient_engine/src/models/connection_status.dart';

String describe(VpnConnectionState state) => switch (state) {
      Disconnected() => 'disconnected',
      Connecting() => 'connecting',
      Connected(:final since) => 'connected since $since',
      Disconnecting() => 'disconnecting',
      ConnectionFailed(:final reason) => 'failed: $reason',
    };

void main() {
  test('exhaustive switch compiles and dispatches correctly for every variant', () {
    expect(describe(const Disconnected()), 'disconnected');
    expect(describe(const Connecting()), 'connecting');
    final since = DateTime(2026, 7, 28);
    expect(describe(Connected(since)), 'connected since $since');
    expect(describe(const Disconnecting()), 'disconnecting');
    expect(describe(const ConnectionFailed('timeout')), 'failed: timeout');
  });

  test('vpnConnectionStateFromStatus maps every real ConnectionStatus value', () {
    expect(vpnConnectionStateFromStatus(ConnectionStatus.disconnected), isA<Disconnected>());
    expect(vpnConnectionStateFromStatus(ConnectionStatus.connecting), isA<Connecting>());

    final since = DateTime(2026, 1, 1);
    final connected = vpnConnectionStateFromStatus(
      ConnectionStatus.connected,
      connectedSince: since,
    ) as Connected;
    expect(connected.since, since);

    expect(vpnConnectionStateFromStatus(ConnectionStatus.disconnecting), isA<Disconnecting>());

    final failed = vpnConnectionStateFromStatus(
      ConnectionStatus.error,
      nativeErrorCode: 4,
    ) as ConnectionFailed;
    expect(failed.nativeErrorCode, 4);
    expect(failed.reason, isNotEmpty);
  });
}
