import '../models/connection_status.dart';

/// The VPN connection's current lifecycle state.
///
/// Matches `flutter_vpnclient_engine_mock`'s `VpnConnectionState` shape exactly
/// (named `VpnConnectionState`, not `ConnectionState`, to avoid colliding with
/// Flutter's own `ConnectionState` enum used by `StreamBuilder`/`FutureBuilder`).
sealed class VpnConnectionState {
  const VpnConnectionState();
}

class Disconnected extends VpnConnectionState {
  const Disconnected();
}

class Connecting extends VpnConnectionState {
  const Connecting();
}

class Connected extends VpnConnectionState {
  const Connected(this.since);

  final DateTime since;
}

class Disconnecting extends VpnConnectionState {
  const Disconnecting();
}

class ConnectionFailed extends VpnConnectionState {
  const ConnectionFailed(this.reason, {this.nativeErrorCode});

  final String reason;

  /// Raw error/status code from the real native engine, when available.
  final int? nativeErrorCode;
}

/// Maps the real, internal `ConnectionStatus` enum (kept as glue for
/// `VpnEnginePlatform`/the real `MethodChannel`'s `onStatusChanged` payload —
/// see `models/connection_status.dart`) onto the new sealed hierarchy.
///
/// This is the mapping table ported from `ConnectionStatus`'s real semantics
/// (`disconnected`/`connecting`/`connected`/`disconnecting`/`error`) — the
/// same 5 real states, just represented as a sealed hierarchy instead of a
/// flat enum with no associated data. `error` has no real reason text (the
/// native ABI only ever reports an undifferentiated error status), so
/// [reason] is a fixed, honest placeholder unless the caller supplies one.
VpnConnectionState vpnConnectionStateFromStatus(
  ConnectionStatus status, {
  DateTime? connectedSince,
  int? nativeErrorCode,
}) {
  switch (status) {
    case ConnectionStatus.disconnected:
      return const Disconnected();
    case ConnectionStatus.connecting:
      return const Connecting();
    case ConnectionStatus.connected:
      return Connected(connectedSince ?? DateTime.now());
    case ConnectionStatus.disconnecting:
      return const Disconnecting();
    case ConnectionStatus.error:
      return ConnectionFailed(
        'Native engine reported an error',
        nativeErrorCode: nativeErrorCode,
      );
  }
}
